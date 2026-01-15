# Terraform and Provider Version Requirements

terraform {
  required_version = ">= 1.14"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    macaddress = {
      source = "ivoronin/macaddress"
      version = "~> 0.3.2"
    }
  }
}
