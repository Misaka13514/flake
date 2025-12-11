{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      esbenp.prettier-vscode
    ];
  };
}
