# sakanaa: takina-touching NixOS configuration
# CN.PVG Homelab
{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.container
    users.atri
    services.caddy
  ];

  noa.nix.enableMirrorSubstituter = true;
}
