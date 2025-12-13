{ pkgs, ... }:
{
  home.packages = with pkgs; [
    flakePackages.burpsuite-pro
  ];
}
