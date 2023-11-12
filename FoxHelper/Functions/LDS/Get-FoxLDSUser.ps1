function Get-FoxLDSUser {
    param (
        [Parameter(
            HelpMessage = 'Server Name or IP which LDS is installed on. Deafult is This Server (127.0.0.1)')]
        [ValidateScript({ Test-Connection -TargetName $_ -Quiet })]
        [string]
        $Server = '127.0.01',

        [Parameter(
            HelpMessage = 'LDAP Port. Deafult is 389')]
        [ValidateNotNullOrEmpty()]
        [int]
        $Port = 389,

        [Parameter(,
            HelpMessage = "Search User by one of the following Parameters: Default is UserPrincipalName=LoginName. 
            Alternatives: GivenName=User First Name, Surname=User Last Name, ObjectGUID=User GUID")]
        [ValidateNotNullOrEmpty()]
        [string]
        $SearchBy = 'UserPrincipalName',
        
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'User to search',
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $User
    )



    import-module -Name "ActiveDirectory" -DisableNameChecking -Force

    $LDS = $Server + ':' + $Port
    IF ($SearchBy -eq 'ObjectGUID') { $Filter = $SearchBy + ' -EQ "' + $User + '"' }
    ELSE { $Filter = $SearchBy + ' -like"*' + $User + '"' }

    return (Get-ADUser -Server $LDS -SearchBase 'CN=Fox,CN=OuTree,DC=Fox,DC=Bks' -filter $Filter)
}