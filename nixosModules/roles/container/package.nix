_: {
  # No need for fonts and documentation on a server
  documentation.enable = false;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  users.mutableUsers = false;

  networking.firewall.enable = true;
  networking.nftables.enable = true;
}
