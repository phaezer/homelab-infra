terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }
  }
}
