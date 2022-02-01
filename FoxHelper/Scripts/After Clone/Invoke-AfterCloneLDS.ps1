#UserParemeters
$SiteName='Site.Domain'
$NewPassword='New Admin Password'




## Modules
Try{
if (!(Get-Module -ListAvailable -Name WebAdministration)){install-Module -Name WebAdministration -Force} 
Import-Module -Name WebAdministration -Force -ErrorAction Stop

if (!(Get-Module -ListAvailable -Name SQLPS) -and !(Get-Module -ListAvailable -Name SQLServer)){install-Module -Name SQLServer -Force -ErrorAction Stop}
ELSEIF(Get-Module -ListAvailable -Name SQLServer){Import-Module -Name SQLServer -DisableNameChecking -Force -ErrorAction Stop}
ELSEIF(Get-Module -ListAvailable -Name SQLPS) {Import-Module -Name SQLPS -DisableNameChecking -Force -ErrorAction Stop}
}
Catch{
Write-host "An Error occured during import of required modules. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}

## Custom Functions ###

    function Get-ValidateProgress
    {
         param ([Parameter(Mandatory,HelpMessage='Value Passed from ValidateLDS.exe',Position=0,ValueFromPipeline)]$ValidateLine)
      process 
      {
         IF($ValidateLine -like 'Proccessing Active Users record*' )
         {
            $Current=$ValidateLine -replace 'Proccessing Active Users record ','' -replace 'of.*','' -replace ' ',''
            $TotalValue=$ValidateLine -replace "Proccessing Active Users record $Current of ",''
            [INT]$Progress=(($Current/$TotalValue)*100)
            Write-Progress -Id 1 -Activity ValidateDBLDS -Status 'Proccessing LDS User records' -PercentComplete $Progress -CurrentOperation "Active User $Current out of $TotalValue"
            IF($Current -eq $TotalValue){write-host 'Finished procccsing Active Users' -ForegroundColor Green}
         }
         ELSEIF($ValidateLine -like 'Proccessing Deleted Users record*' )
         {
            $Current=$ValidateLine -replace 'Proccessing Deleted Users record ','' -replace 'of.*','' -replace ' ',''
            $TotalValue=$ValidateLine -replace "Proccessing Deleted Users record $Current of ",''
            [INT]$Progress=(($Current/$TotalValue)*100)
            Write-Progress -Id 1 -Activity ValidateDBLDS -Status 'Proccessing LDS User records' -PercentComplete $Progress -CurrentOperation "Deleted User $Current out of $TotalValue"
            IF($Current -eq $TotalValue){write-host 'Finished procccsing Deleted Users' -ForegroundColor Green}
         }
      }
    }


        function Get-ValidSite
    {
         param ([Parameter(Mandatory,HelpMessage='Site your are cloneing',Position=0,ValueFromPipeline)]$SiteName)
         If(!(Test-Path -Path "IIS:\Sites\$SiteName"  ))
         {
                Write-Host "The site '$SiteName' does not exist in this server`nPlease enter a vaild site:" -ForegroundColor Yellow
                $SiteName=read-Host
                Get-ValidSite -SiteName $SiteName
         }
         ELSE { return $SiteName }
    }




##Verify Site
$SiteName=Get-ValidSite -SiteName $SiteName


#DefaultParameters
$ErrorActionPreference = "Stop" #if any error, stop.
Try{
$User = Get-ItemProperty "IIS:\Sites\$SiteName" | Select-Object -ExpandProperty userName
Try{
    IF(test-path ("HKLM:\SOFTWARE\BKS\Fox\$SiteName"))
    {
        $SQLServer=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\BKS\Fox\$SiteName" -Name SQL_Server
        $DataBase=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\BKS\Fox\$SiteName" -Name SQL_Database
        $InstallLocation=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\BKS\Fox\$SiteName" -Name Location
    }
    ELSE
    {
        $SQLServer=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Wow6432Node\BKS\Fox\$SiteName" -Name SQL_Server
        $DataBase=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Wow6432Node\BKS\Fox\$SiteName" -Name SQL_Database
        $InstallLocation=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Wow6432Node\BKS\Fox\$SiteName" -Name Location

    }
  $QueryAdminLogin='SELECT LoginName from Users where ID=0'
  $AdminLoginName=Invoke-Sqlcmd  -ServerInstance $SQLServer -Database $DataBase -Query $QueryAdminLogin |Select-Object -ExpandProperty LoginName

}
Catch{
Write-host "An Error occured Quering Database for the LoginName of the Admin user. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}

$LDSQuery='Select ServerName,Port from UserDataSourcesNew'
$LDSInfo=Invoke-Sqlcmd  -ServerInstance $SQLServer -Database $DataBase -Query $LDSQuery
$LDSServer=$LDSInfo | Select-Object -ExpandProperty ServerName
$LDSPort=$LDSInfo | Select-Object -ExpandProperty Port
$LDS=$LDSServer+':'+$LDSPort
[string]$LDSINSANCES=dsdbutil “li I” Q
[array]$LDSINSANCES=($LDSINSANCES -replace 'Running','Running;' -replace 'Stopped','Stopped;').Split(';')
foreach ($INSTACE in $LDSINSANCES){
$LDSInstance=$INSTACE | Select-string  "$LDSPort"
$Temp=$LDSInstance -replace "LDAP Port:             $LDSPort.*",'' -replace ".*Long Name:             ",'' -replace ' ',''
If($Temp){
$LDSName=$Temp
}
}
Remove-Variable -Name Temp
Remove-Variable -Name INSTACE
Remove-Variable -Name LDSINSANCES
Remove-Variable -Name LDSInfo
Remove-Variable -Name LDSQuery
}
Catch{
Write-host "An Error occured during Default Parameters setup. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}

########################################### Script Start   ###########################################

Try{
Stop-Service -Name "ADAM_$LDSName" -Force -ErrorAction Stop
Write-Host "Successfully stopped $LDSName LDS" -ForegroundColor Green
Start-Sleep -Seconds 2

}
Catch{
Write-host "An Error occured during LDS service stop attempt. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}



Try{
dsacls \\$LDS\CN=Configuration,CN={19A0FDA6-AB0D-41C4-BCC1-4D7C9E5D0EDA} /takeOwnership
dsacls \\$LDS\CN=OuTree,DC=Fox,DC=Bks /takeOwnership
dsacls \\$LDS\CN=Schema,CN=Configuration,CN={19A0FDA6-AB0D-41C4-BCC1-4D7C9E5D0EDA} /takeOwnership

Write-Host 'Successfully set LDS Ownership' -ForegroundColor Green
Start-Sleep -Seconds 2

}
Catch{
Write-host "An Error occured during LDS Ownership transfer. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}


Try{
dsacls \\$LDS\CN=Configuration,CN={19A0FDA6-AB0D-41C4-BCC1-4D7C9E5D0EDA} /G "$User":GA /I:T
dsacls \\$LDS\CN=OuTree,DC=Fox,DC=Bks /G "$User":GA /I:T
dsacls \\$LDS\CN=Schema,CN=Configuration,CN={19A0FDA6-AB0D-41C4-BCC1-4D7C9E5D0EDA} /G "$User":GA /I:T
Write-Host "Successfully grant LDS accsess to user $User" -ForegroundColor Green
Start-Sleep -Seconds 2
}
Catch{
Write-host "An Error occured during LDS Ownership transfer. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}

Try{
Start-Service -Name "ADAM_$LDSName" -ErrorAction Stop
Write-Host "Successfully Started $LDSName LDS" -ForegroundColor Green
Start-Sleep -Seconds 2

}
Catch{
Write-host "An Error occured during LDS service start attempt. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}

Try{
Write-Host 'Starting ValidateDBLDS. It might take a while.' -ForegroundColor Magenta
$cmdOutput = cmd.exe /c "cd /d $InstallLocation\Code\Utilities && ValidateDBLDS.exe /viewonly:false" 2>&1 | Get-ValidateProgress
Write-Host "Successfully finished LDS Validation." -ForegroundColor Green
Start-Sleep -Seconds 2
}
Catch{
Write-host "An Error occured during validating LDS. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}


Try{
Set-ADAccountPassword "CN=$AdminLoginName,CN=Fox,CN=OuTree,DC=Fox,DC=Bks" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $NewPassword -Force) -server $LDS
Write-Host "Successfully reset $AdminLoginName password to $NewPassword." -ForegroundColor Green
Start-Sleep -Seconds 2
}
Catch{
Write-host "An Error occured during validating LDS. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red
}