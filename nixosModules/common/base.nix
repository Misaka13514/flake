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
  ];

  networking.hostName = lib.mkDefault hostname;
}
