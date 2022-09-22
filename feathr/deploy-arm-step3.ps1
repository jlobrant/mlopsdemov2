$userId=""
$synapse_workspace_name=""
$keyvault_name=""
$objectId=$(az ad user show --id $userId --query id -o tsv)
$rggroup=""

az keyvault update --name $keyvault_name --enable-rbac-authorization false --resource-group $rggroup
az keyvault set-policy -n $keyvault_name --secret-permissions get list --object-id $objectId --resource-group $rggroup
az role assignment create --assignee $userId --role "Storage Blob Data Contributor" --resource-group $rggroup
az synapse role assignment create --workspace-name $synapse_workspace_name --role "Synapse Contributor" --assignee $userId
