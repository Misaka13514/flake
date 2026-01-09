{
  pkgs,
  lib,
  ...
}:
{
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernel.sysctl."kernel.sysrq" = 1;
}
