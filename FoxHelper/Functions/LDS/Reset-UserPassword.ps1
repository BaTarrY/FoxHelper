function Reset-UserPassword
{
# Example Reset-UserPassword -UserName admin -NewPassword 123 -Server Prod -LDS_Port 50016 -RunAsDiffrentUser
     param 
     (
       [Parameter(Mandatory,HelpMessage='UserName to reset its password',Position=0,ValueFromPipeline)][ValidateNotNullOrEmpty()][String]$UserName,
       [Parameter(Mandatory,HelpMessage='The new Password',Position=1)][ValidateNotNullOrEmpty()]$NewPassword,
       [Parameter(Position=2)][ValidateNotNullOrEmpty()][String]$Server='Localhost',
       [Parameter(Mandatory,HelpMessage='LDS Port',Position=3)][ValidateNotNullOrEmpty()][Int]$LDS_Port,
       [Switch]$RunAsDiffrentUser
		 )

    $NewPassword=ConvertTo-SecureString -AsPlainText $NewPassword -Force -ErrorAction Stop 
    $LDS=$Server+':'+$LDS_Port
    IF($Server -eq 'LocalHost' -and $RunAsDiffrentUser -eq $False) #This server & This user
    {
      Write-Host "Attempting reset password for user '$UserName'"
      Set-ADAccountPassword "CN=$UserName,CN=Fox,CN=OuTree,DC=Fox,DC=Bks" -Reset -NewPassword $NewPassword -server $LDS -ErrorAction Stop 
      Write-Host "Reset password for user '$UserName' finished Successfully" -ForegroundColor Green
    }
    ELSEIF($Server -eq 'LocalHost' -and $RunAsDiffrentUser -eq $True) #This server & Other user
    {
      $ServerUser=Get-Credential -Message "Enter User Name and Password for a Domain/Local user with suffienct permissions for server '$Server' and it's LDS" -ErrorAction Stop
      IF(!($ServerUser))
        {
        Write-Error -Category InvalidData -Exception 'User Credtials were not supplied. Exiting.' -ErrorId 0 -TargetObject Credentials -Message "Using the paremeter 'RunAsDiffrentUser' a user has to be supplied.`nSupply User Name and Password for a Domain/Local user with suffienct permissions for server '$Server' and it's LDS" -RecommendedAction "Remove the swithc 'RunAsDiffrentUser' or Supply User Name and Password for a Domain/Local user with suffienct permissions for server '$Server'"
        Exit
        }
      Write-Host "Attempting reset password for user '$UserName'"
      Set-ADAccountPassword -Credential $ServerUser "CN=$UserName,CN=Fox,CN=OuTree,DC=Fox,DC=Bks" -Reset -NewPassword $NewPassword -server $LDS -ErrorAction Stop
      Write-Host "Reset password for user '$UserName' finished Successfully" -ForegroundColor Green
    }
    ELSEIF($Server -ne 'LocalHost' -and $RunAsDiffrentUser -eq $False) #Other Server & This User
    {
      Write-Host "Attempting reset password for user '$UserName'"
      Invoke-Command -ComputerName $Server -ScriptBlock {Set-ADAccountPassword "CN=$Using:UserName,CN=Fox,CN=OuTree,DC=Fox,DC=Bks" -Reset -NewPassword $Using:NewPassword -server $Using:LDS -ErrorAction Stop} -ErrorAction Stop
      Write-Host "Reset password for user '$UserName' finished Successfully" -ForegroundColor Green
    }
    ELSEIF($Server -ne 'LocalHost' -and $RunAsDiffrentUser -eq $True) #Other Server & Other User
    {
      $ServerUser=Get-Credential -Message "Enter User Name and Password for a Domain/Local user with suffienct permissions for server '$Server' and it's LDS" -ErrorAction Stop
            IF(!($ServerUser))
        {
        Write-Error -Category InvalidData -Exception 'User Credtials were not supplied. Exiting.' -ErrorId 0 -TargetObject Credentials -Message "Using the paremeter 'RunAsDiffrentUser' a user has to be supplied.`nSupply User Name and Password for a Domain/Local user with suffienct permissions for server '$Server' and it's LDS" -RecommendedAction "Remove the swithc 'RunAsDiffrentUser' or Supply User Name and Password for a Domain/Local user with suffienct permissions for server '$Server'"
        Exit
        }
      Write-Host "Attempting reset password for user '$UserName'"
      Invoke-Command -ComputerName $Server -Credential $ServerUser -ScriptBlock {Set-ADAccountPassword "CN=$Using:UserName,CN=Fox,CN=OuTree,DC=Fox,DC=Bks" -Reset -NewPassword $Using:NewPassword -server $Using:LDS -ErrorAction Stop -ErrorVariable $ES} -ErrorAction Stop
      Write-Host "Reset password for user '$UserName' finished Successfully" -ForegroundColor Green
    }
}
# SIG # Begin signature block
# MIID9QYJKoZIhvcNAQcCoIID5jCCA+ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUegrdBCIhwChdzFZb8mnpUeu0
# 1gqgggITMIICDzCCAXygAwIBAgIQdURWGNlnI6BEVyu894mPljAJBgUrDgMCHQUA
# MBgxFjAUBgNVBAMTDUVsaW9yIE1hY2hsZXYwHhcNMjEwNTIyMTM0NTMzWhcNMzkx
# MjMxMjM1OTU5WjAYMRYwFAYDVQQDEw1FbGlvciBNYWNobGV2MIGfMA0GCSqGSIb3
# DQEBAQUAA4GNADCBiQKBgQC6Xwa4fwf4KnocuKZBY5Le32yF/pK7AuUtTdtmvwP8
# ia8P+Z5wdykF8+ROyGU5/b9ZPtbgw83NnR0lUbOS7Ztjwthr/CDE8OyYf1xud0SM
# TQyOc7hGlifU7SgAqGzNvSlbD3CwPfBwVcbLrAv0wMH+WgkpYf1QTN4kGRHwpFVW
# IQIDAQABo2IwYDATBgNVHSUEDDAKBggrBgEFBQcDAzBJBgNVHQEEQjBAgBAQLv6t
# CX4pKMOXztQ3awgAoRowGDEWMBQGA1UEAxMNRWxpb3IgTWFjaGxldoIQdURWGNln
# I6BEVyu894mPljAJBgUrDgMCHQUAA4GBAE84zDAx5U6PK2Inobhn+9mu4NqIunkc
# BUO60xoXzA0clOgF8DRznPJ1lY8pcz4OFBI+L6bdvTyG2pAWQ+GgDf+Ms6QlpdH6
# LAT3YPXHEMJUt39oy54U+RUa5nVewE+0Qe/xGBnmvdvHu3VG1UcKRxjFwdvBb+iB
# aUPeCleH34AAMYIBTDCCAUgCAQEwLDAYMRYwFAYDVQQDEw1FbGlvciBNYWNobGV2
# AhB1RFYY2WcjoERXK7z3iY+WMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQwpPMwe/WGKa99Ew39
# FxJTqIXupTANBgkqhkiG9w0BAQEFAASBgJzMr5AZmXokVp+sFRENY5Jb6Q7bQV/S
# NQMONFz5nJnZ+zfo2z/s0xwNzHKWNjrlVdKWwh3JAX5oWJYCL+J9T/K/OH3aoI1m
# jjxtHsr9O1eGQGZDYlVEBiGDBhJ1z/KwAghPnhKi03S1UnbfoUksg0U4wQvDavAD
# jqkM24cRcP0c
# SIG # End signature block
