#!/usr/bin/env bash
# Cree une VM QEMU/KVM (libvirt) pour tester l'installation : UEFI sans Secure Boot, Q35,
# CPU host-passthrough (le script CachyOS detecte znver4), 2 disques virtio pour tester
# l'ajout du second NVMe au Btrfs, virtio-gpu avec OpenGL (obligatoire pour Hyprland).
#
#   ./scripts/vm/create-test-vm.sh ~/Downloads/archlinux-x86_64.iso
#   virt-viewer --connect qemu:///system --attach arch-dots-test
#
# Ecran noir avec OpenGL (hote NVIDIA) : NO_GL=1 ./scripts/vm/create-test-vm.sh <iso>  (rendu logiciel)
# Supprimer la VM : virsh -c qemu:///system destroy arch-dots-test; virsh -c qemu:///system undefine arch-dots-test --nvram --remove-all-storage
#
# Prerequis sur l'hote Arch :
#   sudo pacman -S --needed libvirt qemu-desktop virt-install virt-viewer dnsmasq edk2-ovmf
#   sudo usermod -aG libvirt "$USER"; sudo systemctl enable --now libvirtd
#   sudo virsh net-start default; sudo virsh net-autostart default
set -euo pipefail
ISO="${1:?usage: $0 <archlinux.iso> [nom] [taille_disque1_G] [taille_disque2_G]}"
NAME="${2:-arch-dots-test}"
D1="${3:-40}"; D2="${4:-40}"
# Pool systeme : qemu tourne sous l'utilisateur libvirt-qemu, qui ne peut pas lire ~/Telechargements
# ni ecrire dans le home. Les images et l'ISO vont donc dans /var/lib/libvirt/images.
POOL="${LIBVIRT_POOL_DIR:-/var/lib/libvirt/images}"
[[ -r "$ISO" ]] || { echo "ISO introuvable : $ISO" >&2; exit 1; }
sudo mkdir -p "$POOL"
ISO_SYS="$POOL/$(basename "$ISO")"
if [[ ! -f "$ISO_SYS" ]]; then echo "Copie de l'ISO vers $ISO_SYS"; sudo cp "$ISO" "$ISO_SYS"; sudo chmod 0644 "$ISO_SYS"; fi
ISO="$ISO_SYS"
RENDER=$(ls /dev/dri/renderD* 2>/dev/null | head -1)
[[ "${NO_GL:-0}" == 1 ]] && RENDER=""
GFX="spice,listen=none"
[[ "${NO_GL:-0}" == 1 ]] || GFX="$GFX,gl.enable=yes${RENDER:+,rendernode=$RENDER}"
id -nG | grep -qw libvirt || echo "Avertissement : tu n'es pas dans le groupe libvirt (sudo usermod -aG libvirt $USER, puis reconnexion)" >&2
systemctl is-active -q libvirtd || { echo "libvirtd inactif : sudo systemctl enable --now libvirtd" >&2; exit 1; }
virsh --connect qemu:///system net-info default >/dev/null 2>&1 || echo "Avertissement : reseau 'default' absent (sudo virsh net-start default)" >&2

if virsh --connect qemu:///system dominfo "$NAME" >/dev/null 2>&1; then
  echo "La VM $NAME existe deja. Supprimer : virsh destroy $NAME; virsh undefine $NAME --nvram --remove-all-storage" >&2
  exit 1
fi

virt-install --connect qemu:///system \
  --name "$NAME" --osinfo archlinux \
  --machine q35 --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no \
  --cpu host-passthrough,topology.sockets=1,topology.cores=4,topology.threads=2 --vcpus 8 \
  --memory 8192 \
  --disk "path=$POOL/$NAME-nvme0.qcow2,size=$D1,bus=virtio,format=qcow2,discard=unmap" \
  --disk "path=$POOL/$NAME-nvme1.qcow2,size=$D2,bus=virtio,format=qcow2,discard=unmap" \
  --cdrom "$ISO" \
  --network network=default,model=virtio \
  --video virtio \
  --graphics "$GFX" \
  --sound none --channel spicevmc \
  --noautoconsole

state=$(virsh --connect qemu:///system domstate "$NAME" 2>/dev/null || echo inconnu)
echo "Etat de la VM : $state"
if [[ "$state" != running ]]; then
  echo "La VM n'est pas demarree : virsh --connect qemu:///system start $NAME ; journal : journalctl -u libvirtd -n 50" >&2
fi
cat <<EOT

VM $NAME creee. Console : virt-viewer --connect qemu:///system --attach $NAME
Dans la VM : les disques sont /dev/vda (archinstall) et /dev/vdb (DOTS_BTRFS_EXTRA_DEVICE).
Dans config.env : DOTS_VM=1, DOTS_MONITOR="Virtual-1", DOTS_BTRFS_EXTRA_DEVICE="/dev/vdb".
Snapshot apres archinstall : virsh snapshot-create-as $NAME post-archinstall
Retour au snapshot        : virsh snapshot-revert $NAME post-archinstall
EOT
