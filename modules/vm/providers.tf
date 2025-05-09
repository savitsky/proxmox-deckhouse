terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.14"
    }
  }
  required_version = ">= 0.13"
}
provider "proxmox" {
  pm_api_url          = "https://192.168.4.60:8006/api2/json"
  pm_api_token_id     = "terraform-prov@pve!terraform-token"
  pm_api_token_secret = "6b2110fb-c996-4d0a-92fc-22d738c24392"
  pm_tls_insecure     = true
  pm_debug            = true
  pm_parallel         = 1
}