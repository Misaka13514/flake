{
  pkgs,
  unstablePkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Language servers
    nixd
    nixfmt-rfc-style
    sops
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };
}
