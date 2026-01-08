{
  pkgs,
  unstablePkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Language servers
    nixd
    nixfmt
    sops
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };
}
