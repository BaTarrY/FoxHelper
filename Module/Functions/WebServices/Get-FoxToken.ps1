function Get-FoxToken
  {
    param (
      [Parameter(Mandatory=$true,HelpMessage='Site URL. HTTPS by Default if not specified',ValueFromPipeline=$true)]$SiteURL,
      [Parameter(Mandatory=$true,HelpMessage='User Login Name')]$UserName,
      [Parameter(Mandatory=$true,HelpMessage='User Login Password')]$Password
    )
    if(!($SiteURL.startswith('https://')) -and !($SiteURL.startswith('http://'))){$SiteURL='https://'+$SiteURL}
    $RequestURL=$SiteURL+'/SOA/WCFAuthenticationSrv/WCFAuthentication.svc/httpsecure/GetUserTokenByLogin'
    $RequestJSON="{
    ""userName"": ""$UserName"",
    ""password"": ""$Password""}"
    $Token=Invoke-RestMethod -Uri $RequestURL -Method Post -ContentType 'application/json' -Body $RequestJSON
    $Token=$Token -replace '@{GetUserTokenByLoginResult=','' -replace '}',''
		return $Token
  }