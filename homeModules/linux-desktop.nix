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
    ./apps/ayugram-desktop
    ./apps/chromium
    ./apps/mitmproxy
    ./apps/vscode
  ]
  ++ lib.optionals useKde [
    ./apps/plasma
  ];

  home.packages = with pkgs; [
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

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        kdePackages.fcitx5-chinese-addons
        kdePackages.fcitx5-configtool
        fcitx5-pinyin-zhwiki
        fcitx5-mozc-ut
      ];
    };
  };
}
