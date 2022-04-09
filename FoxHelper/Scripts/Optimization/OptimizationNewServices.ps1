
 
### PRESSING SPACE after  '-OptimizationSite' at the last line will let you choose a site available under the same machine
 
Function Install-FoxOptimizationServices
{
##   Example:       Install-FoxOptimizationServices -OptimizationSite FOX.mydomain.com
param(
[CmdletBinding()]
[Parameter(
            Position=0,
            Mandatory=$true, ValueFromPipeline=$true,
            HelpMessage='OPTimization Site')]
        $OptimizationSite
)
    $ErrorActionPreference='Stop'
    Try{
     Import-Module WebAdministration -Verbose:$false
 
     ##Returning Variables for improved perforamcne
     $SiteSplit=$OptimizationSite.split('.')[0]
     
 
     ##SET Services Names
       ##SchedulerEngineActivator
       $SchedulerEngineService="$SiteSplit" + ': Scheduler Engine Service'
 
       ##OptimizationProcessOrchestrator
       $ProcessOrchestratorService="$SiteSplit" + ': Process Orchestrator Service'
 
 
       ##DataModelBuilder
       $DataModelBuilderService="$SiteSplit" + ': Data Model Builder Service'
 
 
 
     ##Get Paths
       ##TO OPT SITE ROOT
       $OPTServicePath=(Get-Item iis:\sites\$OptimizationSite).physicalpath
 
       ##SchedulerEngineActivator
       $SchedulerEnginePath="$OPTServicePath\SchedulerEngineActivator\bin\Release\SchedulerEngineActivator.exe" + ' -displayname "'+ $SiteSplit +' Optimization: Scheduler Engine Service" -servicename "' + $SiteSplit +' Optimization: Scheduler Engine Service'
 
       ##OptimizationProcessOrchestrator
       $ProcessOrchestratorPath = "$OPTServicePath\OptimizationProcessOrchestratorActivator\bin\Release\OptimizationProcessOrchestratorActivator.exe" + '-displayname "'+ $SiteSplit +' Optimization: Process Orchestrator Service" -servicename "' + $SiteSplit +' Optimization: Process Orchestrator Service"'
       #DataModelBuilder
       $DataModelBuilderPath = "$OPTServicePath\DataModelBuildeActivator\bin\Release\DataModelBuilderActivator.exe" + ' -displayname "'+ $SiteSplit +' Optimization: data model builder service" --servicename "' + $SiteSplit +' Optimization: data model builder service"'
 
    
       ##Validate Paths
        ##SchedulerEngineActivator
       if(!(Test-Path $SchedulerEnginePath)){
       Write-host "Could not find the file $SchedulerEnginePath" -ForegroundColor Red
       exit}
 
        ##OptimizationProcessOrchestrator
       if(!(Test-Path $ProcessOrchestratorPath)){
       Write-host "Could not find the file $ProcessOrchestratorPath" -ForegroundColor Red
       exit}
 
        #DataModelBuilder
       if(!(Test-Path $DataModelBuilderPath)){
       Write-host "Could not find the file $DataModelBuilderPath" -ForegroundColor Red
       exit}
 
 
 
     ##Get and secure user and password
     $Username = (Get-ItemProperty "IIS:\Sites\$OptimizationSite").userName 
     $Password = (Get-ItemProperty "IIS:\Sites\$OptimizationSite").password
     $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
     $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
 
 
     ##Service Creation & start
        ##SchedulerEngineActivator
     Write-Host "Creating '$SchedulerEngineService'" -ForegroundColor Magenta
     New-Service -Name $SchedulerEngineService -BinaryPathName $SchedulerEnginePath -StartupType 'Automatic' -Credential $Credentials -displayname $SchedulerEngineService -Description $SchedulerEngineService
     
        ##OptimizationProcessOrchestrator
     Write-Host "Creating '$ProcessOrchestratorService'" -ForegroundColor Magenta
     New-Service -Name $ProcessOrchestratorService -BinaryPathName $ProcessOrchestratorPath -StartupType 'Automatic' -Credential $Credentials -displayname $ProcessOrchestratorService -Description $ProcessOrchestratorService
 
 
      #DataModelBuilder
     Write-Host "Creating '$DataModelBuilderService'" -ForegroundColor Magenta
     New-Service -Name $DataModelBuilderService -BinaryPathName $DataModelBuilderPath -StartupType 'Automatic' -Credential $Credentials -displayname $DataModelBuilderService -Description $DataModelBuilderService
 
     
     
     
     ##Setting services as Automatic-Delayed
        ##SchedulerEngineActivator
     & "$env:windir\system32\sc.exe" config $SchedulerEngineService start= delayed-auto
 
        ##OptimizationProcessOrchestrator
     & "$env:windir\system32\sc.exe" config $ProcessOrchestratorService start= delayed-auto
 
        #DataModelBuilder
     & "$env:windir\system32\sc.exe" config $DataModelBuilderService start= delayed-auto
 
 
 
     ##Starting Services
        ##SchedulerEngineActivator
     start-service -Name $SchedulerEngineService
        #DataModelBuilder
    start-service -Name $DataModelBuilderService
     
        ##OptimizationProcessOrchestrator
     start-service -Name $ProcessOrchestratorService
 
    }
    Catch{
    Write-host "An Error occured. See full expection below.`nExecption:"$Error[0].Exception"`nTargetObject:"$Error[0].TargetObject"`nInvocationInfo:"$Error[0].InvocationInfo -ForegroundColor Red}
    }
 
    Install-FoxOptimizationServices -OptimizationSite 'ENTER OPTimization site NAME HERE'
