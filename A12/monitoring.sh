az group create --name myresourcegroup --location westeurope

STORAGE=metricsstorage$RANDOM
az storage account create \
  --name $STORAGE \
  --sku Standard_LRS \
  --location westeurope \
  --resource-group myresourcegroup

az vm create \
 --name monitored-linux-vm \
 --image UbuntuLTS \
 --size Standard_B1s \
 --location westeurope \
 --admin-username azureuser \
 --boot-diagnostics-storage $STORAGE \
 --resource-group myresourcegroup \
 --generate-ssh-key