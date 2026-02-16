# Packer configuration for building a DevBox VM using QEMU
#!/usr/bin/env packer

packer {
  required_version = ">= 1.9.0"
  required_plugins {
    qemu = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_path" {
  type    = string
  default = "packer/ubuntu-24.04.3-live-server-amd64.iso"
}

variable "ssh_username" {
  type    = string
  default = "dev"
}

variable "ssh_password" {
  type    = string
  default = "devpass"
}

variable "vm_name" {
  type    = string
  default = "DevBox_VM"
}

variable "disk_size" {
  type    = number
  default = 20000
}

source "qemu" "ubuntu" {
  iso_url           = var.iso_path
  iso_checksum      = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
  output_directory  = "output-devbox-vm"
  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_wait_timeout  = "20m"
  disk_size         = var.disk_size
  format            = "qcow2"
  accelerator       = "kvm"
  headless          = true
}

build {
  name    = "DevBox Build"
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    script = "devbox.sh"
  }

  # Optional: extra scripts
  # provisioner "shell" {
  #   script = "scripts/setup-users.sh"
  # }
}
