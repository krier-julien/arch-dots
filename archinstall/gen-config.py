#!/usr/bin/env python3
"""Genere archinstall/user_configuration.json pour un disque donne.

archinstall (3.x) n'accepte pas de taille en pourcentage : la partition Btrfs doit avoir une
taille explicite, calculee ici a partir de la taille reelle du disque. A lancer sur le live
ISO (python3 et lsblk y sont presents) :

    python3 archinstall/gen-config.py --device /dev/nvme0n1 -o /tmp/config.json
    archinstall --config /tmp/config.json --creds /tmp/creds.json

Options utiles : --hostname, --keymap, --timezone, --lang, --esp-gib, --size-bytes (hors ligne).
"""
import argparse
import json
import subprocess
import sys
import uuid

MIB = 1024 * 1024
SECTOR = {"unit": "B", "value": 512}


def size(value, unit):
    return {"value": int(value), "unit": unit, "sector_size": SECTOR}


def disk_bytes(device):
    out = subprocess.check_output(["lsblk", "-bdno", "SIZE", device], text=True).strip()
    return int(out.splitlines()[0])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--device", default="/dev/nvme0n1", help="disque cible (efface !)")
    p.add_argument("--size-bytes", type=int, help="taille du disque en octets (sinon lue avec lsblk)")
    p.add_argument("--esp-gib", type=int, default=1)
    p.add_argument("--hostname", default="arch")
    p.add_argument("--keymap", default="us")
    p.add_argument("--timezone", default="Europe/Luxembourg")
    p.add_argument("--lang", default="en_US", help="sans le suffixe .UTF-8 (sys_enc le porte)")
    p.add_argument("-o", "--output", default="archinstall/user_configuration.json")
    a = p.parse_args()

    total = a.size_bytes if a.size_bytes else disk_bytes(a.device)
    total_mib = total // MIB
    esp_start_mib = 1
    esp_mib = a.esp_gib * 1024
    root_start_mib = esp_start_mib + esp_mib
    root_mib = total_mib - root_start_mib - 2  # 2 MiB de marge pour la table GPT de fin
    if root_mib < 20 * 1024:
        sys.exit(f"Disque trop petit : {total_mib} MiB")

    config = {
        "archinstall-language": "English",
        "bootloader_config": {"bootloader": "Limine", "uki": False, "removable": False},
        "disk_config": {
            "config_type": "default_layout",
            "btrfs_options": {"snapshot_config": {"type": "Snapper"}},
            "device_modifications": [
                {
                    "device": a.device,
                    "wipe": True,
                    "partitions": [
                        {
                            "obj_id": str(uuid.uuid4()),
                            "status": "create",
                            "type": "primary",
                            "fs_type": "fat32",
                            "flags": ["boot", "esp"],
                            "start": size(esp_start_mib, "MiB"),
                            "size": size(esp_mib, "MiB"),
                            "mountpoint": "/boot",
                            "mount_options": [],
                            "dev_path": None,
                            "btrfs": [],
                        },
                        {
                            "obj_id": str(uuid.uuid4()),
                            "status": "create",
                            "type": "primary",
                            "fs_type": "btrfs",
                            "flags": [],
                            "start": size(root_start_mib, "MiB"),
                            "size": size(root_mib, "MiB"),
                            "mountpoint": None,
                            "mount_options": ["compress=zstd:1", "noatime", "discard=async"],
                            "dev_path": None,
                            "btrfs": [
                                {"name": "@", "mountpoint": "/"},
                                {"name": "@home", "mountpoint": "/home"},
                                {"name": "@log", "mountpoint": "/var/log"},
                                {"name": "@pkg", "mountpoint": "/var/cache/pacman/pkg"},
                                {"name": "@snapshots", "mountpoint": "/.snapshots"},
                            ],
                        },
                    ],
                }
            ],
        },
        "hostname": a.hostname,
        "kernels": ["linux"],
        "locale_config": {"kb_layout": a.keymap, "sys_lang": a.lang, "sys_enc": "UTF-8"},
        "network_config": {"type": "nm"},
        "ntp": True,
        "packages": ["git", "base-devel", "vim", "openssh", "btrfs-progs", "snapper"],
        "parallel_downloads": 10,
        "profile_config": None,
        "services": ["NetworkManager"],
        "swap": False,
        "timezone": a.timezone,
    }
    with open(a.output, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")
    print(f"{a.output} : {a.device} ({total_mib} MiB) -> ESP {esp_mib} MiB + Btrfs {root_mib} MiB", file=sys.stderr)


if __name__ == "__main__":
    main()
