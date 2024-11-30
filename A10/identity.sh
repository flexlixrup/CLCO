
az role assignment list --assignee <email>

az ad user show --id "<email>" --query "id" --output tsv

az role definition list \
 --query "[].{name:name, roleType:roleType, roleName:roleName}" \
 --output tsv

az group list --query "[].{name:name}" --output tsv

az role assignment create \
 --assignee "<email>" \
 --role "Reader" \
 --resource-group <ResourceGroup>
