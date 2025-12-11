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
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      inherit wallpaper;
    };

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

      "kscreenlockerrc" = {
        "Greeter/Wallpaper/org.kde.image/General" = {
          "Image" = "file://${wallpaper}";
          "PreviewImage" = "file://${wallpaper}";
        };
      };
    };
  };
}
