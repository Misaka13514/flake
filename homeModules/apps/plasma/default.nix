{
  pkgs,
  lib,
  hostname,
  assetsPath,
  ...
}:
let
  wallpaper =
    if hostname == "Index" then
      "${assetsPath}/wallpapers/114305978_p1.png"
    else
      "${assetsPath}/wallpapers/114305978_p0.png";
  myTouchpads = [
    "UNIW0001:00 093A:0255 Touchpad"
    "SYNP1F13:00 06CB:CD95 Touchpad"
  ];
  extractIds =
    name:
    let
      matches = builtins.match ".* ([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4}) .*" name;
    in
    if matches != null then
      {
        vendorId = builtins.elemAt matches 0;
        productId = builtins.elemAt matches 1;
      }
    else
      { };
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      inherit wallpaper;
    };

    input.touchpads = map (
      name:
      let
        ids = extractIds name;
      in
      {
        inherit name;
        inherit (ids) vendorId productId;
        naturalScroll = true;
      }
    ) myTouchpads;

    panels = [
      {
        location = "bottom";
        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config = {
              General = {
                icon = "${assetsPath}/nix-snowflake-transgender.png";
              };
            };
          }
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:systemsettings.desktop"
                  "applications:code.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:org.telegram.desktop.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            name = "org.kde.plasma.digitalclock";
            config = {
              Appearance = {
                showSeconds = "Always";
                use24hFormat = true;
                dateFormat = "isoDate";
              };
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    configFile = {
      "kdeglobals"."KDE" = {
        AutomaticLookAndFeel = true;
      };

      "knighttimerc"."Location" = {
        Automatic = false;
        Latitude = "31.242";
        Longitude = "121.495";
      };

      "kscreenlockerrc"."Greeter/Wallpaper/org.kde.image/General" = {
        "Image" = "file://${wallpaper}";
        "PreviewImage" = "file://${wallpaper}";
      };

      "plasmanotifyrc"."Services/donationmessage" = {
        "ShowInHistory" = false;
        "ShowPopups" = false;
      };

      "kwinrc"."Wayland" = {
        "InputMethod" = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
      };

      "kded5rc"."Module-browserintegrationreminder" = {
        "autoload" = false;
      };
    };
  };
}
