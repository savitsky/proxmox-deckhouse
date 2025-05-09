#!/bin/env bash
#--------------------==================== Script for creating domains and checking A records ====================--------------------
export ANSIBLE_HOST_KEY_CHECKING=False

GREEN='\033[0;32m' # Green color
NC='\033[0m'       # Color reset

# Read variables dh_domain and target_value from ./deckhouse/vars.yaml
# dh_domain contains the base domain for checks
# target_value is the expected IP address in the A records
dh_domain=$(grep "dh_domain:" ./deckhouse/vars.yaml | awk '{print $2}' | tr -d '"')
target_value=$(grep "target_value:" ./deckhouse/vars.yaml | awk '{print $2}' | tr -d '"')

# Array of domains to check
declare -a domains=("dex.$dh_domain" "dashboard.$dh_domain" "documentation.$dh_domain" "grafana.$dh_domain" "status.$dh_domain" "upmeter.$dh_domain")

# Flag indicating whether the playbook should be run to create or update A records
run_playbook=false

# Check each domain
for domain in "${domains[@]}"; do
    if nslookup $domain &>/dev/null; then
        # If the A record exists, resolve its IP
        resolved_ip=$(nslookup $domain | grep 'Address: ' | tail -n 1 | awk '{print $2}')
        if [[ "$resolved_ip" != "${target_value}" ]]; then
            echo "A record for $domain resolves to $resolved_ip, but expected ${target_value}! Fixing it now!"
            run_playbook=true
        else
          echo "Domains are OK, moving on to master-0 setup."
        fi
    else
        echo "A record for $domain not found! Fixing it now!"
        run_playbook=true
    fi
done

# If necessary, run the playbook to create or update domains
if $run_playbook; then
    ansible-playbook ./deckhouse/create-domains.yaml
fi
