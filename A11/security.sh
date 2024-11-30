az group create --name myresourcegroup --location westeurope

az vm create \
 --resource-group myresourcegroup \
 --name my-vm \
 --image UbuntuLTS \
 --admin-username azureuser \
 --location westeurope \
 --generate-ssh-keys

az vm run-command invoke \
  --resource-group myresourcegroup \
  --name my-vm \
  --command-id RunShellScript \
  --scripts "apt-get update && apt-get install -y nginx"

az vm run-command invoke \
 --resource-group myresourcegroup \
 --name my-vm \
 --command-id RunShellScript \
 --scripts "echo '<head><title>Web Portal: '$(hostname)'</title></head><body><h1>Web Portal</h1><p>Web server: <strong>'$(hostname)'</storng></p></body>' > /var/www/html/index.nginx-debian.html && service nginx restart"

IPADDRESS="$(az vm list-ip-addresses \
--resource-group myresourcegroup \
--name my-vm \
--query "[].virtualMachine.network.publicIpAddresses[*].ipAddress" \
--output tsv)"

echo $IPADDRES

az network nsg list \
 --resource-group myresourcegroup \
 --query '[].name' \
 --output tsv

az network nsg rule list \
 --resource-group myresourcegroup \
 --nsg-name my-vmNSG 

az network nsg rule list \
 --resource-group myresourcegroup \
 --nsg-name my-vmNSG \
 --query '[].{Name:name, Priority:priority, Port:destinationPortRange, Access:access}' \
 --output table

az network nsg rule create \
 --resource-group myresourcegroup \
 --nsg-name my-vmNSG \
 --name allow-http \
 --protocol tcp \
 --priority 100 \
 --destination-port-ranges 80 \

az network nsg rule list \
 --resource-group myresourcegroup \
 --nsg-name my-vmNSG \
 --query '[].{Name:name, Priority:priority, Port:destinationPortRange, Access:access}' \
 --output table