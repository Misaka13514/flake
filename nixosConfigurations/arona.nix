# arona: NixOS in the Shittim Chest
{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.desktop
    gui.suites.plasma
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
