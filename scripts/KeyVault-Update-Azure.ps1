<#
Update Network and firewall entries in Key vaults in Azure Subscriptions
A string to match against subscription names (e.g. "Test" to target all "*Test*" subscriptions).
#>
Import-Module Az.ResourceGraph

# Get the Environment name and required Ips
$EnvironmentName = $env:Environment
$requiredIps = $env:Target -split '\s*,\s*'

# Get all subscriptions matching the keyword
$subs = Get-AzSubscription | Where-Object { $_.Name -like "*$EnvironmentName*" }
if (-not $subs) {
    Write-Output "No subscriptions found matching '*$EnvironmentName*'."
    exit 0
}

foreach ($sub in $subs) {
    Write-Output "Processing subscription: $($sub.Name) ($($sub.Id))"
    Set-AzContext -SubscriptionId $sub.Id

    $keyVaults = Get-AzKeyVault
    foreach ($kv in $keyVaults) {
        try {
            $resourceGroup = $kv.ResourceGroupName
            $vaultName = $kv.VaultName

            # Explicitly get the latest Key Vault settings
            $kvDetails = Get-AzKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup

            # Process only if the Key Vault is configured for selected networks.
            if ($kvDetails.NetworkAcls.DefaultAction -eq "Allow") {
                Write-Output "Skipping $vaultName because its default network rule action is 'Allow'"
                continue
            }

            # Fetch Existing IP Rules from NetworkAcls
            $existingIps = @(
                $kvDetails.NetworkAcls.IpAddressRanges |
                Where-Object { -not [string]::IsNullOrEmpty($_) }
            )

            Write-Output "Existing IPs for $vaultName: $existingIps"

            ## Identify New IPs That Need to Be Added
            $ipsToAdd = $requiredIps | Where-Object { $_ -notin $existingIps }

            if ($ipsToAdd.Count -eq 0) {
                Write-Output "No new IPs to add for $vaultName. All IPs already exist."
                continue
            }

            ## Add All New IPs in a Single Command
            Add-AzKeyVaultNetworkRule -VaultName $vaultName -ResourceGroupName $resourceGroup -IpAddressRange @($ipsToAdd) -ErrorAction SilentlyContinue

            Write-Output "Added IPs [$($ipsToAdd -join ', ')] to $vaultName"

        }
        catch {
            Write-Error "Error processing Key Vault $vaultName: $_"
        }
    }
   Write-Output "Updates completed....."
}
Write-Output "End of PowerShell script...."
