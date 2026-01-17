# NixOS module to set up an Arch Linux VM for archlinuxcn / AUR package maintenance
{
  pkgs,
  lib,
  config,
  ...
}:

let
  archCloudImage = pkgs.fetchurl {
    name = "arch-linux-cloudimg.qcow2";
    url = "https://geo.mirror.pkgbuild.com/images/v20260115.482142/Arch-Linux-x86_64-cloudimg.qcow2";
    sha256 = "sha256-kYz1wyQZmkNgmPJv+BnMqCDLrejCChJ29BE0yzM77uM=";
  };

  mySshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7DuYiwiKT6VCfWLCE/OTALtgqujaZWWoco9pKmGKGP openpgp:0x88613226";
  vmName = "arch-maintainer";
  sshPort = "10022";

  setupScript = ''
    #!/bin/bash
    set -euo pipefail

    echo "Initializing Pacman keys..."
    pacman-key --init
    pacman-key --populate

    pacman-key --recv-keys 293B93D8A471059F85D716A65BA92099D9BE2DAA
    pacman-key --lsign-key 293B93D8A471059F85D716A65BA92099D9BE2DAA

    if ! grep -q "archlinuxcn" /etc/pacman.conf; then
      echo "Adding archlinuxcn repo..."
      cat >> /etc/pacman.conf <<EOF

    [archlinuxcn]
    Server = https://repo.archlinuxcn.org/\$arch
    EOF
    fi

    cat >> /etc/makepkg.conf <<EOF
    PACKAGER="Misaka13514 <Misaka13514@gmail.com>"
    MAKEFLAGS="-j$(nproc)"
    EOF

    echo "Syncing keyring..."
    pacman -Sy --noconfirm archlinuxcn-keyring

    echo "Setup complete."
  '';

  userDataConfig = {
    hostname = vmName;
    timezone = "Asia/Shanghai";
    locale = "en_US.UTF-8";
    manage_etc_hosts = true;
    ssh_pwauth = false;

    users = [
      {
        name = "arch";
        groups = "wheel";
        sudo = [ "ALL=(ALL) NOPASSWD:ALL" ];
        shell = "/bin/bash";
        lock_passwd = false;
        ssh_authorized_keys = [ mySshKey ];
      }
    ];

    chpasswd = {
      list = "arch:arch";
      expire = false;
    };

    write_files = [
      {
        path = "/etc/ssh/sshd_config.d/99-allow-x11.conf";
        permissions = "0644";
        content = "X11Forwarding yes";
      }
      {
        path = "/etc/ssh/ssh_known_hosts";
        permissions = "0644";
        content = ''
          github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
          aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN
          build.archlinuxcn.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiYTB+9JVjER580kp4YTgldaAG9NgjbL+EFh9LD1LIt
        '';
      }
      {
        path = "/usr/bin/setup-arch-env.sh";
        permissions = "0755";
        content = setupScript;
      }
    ];

    growpart = {
      mode = "auto";
      devices = [ "/" ];
    };

    package_update = true;
    package_upgrade = true;

    packages = [
      "git"
      "bash-completion"
      "qemu-guest-agent"
      "noto-fonts-cjk"
      "base-devel"
      "devtools"
      "git"
      "neovim"
      "ripgrep"
      "xorg-xauth"
    ];

    runcmd = [
      "/usr/bin/setup-arch-env.sh"
      "systemctl restart sshd"
      "systemctl enable --now qemu-guest-agent"
    ];
  };

  userData = pkgs.writeText "arch-user-data" ("#cloud-config\n" + builtins.toJSON userDataConfig);

  metaData = pkgs.writeText "arch-meta-data" ''
    instance-id: ${vmName}-id
    local-hostname: ${vmName}
  '';

  seedIso = pkgs.runCommand "arch-seed-iso" { nativeBuildInputs = [ pkgs.cloud-utils ]; } ''
    cloud-localds $out ${userData} ${metaData}
  '';

  launchScript = pkgs.writeShellScriptBin "deploy-arch-vm" ''
    set -euo pipefail
    export LIBVIRT_DEFAULT_URI="qemu:///session"

    VM_NAME="${vmName}"
    SSH_PORT="${sshPort}"
    STATE_DIR="$HOME/.local/share/libvirt/images"
    DISK_IMG="$STATE_DIR/$VM_NAME.qcow2"
    LOCAL_SEED="$STATE_DIR/$VM_NAME-seed.iso"

    QEMU_IMG="${pkgs.qemu}/bin/qemu-img"
    VIRSH="${pkgs.libvirt}/bin/virsh"
    VIRT_INSTALL="${pkgs.virt-manager}/bin/virt-install"

    mkdir -p "$STATE_DIR"

    if $VIRSH list --all --name | grep -qx "$VM_NAME"; then
      echo "VM '$VM_NAME' already exists."
      if $VIRSH list --name | grep -qx "$VM_NAME"; then
        echo "VM is running."
        echo "Connect via: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT -A -Y arch@localhost"
      else
        echo "VM is stopped. Start it with: virsh start $VM_NAME"
      fi
      exit 0
    fi

    echo "Copying cloud-init ISO..."
    cp -f "${seedIso}" "$LOCAL_SEED"
    chmod 644 "$LOCAL_SEED"

    echo "Initializing VM disk..."
    if [ ! -f "$DISK_IMG" ]; then
      $QEMU_IMG create -f qcow2 -F qcow2 -b "${archCloudImage}" "$DISK_IMG" 40G
    fi

    echo "Defining and starting VM (User Mode)..."
    $VIRT_INSTALL \
      --name "$VM_NAME" \
      --memory 4096 \
      --vcpus 4 \
      --disk path="$DISK_IMG",device=disk,bus=virtio \
      --disk path="$LOCAL_SEED",device=cdrom \
      --os-variant archlinux \
      --graphics spice \
      --noautoconsole \
      --import \
      --channel spicevmc \
      --qemu-commandline="-netdev user,id=net0,hostfwd=tcp::${sshPort}-:22 -device virtio-net-pci,netdev=net0,addr=0x10"

    echo "Deployment started."
    echo "Wait for cloud-init (approx 2-5 mins)..."
    echo "Once ready, connect with:"
    echo "  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT -A -Y arch@localhost"
    echo "To save this state run:"
    echo "  virsh shutdown $VM_NAME"
    echo "  restore-arch-vm --create-base"
  '';

  restoreScript = pkgs.writeShellScriptBin "restore-arch-vm" ''
    set -euo pipefail
    export LIBVIRT_DEFAULT_URI="qemu:///session"

    VM_NAME="${vmName}"
    SNAPSHOT_NAME="base-clean"
    VIRSH="${pkgs.libvirt}/bin/virsh"

    show_help() {
      echo "Usage: $0 [option]"
      echo "  (no args)      : Reset VM to clean state and start it."
      echo "  --create-base  : Create the 'clean' snapshot from current state (VM must be off)."
      echo "  --delete-base  : Delete the snapshot (to allow updating base image)."
    }

    if [ "$#" -eq 0 ]; then
      if ! $VIRSH snapshot-list "$VM_NAME" | grep -q "$SNAPSHOT_NAME"; then
        echo "Error: Snapshot '$SNAPSHOT_NAME' not found!"
        echo "Run '$0 --create-base' after the VM is fully initialized and shut down."
        exit 1
      fi

      echo "Reverting '$VM_NAME' to snapshot '$SNAPSHOT_NAME'..."
      $VIRSH destroy "$VM_NAME" >/dev/null 2>&1 || true
      $VIRSH snapshot-revert "$VM_NAME" "$SNAPSHOT_NAME"

      echo "Starting VM..."
      $VIRSH start "$VM_NAME"
      echo "Done. VM is fresh and booting."
      exit 0

    elif [ "$1" == "--create-base" ]; then
      if $VIRSH list --name | grep -q "$VM_NAME"; then
        echo "Error: VM is running. Please shut it down first to ensure a clean filesystem."
        exit 1
      fi

      if $VIRSH snapshot-list "$VM_NAME" | grep -q "$SNAPSHOT_NAME"; then
        echo "Snapshot already exists. Use --delete-base first if you want to update it."
        exit 1
      fi

      echo "Creating snapshot '$SNAPSHOT_NAME'..."
      $VIRSH snapshot-create-as --domain "$VM_NAME" --name "$SNAPSHOT_NAME" --description "Clean initialized state"
      echo "Snapshot created. You can now use '$0' to reset anytime."
      exit 0

    elif [ "$1" == "--delete-base" ]; then
      echo "Deleting snapshot '$SNAPSHOT_NAME'..."
      $VIRSH snapshot-delete --domain "$VM_NAME" --snapshotname "$SNAPSHOT_NAME"
      echo "Done."
      exit 0
    else
      show_help
    fi
  '';

in
{
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = [
    launchScript
    restoreScript
    pkgs.virt-manager
  ];
}
