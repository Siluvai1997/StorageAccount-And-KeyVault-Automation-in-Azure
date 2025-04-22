<#
Update Network and firewall entries in Storage accounts in Azure Subscriptions
A string to match against subscription names (e.g. "Test" to target all "*Test*" subscriptions).
#>
Write-Output "Running PowerShell Script..."
Import-Module Az.ResourceGraph

# Configuration
$requiredIPs = $env:Target -split '\s*,\s*' 
$EnvironmentName = $env:Environment

# Get all subscriptions matching the keyword
$subs = Get-AzSubscription | Where-Object { $_.Name -like "*$EnvironmentName*" }
if (-not $subs) {
    Write-Output "No subscriptions found matching '*$EnvironmentName*'."
    exit 0
}

foreach ($sub in $subs) {
    Write-Output "Processing subscription: $($sub.Name) ($($sub.Id))"
    Set-AzContext -SubscriptionId $sub.Id
    
    # Use subscriptionId to set the context
    Set-AzContext -Subscription $subscription.subscriptionId | Out-Null

    # Get the storage accounts info
    $storageAccounts = Get-AzStorageAccount
    # Iterate through each storage account
    foreach ($account in $storageAccounts) {
        try {
            $resourceGroup = $account.ResourceGroupName
            $accountName = $account.StorageAccountName
            
            # Get the current network rule configuration
            $networkRules = Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroup -Name $accountName

            # Check if public network access is enabled and if the firewall is restricted
            $publicNetworkAccess = $account.PublicNetworkAccess ?? "Enabled"
            if ($publicNetworkAccess -ne "Enabled" -or $networkRules.DefaultAction -eq "Allow") {
                Write-Output "Skipping $accountName - Public network access not restricted or default action is Allow"
                continue
            }

            # Get existing IP rules from the network rule set
            $existingIPs = @($networkRules.IPRules | ForEach-Object { $_.IPAddressOrRange })

            # Determine which IPs need to be added
            $ipsToAdd = $requiredIPs | Where-Object { $_ -notin $existingIPs }
            if ($ipsToAdd.Count -eq 0) {
                Write-Output "No changes needed for $accountName - All IPs already exist"
                continue
            }

            # Add new IPs without affecting existing rules
            Add-AzStorageAccountNetworkRule -ResourceGroupName $resourceGroup -Name $accountName -IPAddressOrRange @($ipsToAdd)
            Write-Output "Added IPs [$($ipsToAdd -join ', ')] to $accountName"

        } catch {
            Write-Error "Error processing $accountName: $_"
        }
    }
	
    Write-Output "====== End of Subscription: $($subscription.name) ========"
}
 Write-Output "Updates completed....."
