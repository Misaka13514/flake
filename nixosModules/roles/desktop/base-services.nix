{ pkgs, lib, ... }:

{
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl."kernel.sysrq" = 1;

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

}
