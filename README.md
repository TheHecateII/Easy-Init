# Easy-Init 🚀

![Debian](https://img.shields.io/badge/Debian-11%20%7C%2012%20%7C%2013-A81D33?style=flat-square&logo=debian&logoColor=white)
![Proxmox](https://img.shields.io/badge/Proxmox-VE-E57000?style=flat-square&logo=proxmox&logoColor=white)
![Bash](https://img.shields.io/badge/Shell-Script-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)

**Easy-Init** is a robust automation script designed to generate ready-to-use **Debian Cloud-Init templates** on Proxmox VE.

The script automates the entire workflow: downloading the official cloud image, injecting the QEMU Guest Agent (critical for Ansible provisioning), resizing, and configuring the hardware optimized for cloud environments.

## 🚀 Features

* **Multi-Version Support:** Supports Debian 11 (Bullseye), 12 (Bookworm), and 13 (Trixie/Testing).
* **Auto-Injection:** Automatically installs and enables `qemu-guest-agent` directly into the disk image using `libguestfs-tools`.
* **Storage Agnostic:** Automatically detects and adapts to `local`, `local-lvm`, `zfs`, or `ceph` storage backends.
* **Idempotent:** Safely destroys old templates with the same ID before creating new ones.
* **Zero Dependencies:** Checks for and installs necessary tools (like `libguestfs-tools`) if they are missing.

## 📋 Prerequisites

* A **Proxmox VE** server (Root access required).
* Internet access on the Proxmox node (to fetch the cloud images).

## 🛠️ Quick Usage

You can run **Easy-Init** directly from your Proxmox shell without cloning the repository.

### Syntax
```bash
bash <(curl -s [https://raw.githubusercontent.com/TheHecateII/Easy-Init/main/build_template.sh](https://raw.githubusercontent.com/TheHecateII/Easy-Init/main/build_template.sh)) [VERSION] [STORAGE]
