#!/usr/bin/env bash

# Enable the err trap, code will get called when an error is detected
set -o errtrace 
trap 'echo ERROR: There was an error in ${FUNCNAME-main context}' ERR


# Ensure Azure CLI is installed
type az &> /dev/null
if [[ $? -eq 1 ]]; then
    echo 'Error az was not found.

See instructions on installing Azure CLI. 

https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

'
    exit 1
fi


# Change to correct directory
cd "$(dirname "$0")" || exit


# Function to display the help message
display_help() {

    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  setup <ResourceGroupName> <Location>   : Perform setup"
    echo "  delete <ResourceGroupName>             : Delete all resources"
    echo "  --help  : Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 setup"
    echo "  $0 delete"
    
}


setup() {

    local rgname
    local location

    if [ -z "$2" ]; then
        read -rp 'Enter a resource group name: ' rgname
    else 
        rgname=$2
    fi

    if [ -z "$3" ]; then
        read -rp 'Enter a location (recommended: eastus): ' location
    else 
        location=$3
    fi
        
    echo
    echo "# SETUP"
    echo


    if az group create \
        --only-show-errors \
        -o none \
        --name "$rgname" \
        --location "$location";
    then
        echo "Created resource group: ${rgname}"
    else
        echo "Error during create resource group" >&2
        exit 1
    fi


    if az network vnet create \
        --only-show-errors \
        -o none \
        --resource-group "$rgname" \
        --name "$rgname"-vnet \
        --subnet-name "$rgname"-subnet \
        --location "$location";
    then
        echo "Created a virtual network: $rgname-vnet"
    else
        echo "Error during create virtual network" >&2
        exit 1
    fi


    if az network nsg create \
        --only-show-errors \
        -o none \
        --resource-group "$rgname" \
        --name "$rgname"-nsg;
    then
        echo "Created a network security group: $rgname-nsg"
    else
        echo "Error during create network security group" >&2
        exit 1
    fi


    if az network nsg rule create \
        --only-show-errors \
        -o none \
        --resource-group "$rgname" \
        --nsg-name "$rgname"-nsg \
        --name Allow-80-Inbound \
        --priority 110 \
        --source-address-prefixes '*' \
        --source-port-ranges '*' \
        --destination-address-prefixes '*' \
        --destination-port-ranges 80 \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --description "Allow inbound on port 80.";
    then
        echo "Created nsg rule: allow access on port 80"
    else
        echo "Error during create nsg rule" >&2
        exit 1
    fi


    for i in $(seq 1 2 ); do
        if az network nic create \
            --only-show-errors \
            -o none \
            --resource-group "$rgname" \
            --name "$rgname-nic${i}" \
            --vnet-name "$rgname"-vnet \
            --subnet "$rgname"-subnet \
            --network-security-group "$rgname"-nsg;
        then
            echo "Created nic: $rgname-nic${i}" 
        else
            echo "Error during create nic" >&2
            exit 1
        fi
    done 


    for i in $(seq 1 2 ); do
        if az vm create \
            --only-show-errors \
            -o none \
            --location "$location" \
            --admin-username azureuser \
            --resource-group "$rgname" \
            --name "$rgname-vm${i}" \
            --nics "$rgname-nic${i}" \
            --image Ubuntu2204 \
            --generate-ssh-keys 
        then
            echo "Created virtual machine: $rgname-vm${i}"
        else
            echo "Error during create virtual machine" >&2
            exit 1
        fi
    done
    
    for i in $(seq 1 2 ); do
        if az vm run-command invoke \
            -o none \
            --only-show-errors \
            --resource-group "$rgname" \
            --name "$rgname-vm${i}" \
            --command-id RunShellScript \
            --scripts "apt-get update && apt-get install -y nginx" 
        then
            echo "Installed nginx on: $rgname-vm${i}"
        else
            echo "Error during nginx installation on: $rgname-vm${i}" >&2
            exit 1
        fi

        if az vm run-command invoke \
            -o none \
            --only-show-errors \
            --resource-group "$rgname" \
            --name "$rgname-vm${i}" \
            --command-id RunShellScript \
            --scripts "echo '<head><title>Web server ${i}</title></head><body><h1>Web Portal</h1><p>Web server ${i}</p></body>' > /var/www/html/index.nginx-debian.html && service nginx restart"
        then
            echo "Deployed site on: $rgname-vm${i}"
        else
            echo "Error during deploy site on: $rgname-vm${i}" >&2
            exit 1
        fi
    done

    echo
    echo "# FINISHED"
    echo
}


delete() {

    local rgname

    if [ -z "$2" ]; then
        read -rp 'Enter a resource group name: ' rgname
    else 
        rgname=$2
    fi


    echo 
    echo "# DELETE"
    echo

    if az group delete --name "${rgname}"; then
        echo "Deleted resource group ${rgname}"
    else
        echo "Error during delete web app" >&2
        exit 1
    fi

    echo 
    echo "# FINISHED"
    echo 

}


# Check if no arguments were provided, or if the --help option was used
if [ $# -eq 0 ] || [[ "${1-}" =~ ^-*h(elp) ]]; then
    display_help
    exit 0
fi

# Process the command-line arguments
case "$1" in
    setup)
        setup "$@" 
        ;;
    delete)
        delete "$@" 
        ;;
    *)
        echo "Invalid option: $1"
        display_help
        exit 1 
        ;;
esac


