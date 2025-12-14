{ pkgs, ... }:
{
  home.packages = with pkgs; [
    flakePackages.ida-pro
  ];
}
