Param([object]$WebhookData)

$eventData = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

if ($eventData.subject -match 'microsoft.compute/virtualmachines') {
    $vmName = $eventData.subject.Split('/')[8]
    $vmResourceGroupName = $eventData.subject.Split('/')[4]
    $vmSubscription = $eventData.subject.Split('/')[2]

    Connect-AzAccount -Identity

    $storageAccountName = Get-AutomationVariable "StorageAccountName"
    $resourceGroupName = Get-AutomationVariable "ResourceGroupName"

    $ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

    $scriptBlock = @'

#!/usr/bin/env bash
#set -eux
sudo dnf install git-all
'@

    $scriptBlock | Out-File $env:Temp\script.sh

    Set-AzContext -SubscriptionId $vmSubscription
    Invoke-AzVMRunCommand -ResourceGroupName $vmResourceGroupName -VMName $vmName -ScriptPath $env:Temp\script.sh -CommandId 'RunShellScript'  -Verbose
}
else {
    Write-Output "Event subject does not match microsoft.compute"
}


