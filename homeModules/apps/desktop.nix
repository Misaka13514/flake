{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  useKde = osConfig.services.desktopManager.plasma6.enable;
in
{
  imports = [
    ./ayugram-desktop
    ./chromium
    ./vscode
  ]
  ++ lib.optionals useKde [
    ./plasma
  ];

  home.packages = with pkgs; [
    flakePackages.burpsuite-pro
    flakePackages.ida-pro
    gimp
    hmcl
    libreoffice-qt-fresh
    mission-center
    mpv
    obsidian
    remmina
    rustdesk-flutter
    telegram-desktop
    vlc
    yubioath-flutter
  ];

  home.sessionVariables = {
    "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
    "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
    "MOZ_WEBRENDER" = "1";
    # enable native Wayland support for most Electron apps
    "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
    # misc
    "_JAVA_AWT_WM_NONREPARENTING" = "1";
    "GDK_SCALE" = "2"; # Java HiDPI scaling
    "QT_WAYLAND_DISABLE_WINDOWDECORATION" = "1";
    "QT_QPA_PLATFORM" = "wayland";
    "SDL_VIDEODRIVER" = "wayland";
    "GDK_BACKEND" = "wayland";
    "XDG_SESSION_TYPE" = "wayland";
  };
}
