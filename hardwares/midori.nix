# QEMU x86_64 guest
{
  lib,
  modulesPath,
  ...
}:
{
  hardware.facter.reportPath = ./midori.json;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200n8"
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/pve-igpu"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:01.0", SYMLINK+="dri/pve-virtgpu"
  '';

  environment.sessionVariables = {
    KWIN_DRM_DEVICES = "/dev/dri/pve-igpu:/dev/dri/pve-virtgpu";
  };
}
