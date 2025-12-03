#!/bin/bash
set -e

# ==============================================================================
#  MASTER SCRIPT: DEBIAN CLOUD TEMPLATE CREATOR (11, 12, 13)
#  Usage: ./script.sh [VERSION] [STORAGE]
#  Ex:    ./script.sh 12 local-lvm
# ==============================================================================

# --- 1. ARGUMENT HANDLING ---
DEBIAN_VERSION=${1:-12}     # Default: 12
TARGET_STORAGE=${2:-local}  # Default: local

# --- 2. VERSION CONFIGURATION ---
case $DEBIAN_VERSION in
  11)
    CODENAME="bullseye"
    TEMPLATE_ID=9011
    URL="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    ;;
  12)
    CODENAME="bookworm"
    TEMPLATE_ID=9012
    URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    ;;
  13)
    CODENAME="trixie"
    TEMPLATE_ID=9013
    # Debian 13 is testing/daily, specific URL required
    URL="https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.qcow2"
    ;;
  *)
    echo "❌ Error: Unsupported version. Choose 11, 12, or 13."
    exit 1
    ;;
esac

TEMPLATE_NAME="debian-${DEBIAN_VERSION}-${CODENAME}-cloud"
IMAGE_FILENAME="debian-${DEBIAN_VERSION}-cloud-image.qcow2"

# --- 3. DEPENDENCY CHECK ---
if ! command -v virt-customize &> /dev/null; then
    echo "⚠️  'virt-customize' tool is missing."
    echo "🔄 Automatically installing libguestfs-tools..."
    apt-get update -qq && apt-get install -y libguestfs-tools
fi

# --- 4. INFO DISPLAY ---
echo "=========================================="
echo "🛠  CREATING DEBIAN TEMPLATE $DEBIAN_VERSION ($CODENAME)"
echo "🆔  Template ID : $TEMPLATE_ID"
echo "💾  Storage     : $TARGET_STORAGE"
echo "🌐  Source      : $URL"
echo "=========================================="

# --- 5. CLEANUP ---
echo "🧹 Cleaning up existing files..."
qm destroy $TEMPLATE_ID > /dev/null 2>&1 || true
rm -f $IMAGE_FILENAME

# --- 6. DOWNLOAD ---
echo "⬇️  Downloading disk image..."
wget -q --show-progress "$URL" -O "$IMAGE_FILENAME"

# --- 7. QEMU AGENT INJECTION ---
echo "💉 Injecting QEMU-Guest-Agent..."
# Install and enable service to ensure connectivity
virt-customize -a $IMAGE_FILENAME --install qemu-guest-agent --run-command 'systemctl enable qemu-guest-agent' > /dev/null 2>&1

# --- 8. VM CREATION ---
echo "🔨 Creating VM..."
# CORRECTION ICI : J'ai retiré ",cpu=host" qui était dans net0
qm create $TEMPLATE_ID --name "$TEMPLATE_NAME" --memory 2048 --net0 virtio,bridge=vmbr0

# --- 9. DISK IMPORT (DYNAMIC) ---
echo "💾 Importing disk to '$TARGET_STORAGE'..."
# Capture exact disk path regardless of storage type (local, lvm, zfs, etc.)
IMPORTED_DISK=$(qm importdisk $TEMPLATE_ID $IMAGE_FILENAME $TARGET_STORAGE --format qcow2 | tail -n 1 | awk '{print $NF}' | sed "s/'//g")

echo "   ✅ Disk created: $IMPORTED_DISK"

# --- 10. HARDWARE CONFIGURATION ---
echo "⚙️  Configuring hardware..."
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $IMPORTED_DISK
qm set $TEMPLATE_ID --ide2 $TARGET_STORAGE:cloudinit
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

# C'est ici qu'on définit le CPU correctement (séparé du réseau)
qm set $TEMPLATE_ID --cpu host

# --- 11. CONVERSION ---
echo "📦 Converting to Template..."
qm template $TEMPLATE_ID

# --- 12. FINAL CLEANUP ---
rm -f $IMAGE_FILENAME

echo ""
echo "✅ SUCCESS! Debian $DEBIAN_VERSION Template (ID $TEMPLATE_ID) is ready."
