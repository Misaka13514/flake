{
  lib,
  config,
  pkgs,
  ...
}:
let
  extraPackages = with pkgs; [
    fastfetch
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

  # Replace command-not-found with nix-index and comma
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
