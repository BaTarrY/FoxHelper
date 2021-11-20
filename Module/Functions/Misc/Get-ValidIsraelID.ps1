function Get-ValidIsraelID
{
  [CmdletBinding()]
  param ([Parameter(ValueFromPipeline=$true)][int]$FindCheckDigitID)
  if(!($FindCheckDigitID)){ $ID=Get-Random -Minimum 21111111 -Maximum 29999999}
  Else{$ID=$FindCheckDigitID}
  $IDarray=$ID -split '' | Where-Object {$_} 
  $IDLen=$IDarray.Length
  for ($Counter=1;$Counter -le ($IDLen-1);$Counter=$Counter+2)
  {
    [int]$Temp=$IDarray[$Counter]
    $Temp=$Temp*2
    if($Temp -gt 9) {$Temp=1+$Temp%10}
    $IDarray[$Counter]=$Temp
  }
  $IDarray=$IDarray+0
  While(((($IDarray | Measure-Object -Sum).Sum)%10 -ne 0))
  {
    [int]$Temp=10-(($IDarray | Measure-Object -Sum).Sum)%10
    $IDarray[$IDLen]=$Temp
    $ID=($ID*10)+$Temp
  }
  If($IDarray.Length -eq 9) {Return -join $ID}
  Else {Get-ValidID}
}
