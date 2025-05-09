#!/bin/env bash
export ANSIBLE_HOST_KEY_CHECKING=False
master0_ip=$1

GREEN='\033[0;32m' # Green color
NC='\033[0m'       # Reset color

echo -e "${GREEN} ------====== Starting Deckhouse installation ======------ ${NC}"

# Check if master-0 IP address was provided
if [ -z $master0_ip ]; then
    echo -e "${GREEN} We need the IP address of the master-0 node. ${NC}"
else
    echo -e "${GREEN} master-0 IP address is '$master0_ip' ${NC}"
    
    docker run --pull=always -i \
      -v "$PWD/deckhouse/config.yml:/config.yml" \
      -v "$HOME/.ssh/:/tmp/.ssh/" \
      registry.deckhouse.io/deckhouse/ce/install:stable \
      dhctl bootstrap \
      --ssh-user=root \
      --ssh-host=$master0_ip \
      --ssh-agent-private-keys=/tmp/.ssh/id_rsa \
      --config=/config.yml
fi

echo -e "${GREEN} ------====== Deckhouse installation finished ======------ ${NC}"
