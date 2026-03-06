# QEMU x86_64 guest
{
  lib,
  modulesPath,
  ...
}:
{
  hardware.facter.reportPath = ./midori.json;
}
