#                                Deckhouse Terraform
This code is used to automate the installation of a Deckhouse Kubernetes cluster on a Proxmox hypervisor

The main goal is to trigger a pipeline on every push to the repository that will automatically create virtual servers, install the required packages on them, verify domains, create or update DNS records, and install a Deckhouse Kubernetes cluster on these virtual servers.
