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
}
