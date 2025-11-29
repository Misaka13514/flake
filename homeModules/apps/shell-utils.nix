{
  lib,
  config,
  pkgs,
  ...
}:
let
  extraPackages = with pkgs; [
    fastfetch
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.git = {
    enable = true;
    settings = {
      user.name = "Misaka13514";
      user.email = "Misaka13514@gmail.com";
      init.defaultBranch = "main";
      commit.gpgsign = true;
    };
  };

  programs.fish = {
    enable = true;
  };
}
