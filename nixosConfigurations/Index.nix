# Index: A Certain Magical NixOS Configuration
{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.desktop
    gui.suites.plasma
    gui.obs-studio
    gui.steam
    gui.wireshark
    services.docker
    services.vscode-server
    hardware.bluetooth
    users.atri
  ];

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager = {
      enable = true;
      modules = with homeModules; [
        apps.desktop
        apps.shell-utils
        apps.development
      ];
    };
  };
}
