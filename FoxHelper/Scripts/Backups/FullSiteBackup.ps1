$SiteName=''
$Destination='D:\Backups'
$Date = Get-Date -Format 'dd-MM-yyyy HH-mm'

#Create backup folder
$BackupPath = $Destination + "\$Date"
$NULL = new-item -Path $Destination -ItemType Directory


Import-Module WebAdministration -Verbose:$false
function Get-ValidSite {
    param ([Parameter(Mandatory, HelpMessage = 'Site your are validating', Position = 0, ValueFromPipeline)]$SiteName)
    If (!(Test-Path -Path "IIS:\Sites\$SiteName"  )) {
        Write-Host "The site '$SiteName' does not exist in this server`nPlease enter a vaild site:" -ForegroundColor Yellow
        $SiteName = read-Host
        Get-ValidSite -SiteName $SiteName
    }
    ELSE { return $SiteName }
}

$SiteName = Get-ValidSite -SiteName $SiteName




[string]$CodePath=((Get-ItemProperty "IIS:\Sites\$SiteName").PhysicalPath) 
$CodePath=$CodePath -replace '\\Application',''

[string]$UploadPath=((Get-ItemProperty "IIS:\Sites\$SiteName\upload").PhysicalPath) 



#CODE
Compress-Archive -Path $CodePath -DestinationPath "$Destination\Code.zip" -CompressionLevel Fastest

#Upload: Misc and Login
Compress-Archive -Path "$UploadPath\Misc" -DestinationPath "$Destination\Misc.zip" -CompressionLevel Fastest
Compress-Archive -Path "$UploadPath\Login" -DestinationPath "$Destination\Login.zip" -CompressionLevel Fastest

#IIS
& "$env:ComSpec" /c "%windir%\system32\inetsrv\appcmd list site $SiteName /config /xml > $Destination\IIS-$SiteName.xml" 2>&1
Export-IISConfiguration -PhysicalPath $Destination -DontExportKeys

#AppPool
& "$env:ComSpec" /c "%windir%\system32\inetsrv\appcmd list apppool Fox /config /xml > $Destination\FoxPool.xml" 2>&1

#Registry
Get-Item -Path "HKLM:\SOFTWARE\BKS\Fox\$SiteName" | Out-File -FilePath "$Destination\BKS.reg"
Get-Item -Path "HKLM:\SOFTWARE\Wow6432Node\BKS\Fox\$SiteName" | Out-File -FilePath "$Destination\Wow6432Node_BKS.reg"

#Need to add LDS backup here