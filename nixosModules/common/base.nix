{
  pkgs,
  lib,
  hostname,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
  ];

  networking.hostName = lib.mkDefault hostname;
}
