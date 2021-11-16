function Remove-String
   {
     param (
       [Parameter(Mandatory=$true,HelpMessage='Variable to remove text from',ValueFromPipeline=$true)]$Variable,
       [Parameter(Mandatory=$true,HelpMessage='Text to remove')]$Replace
     )
     foreach ($Replace in $Replace)
     {
       $Variable = $Variable -replace $Replace -replace ''
     }
     return $Variable
			
   }