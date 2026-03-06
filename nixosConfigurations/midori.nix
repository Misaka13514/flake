# midori: NixOS of Fresh Inspiration
{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.desktop
    diskLayouts.single-disk-ext4
    gui.suites.plasma
    services.podman
    services.mdns
    services.printing
    services.tailscale
    hardware.bluetooth
    users.atri
  ];

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager = {
      enable = true;
      modules = with homeModules; [
        linux-desktop
        apps.shell-utils
        apps.development
      ];
    };
  };
}
