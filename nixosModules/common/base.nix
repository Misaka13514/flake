{
  pkgs,
  lib,
  hostname,
  nixSecrets,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
  ];

  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = nixSecrets.authorizedKeys;
  };

  networking.hostName = lib.mkDefault hostname;
  networking.firewall.enable = true;
  networking.nftables.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
  };

  programs.git.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
