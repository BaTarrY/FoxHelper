function Invoke-RemoveFiles
  {
    param (
     [Parameter(Mandatory=$true,HelpMessage='Path to files',ValueFromPipeline=$true,Position=3)][string]$Path,
     [Parameter(Position=4)][ValidateScript({$_ -ge 0})][Int]$OlderThen,
     [Parameter(ParameterSetName="Delete",Position=0)][Switch]$Recourse,
     [Parameter(ParameterSetName="Delete",Position=1)][Switch]$IncludeFolders
    )
    if(!($OlderThen)){$OlderThen=0}
    $CurrentDate = Get-Date
    $DatetoBeDeleted = $CurrentDate.AddDays($OlderThen*-1)
    IF($Recourse.IsPresent -and !($IncludeFolders.IsPresent) ){Get-ChildItem $Path -Recurse  | Where-Object { $_.CreationTime  -lt $DatetoBeDeleted } | where-object { !$_.PSisContainer } |Remove-Item}
    elseif($Recourse.IsPresent -and ($IncludeFolders.IsPresent)){Get-ChildItem $Path -Recurse  | Where-Object { $_.CreationTime  -lt $DatetoBeDeleted } |Remove-Item  -Recurse}
    Else {Get-ChildItem $Path | Where-Object { $_.CreationTime  -lt $DatetoBeDeleted } |Where-Object { !$_.PSisContainer } |Remove-Item}
   
  }