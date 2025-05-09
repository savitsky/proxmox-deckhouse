#!/bin/env bash

# Check if the argument (password) is provided
if [ -z "$1" ]; then
  echo "Error! Not set password for user terraform-prov"
  exit 1
fi

passw_terraform_prov_user="$1"

GREEN='\033[0;32m' # Green color
NC='\033[0m'       # Reset color

# Check if libguestfs-tools is already installed
if dpkg -l | grep libguestfs-tools > /dev/null 2>&1; then
    echo -e "${GREEN}The package libguestfs-tools is already installed.${NC}"
else
    echo -e "${GREEN}Installing libguestfs-tools...${NC}"
    apt install -y libguestfs-tools
fi

# Remove existing image if it exists
if [ -e "jammy-server-cloudimg-amd64.img" ]; then
    echo -e "${GREEN}Removing existing image...${NC}"
    rm jammy-server-cloudimg-amd64.img
fi

# Download Ubuntu Cloud Image
echo -e "${GREEN}Downloading Ubuntu Cloud Image...${NC}"
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
echo -e "${GREEN}Done.${NC}"

# Install qemu-guest-agent, mc, htop, fail2ban into the downloaded image
echo -e "${GREEN}Installing qemu-guest-agent, mc, htop, fail2ban into the image...${NC}"
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent,mc,htop,fail2ban
echo -e "${GREEN}Done.${NC}"

# Add SSH keys and firstboot commands
echo -e "${GREEN}Adding SSH keys and firstboot commands...${NC}"
virt-customize -a jammy-server-cloudimg-amd64.img \
    --firstboot-command "echo 'ssh-rsa !!!key-here!!! ' > /root/.ssh/authorized_keys" \
    --firstboot-command "echo 'ssh-rsa !!!key-here!!! gitlab-runner@werf-dev' >> /root/.ssh/authorized_keys" \
    --firstboot-command "sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config" \
    --firstboot-command "sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config" \
    --firstboot-command "systemctl restart ssh" \
    --firstboot-command "cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local" \
    --firstboot-command "systemctl enable --now fail2ban"
echo -e "${GREEN}Done.${NC}"

# Check if VM exists, and delete it if it does
echo -e "${GREEN}Checking if VM with ID 888 exists, and removing it if it does...${NC}"
if qm status 888 > /dev/null 2>&1; then
    echo -e "${GREEN}Deleting VM with ID 888...${NC}"
    qm destroy 888 --purge
fi

# Create and configure a VM that will be used as a template
echo -e "${GREEN}Creating and configuring a virtual machine that will be used as a template...${NC}"
qm create 888 --name ubuntu-cloud-init --memory 4096 --cores 4 --net0 virtio,bridge=vmbr1
qm importdisk 888 jammy-server-cloudimg-amd64.img fast
qm set 888 --scsihw virtio-scsi-pci --scsi0 fast:vm-888-disk-0 --boot c --bootdisk scsi0 --ide2 fast:cloudinit --serial0 socket --agent 1 # --vga serial0
qm template 888
echo -e "${GREEN}Done.${NC}"

# Check if the TerraformProv role exists, and create it if it doesn't
echo -e "${GREEN}Checking if the TerraformProv role exists, and creating it if not...${NC}"
if ! pveum role list --noborder | awk '{print $1}' | grep -q "^TerraformProv$"; then
    pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"
    echo -e "${GREEN}TerraformProv role has been successfully added.${NC}"
else
    echo -e "${GREEN}TerraformProv role already exists.${NC}"
fi

# Check if the terraform-prov@pve user exists, and create it if it doesn't
echo -e "${GREEN}Checking if the user terraform-prov@pve exists, and creating it if not...${NC}"
if ! pveum user list --noborder | awk '{print $1}' | grep -q "^terraform-prov$"; then
    pveum user add terraform-prov@pve --password $passw-terraform-prov-user
    pveum aclmod / -user terraform-prov@pve -role TerraformProv
    echo -e "${GREEN}User terraform-prov@pve has been successfully created and assigned the TerraformProv role.${NC}"
    if [ ! -d /root/scripts ]; then
        mkdir -p /root/scripts
    fi
    pveum user token add terraform-prov@pve terraform-token --privsep 0 > /root/scripts/token_output.txt
else
    echo -e "${GREEN}User terraform-prov@pve already exists.${NC}"
fi
