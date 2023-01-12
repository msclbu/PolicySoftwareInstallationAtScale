param(
    [string]$mgID,
    [string]$resourceGroupName,
    [string]$storageAccountName,
    [string]$location,
    [string]$automationAccountName,
    [string]$storageAccountResourceGroupName,
    [string]$subscriptionID,
    [string]$mgName
)

$params = @{
    resourceGroupName     = $resourceGroupName #"" # <-- Change this value for the Resource Group Name
    storageAccountName    = $storageAccountName#"" # <-- Change this value - must be globally unique
    location              = $location #"" # <-- Change this value to a location you want
    automationAccountName = $automationAccountName #"" # <-- Change this value for the Automation Account Name
    storageAccountResourceGroupName = $storageAccountResourceGroupName #''
    subscriptionID = $subscriptionID
}
#Create Resource Group
New-AzResourceGroup -Name $params.resourceGroupName -Location 'australiaeast' -Force

#Deploy main Bcicep template
Write-Host "Deploying Infrastructure" -ForegroundColor Green
New-AzResourceGroupDeployment -ResourceGroupName $params.resourceGroupName -TemplateFile .\deploy.bicep -TemplateParameterObject $params -Verbose `
-mgId $mgID

#Get automation account
$automationAccount = Get-AzAutomationAccount -ResourceGroupName $params.resourceGroupName -Name $params.automationAccountName

#Create Azure Policy definitions from JSON Templates
$linuxPolicyDef = New-AzPolicyDefinition -Name 'Install Linux Apps via tags Policy Definition' -Policy ./policyDefinitionLinuxTags.json -ManagementGroupName $mgName
$windowsPolicyDef = New-AzPolicyDefinition -Name 'Install Windows Apps via tags Policy Definition' -Policy ./policyDefinitionWindowsTags.json -ManagementGroupName $mgName

#Publish Runbooks
Write-Host "Publishing Windows runbook to automation account" -ForegroundColor Green
$automationAccount | Import-AzAutomationRunbook -Name deployPowerShellWin -Path .\deployPowershellWin.ps1 -Type PowerShell -Force -Published

Write-Host "Publishing Linux runbook to automation account" -ForegroundColor Green
$automationAccount | Import-AzAutomationRunbook -Name deployGitLinux -Path .\deployGitLinux.ps1 -Type PowerShell -Force -Published

#Generate webhooks for published runbooks
Write-Host "Generating Windows webhook" -ForegroundColor Green
$whWin = $automationAccount | New-AzAutomationWebhook -Name WHWin -ExpiryTime (Get-Date).AddYears(1) -RunbookName deployCrowdstrikeWin -IsEnabled $true -Force

Write-Host "Generating Linux webhook" -ForegroundColor Green
$whLinux = $automationAccount | New-AzAutomationWebhook -Name WHLinux -ExpiryTime (Get-Date).AddYears(1) -RunbookName deployCrowdstrikeLinux -IsEnabled $true -Force

Write-Host "Deploying software installation policy" -ForegroundColor Green
$policyOutput = New-AzManagementGroupDeployment -ManagementGroupId $mgName -TemplateFile ".\deployPolicy.bicep" -location $params.location `
-locationFromTemplate $params.location `
-policyDefinitionIdWindows ($windowsPolicyDef.ResourceId) `
-policyDefinitionIdLinux ($linuxPolicyDef.ResourceId) 

$policyAssignmentIdWin = $policyOutput.Outputs["assignmentIdWin"].Value
$policyAssignmentIdLinux = $policyOutput.Outputs["assignmentIdLinux"].Value

#Deploy event grid
Write-Host "Deploying event grid subscription and topics" -ForegroundColor Green
New-AzResourceGroupDeployment -ResourceGroupName $params.resourceGroupName `
    -TemplateFile .\eventGridDeploy.bicep `
    -uriWin ($whWin.WebhookURI | ConvertTo-SecureString -AsPlainText -Force) `
    -uriLinux ($whLinux.WebhookURI | ConvertTo-SecureString -AsPlainText -Force) `
    -topicName "PolicyStateChanges" `
    -policyAssignmentIdWin $($policyAssignmentIdWin) `
    -policyAssignmentIdLinux $($policyAssignmentIdLinux) `
    -Verbose