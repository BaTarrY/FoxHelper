function Find-String
   {
     param (
       [Parameter(Mandatory=$true,HelpMessage='Path to search at.',ValueFromPipeline=$true)]$Path,
       [Parameter(Mandatory=$true,HelpMessage='Value to search.')]$Keyword
     )
     $Files = Get-ChildItem -path $Path -Recurse | Select-String -Pattern ([Regex]::Escape($Keyword)) -List | Select-Object -Unique Path |Format-Table -AutoSize
     return $Files
   }