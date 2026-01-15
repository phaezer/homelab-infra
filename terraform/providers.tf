# Provider Configurations
# All provider setup and authentication

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token

  ssh {
    agent    = true
    username = "terraform"
  }
}
