$resource_prefix=""

# Please don't change this name, a corresponding webapp with same name gets created in subsequent steps.
$sitename="${resource_prefix}webapp"


# Fetch the ClientId, TenantId and ObjectId for the created app
$aad_clientId=$(az ad app list --display-name $sitename --query [].appId -o tsv)

# We just use the homeTenantId since a user could have access to multiple tenants
$aad_tenantId=$(az account show --query "[homeTenantId]" -o tsv)

#Fetch the objectId of AAD app to patch it and add redirect URI in next step.
$aad_objectId=$(az ad app list --display-name $sitename --query [].id -o tsv)

# Make sure the above command ran successfully and the values are not empty. If they are empty, re-run the above commands as the app creation could take some time.
# MAKE NOTE OF THE CLIENT_ID & TENANT_ID FOR STEP #2
Write-Output "AZURE_AAD_OBJECT_ID: $aad_objectId" | Out-File output-arm-step2.txt -Append
Write-Output "AAD_CLIENT_ID: $aad_clientId" | Out-File output-arm-step2.txt -Append
Write-Output "AZURE_TENANT_ID: $aad_tenantId" | Out-File output-arm-step2.txt -Append

# Updating the SPA app created above, currently there is no CLI support to add redirectUris to a SPA, so we have to patch manually via az rest
az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$aad_objectId" --headers "Content-Type=application/json" --body "{spa:{redirectUris:['https://$sitename.azurewebsites.net']}}"