{
  hostname,
  assetsPath,
  secretsPath,
  config,
  ...
}:
let
  username = "atri";
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

    kscreenlocker = {
      timeout = 15;
      passwordRequiredDelay = 30;
      appearance = {
        inherit wallpaper;
      };
    };

    powerdevil = {
      AC = {
        dimDisplay.enable = true;
        dimDisplay.idleTimeout = 600;
        turnOffDisplay.idleTimeout = 900;
        autoSuspend.action = "sleep";
        autoSuspend.idleTimeout = 1200;
        powerProfile = "performance";
      };
      battery = {
        dimDisplay.enable = true;
        dimDisplay.idleTimeout = 120;
        turnOffDisplay.idleTimeout = 300;
        autoSuspend.action = "sleep";
        autoSuspend.idleTimeout = 600;
        powerProfile = "balanced";
      };
      lowBattery = {
        dimDisplay.enable = true;
        dimDisplay.idleTimeout = 60;
        turnOffDisplay.idleTimeout = 120;
        autoSuspend.action = "sleep";
        autoSuspend.idleTimeout = 300;
        powerProfile = "powerSaving";
      };
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
            kickoff = {
              icon = "${assetsPath}/nix-snowflake-transgender.png";
              compactDisplayStyle = true;
              settings = {
                General = {
                  highlightNewlyInstalledApps = false;
                  switchCategoryOnHover = true;
                };
              };
            };
          }
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:systemsettings.desktop"
                "applications:code.desktop"
                "applications:chromium-browser.desktop"
                "applications:com.ayugram.desktop.desktop"
              ];
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              calendar = {
                firstDayOfWeek = "sunday";
              };
              time = {
                showSeconds = "always";
                format = "24h";
              };
              date = {
                format = "isoDate";
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

      "plasmanotifyrc"."Services/donationmessage" = {
        "ShowInHistory" = false;
        "ShowPopups" = false;
      };

      "kwinrc"."Wayland" = {
        "InputMethod" =
          "/etc/profiles/per-user/${username}/share/applications/fcitx5-wayland-launcher.desktop";
      };

      "kded5rc"."Module-browserintegrationreminder" = {
        "autoload" = false;
      };

      "krdpserverrc"."General" = {
        "Certificate" = config.sops.secrets."cert-01-crt".path;
        "CertificateKey" = config.sops.secrets."cert-01-key".path;
        "SystemUserEnabled" = true;
      };

      "plasmaparc"."General" = {
        "RaiseMaximumVolume" = true;
      };
    };
  };

  sops.secrets."cert-01-key" = {
    format = "yaml";
    sopsFile = "${secretsPath}/ca.yaml";
    mode = "0400";
  };

  sops.secrets."cert-01-crt" = {
    format = "yaml";
    sopsFile = "${secretsPath}/ca.yaml";
    mode = "0444";
  };
}
