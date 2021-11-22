function Get-FoxSitesInformation
{
    param (
      [securestring]$SecuredCredentials,
      [Parameter(ValueFromPipeline)]$Servers,
      [Parameter(Mandatory)][ValidateSet('Console', 'QuickReview','HTML', 'Excel','CSV')]$OutputType
    )

$WrinRMStatus=Get-Service -Name WinRM |Select-Object -ExpandProperty Status
if($WrinRMStatus -eq 'Stopped'){
    Start-Service -Name WinRM
  }

if (!($Servers)) {
$ServersPath=[Environment]::GetFolderPath('MyDocuments')
$ServersPath=$ServersPath+ '\IISServers.csv'
if(Test-Path -Path $ServersPath){

  $Servers=import-CSV -Path $ServersPath | Select-Object -Unique -ExpandProperty 'Servers'
}
Else{  Write-host "Notice: This is a one-time Operation`n" -ForegroundColor Yellow
'Servers' | Out-File -FilePath $ServersPath
$Servers=(Read-Host -Prompt 'Enter your IIS Server names - Seperated by Commas (,)').Split(',') 
Add-Content -Value $Servers -Path $ServersPath
}}


if (!($SecuredCredentials)) {
$cred=(Get-Credential)
}
$SQLQuery='select value as [FoxVersion],UserDataSourcesNew.ServerName as [LDSServer],UserDataSourcesNew.Port as [LDSPort]
from SystemConfiguration 
left join UserDataSourcesNew on UserDataSourcesNew.UsersContainerDistinguishedName=''CN=Fox,CN=OuTree,DC=Fox,DC=Bks''
where SystemConfiguration.property=''version'''

Get-Service -Name WinRM | start-service 

$SitesInfo=Invoke-Command -ComputerName $Servers -Credential $cred  -ScriptBlock{
##Remote Start Here
    Import-Module -Name WebAdministration

    
    $SitesInfo=@()
    $HostName=$env:computername
    $Sites=Get-ChildItem -Path IIS:\Sites | Where-Object -Property Name -NE 'Default Web Site'|Where-Object -Property Name -NotLike "*OPT*"
    foreach($Site in $Sites){
        $SiteName=($Site|Select-Object -ExpandProperty Name)
        IF(Test-Path -Path HKLM:\SOFTWARE\BKS\Fox\$Site){
            $Registry="HKLM:\SOFTWARE\BKS\Fox\$SiteName"}
        Else{
        $Registry="HKLM:\SOFTWARE\WOW6432Node\BKS\Fox\$SiteName"}
        if ($null -ne (Get-ItemProperty -Path $Registry -Name Location -ErrorAction SilentlyContinue).Location){
            $SQLInstance=Get-ItemProperty -Path $Registry | Select-Object -ExpandProperty SQL_Server
            $DataBase=Get-ItemProperty -Path $Registry | Select-Object -ExpandProperty Sql_DataBase
            $InstallLocation=Get-ItemProperty -Path $Registry | Select-Object -ExpandProperty Location
            Switch(Get-ItemProperty -Path $Registry | Select-Object -ExpandProperty SqlAuthenticationType){
              1{$SQLAuthType='SQL'}
              2{$SQLAuthType='WINDOWS'}
              }
            $SQLInstanceCheck=$SQLInstance.Split('\')[0]
      if (($SQLInstanceCheck) -eq $HostName) {
        $SQLResult=Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $DataBase -Query $Using:SQLQuery

      }
      else {
        $SQLResult=Invoke-Command -ComputerName $SQLInstanceCheck -ArgumentList $SQLInstance,$Database,$Using:SQLQuery -Credential $Using:cred -ScriptBlock{
          [CmdletBinding()]
          param($SQLInstance,$Database,$SQLQuery)
          Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $DataBase -Query $SQLQuery }
      }
        $LDSServer=$SQLResult | Select-Object -ExpandProperty LDSServer
        if ('127.0.0.1' -or $HostName){
          $LDSServer=$HostName}
        $LDSPort=$SQLResult| Select-Object -ExpandProperty LDSPort
        $Version=$SQLResult| Select-Object -ExpandProperty FoxVersion
        $item = New-Object -TypeName PSObject
        Add-Member -InputObject $Item -type NoteProperty -Name 'Fox Site' -Value $SiteName.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'Site Status' -Value ($Site|Select-Object -ExpandProperty State).ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'Fox Version' -Value $Version
        Add-Member -InputObject $Item -type NoteProperty -Name 'IIS Server' -Value $HostName.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'Install Location' -Value $InstallLocation.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'SQL Server' -Value $SQLInstance.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'Fox DataBase' -Value $DataBase.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'SQL Authentication Type' -Value $SQLAuthType
        Add-Member -InputObject $Item -type NoteProperty -Name 'LDS Server' -Value $LDSServer.ToUpper()
        Add-Member -InputObject $Item -type NoteProperty -Name 'LDS Port' -Value $LDSPort
    
        $SitesInfo+=$Item
        }
    }
    $SitesInfo
    ##Remote ENDs Here
}
Switch($OutputType){
  'Console'{$SitesInfo |Select-Object -ExcludeProperty 'PSComputerName','RunspaceId' | Format-Table -AutoSize -Force}
  'HTML'{$SitesInfo |Select-Object -ExcludeProperty 'PSComputerName','RunspaceId','PSShowComputerName' | Out-GridHtml}
  'CSV'{
    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
    $null = $browser.ShowDialog()
    $Path=$browser.SelectedPath
    if($Path){
      if(Test-Path -Path "$Path\IISSitesInformation.csv"){Remove-Item -Path "$Path\IISSitesInformation.csv" -Force}
      $SitesInfo |Select-Object -ExcludeProperty 'PSComputerName','RunspaceId','PSShowComputerName' | Out-File -FilePath "$Path\IISSitesInformation.csv"}
    Else {Write-Host -Object 'No File Selected. Oborting.' -ForegroundColor Red}
    exit}
    



    'Excel'{
      Import-Module -Name ImportExcel
      Add-Type -AssemblyName System.Windows.Forms
      $browser = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
      $null = $browser.ShowDialog()
      $Path=$browser.SelectedPath
      if($Path){
        if(Test-Path -Path "$Path\IISSitesInformation.xlsx"){Remove-Item -Path "$Path\IISSitesInformation.xlsx" -Force}
        $SitesInfo |Select-Object -ExcludeProperty 'PSComputerName','RunspaceId','PSShowComputerName' | Export-Excel -Path "$Path\IISSitesInformation.xlsx" -Title 'Your Fox IIS Sites Information' -WorksheetName (Get-Date -Format 'dd/MM/yyyy') -TitleBold -AutoSize -FreezeTopRowFirstColumn -TableName SitesInformation -Show}
      Else {Write-Host -Object 'No File Selected. Oborting.' -ForegroundColor Red}
      exit}
  'QuickReview'{$SitesInfo |Select-Object -ExcludeProperty 'PSComputerName','RunspaceId','PSShowComputerName' | Out-GridView -Title 'Your Fox IIS Sites Information'} 
  }
  if($WrinRMStatus -eq 'Stopped'){
    Stop-service -Name WinRM
  }
}