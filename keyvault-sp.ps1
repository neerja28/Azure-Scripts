# Using SP credentials to log in to Azure
# Must have Key Vault Contributor role (Microsoft.KeyVault/vaults/write)
# it lets the SP manage key vaults, but does not have access to them
$tenantId= $env:tenantId
$spName = $env:spName
$clientId= $env:clientId
$clientSecret= $env:clientSecret
$secSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $secSecret

try {
        # Sign in to Azure 
        Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential -ErrorAction Stop
        # Set SP to be used to retrive Object ID
        $sp = Get-AzADServicePrincipal -DisplayName $spName
        # Get the list of all subscriptions which SP has access to
        $Subscriptions = Get-AzSubscription -TenantId $tenantId
        foreach($subscription in $Subscriptions)
        {
            Set-AzContext -SubscriptionId $subscription.Id
            # Get the list of all the RGs part of the subscription
            $rgs =  Get-AzResourceGroup 
            foreach ($rg in $rgs)
            {   
                # Get the list of all the Keyvaults part of the RG
                $keyvaults = Get-AzKeyVault -ResourceGroupName $rg.ResourceGroupName
                foreach ($keyvault in $keyvaults)
                {
                    $kv = Get-AzKeyVault -VaultName $keyvault.VaultName
                    if($kv.enableRbacAuthorization -eq $false)
                    {
                        Write-Host "Keyvault ->" $keyvault.VaultName "Resource Group ->" $rg.ResourceGroupName ";"
                        # Adding SP with Get, List key and secret permissions to the KV using Access policy
                        Set-AzKeyVaultAccessPolicy -VaultName $keyvault.VaultName -ResourceGroupName $rg.ResourceGroupName -ObjectId $sp.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list
                    }
                }
            }
        }
}
catch {
    write-output "An error has occured!!!";
    write-output  $_.Exception.message;
}