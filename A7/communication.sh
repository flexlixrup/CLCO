az cognitiveservices account show \
    --resource-group RESOURCE_GROUP \
    --name SERVICE_NAME \
    --query id \
    --output tsv

az network vnet create \
 --resource-group RESOURCE_GROUP \
 --location LOCATION \
 --name VNET_NAME \
 --address-prefixes 10.0.0.0/16

az network vnet subnet create \
 --resource-group RESOURCE_GROUP \
 --vnet-name VNET_NAME \
 --name APP_SUPNET_NAME \
 --address-prefixes 10.0.0.0/24 \
 --delegations Microsoft.Web/serverfarms \
 --disable-private-endpoint-network-policies false

az network vnet subnet create \
 --resource-group RESOURCE_GROUP \
 --vnet-name VNET_NAME \
 --name ENDPOINT_SUBNET_NAME \
 --address-prefixes 10.0.1.0/24 \
 --disable-private-endpoint-network-policies true

az network private-dns zone create \
 --resource-group RESOURCE_GROUP \
 --name "privatelink.cognitiveservices.azure.com"

az network private-dns link vnet create \
 --resource-group RESOURCE_GROUP \
 --name cognitiveservices-zonelink \
 --zone-name privatelink.cognitiveservices.azure.com \
 --virtual-network VNET_NAME \
 --registration-enabled False

az resource update \
 --ids SERVICE_ID \
 --set properties.publicNetworkAccess="Disabled"

az webapp update \
 --resource-group RESOURCE_GROUP \
 --name WEB_APP_NAME \
 --https-only

az webapp vnet-integration add \
 --resource-group RESOURCE_GROUP \
 --name WEB_APP_NAME \
 --vnet VNET_NAME \
 --subnet APP_SUPNET_NAME

# Get the endpoint for the Language service resource
endpoint=$(az cognitiveservices account show \
 --name SERVICE_NAME \
 --resource-group RESOURCE_GROUP \
 --query "properties.endpoint" \
 --output tsv
)

# Get the associated key
 key=$(az cognitiveservices account keys list \
 --name SERVICE_NAME \
 --resource-group RESOURCE_GROUP \
 --query "key1" \
 --output tsv
)

az webapp config appsettings set \
 --resource-group RESOURCE_GROUP \
 --name WEBAPP_NAME \
 --settings AZ_ENDPOINT="$endpoint" AZ_KEY="$key"
