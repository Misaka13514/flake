{
  pkgs,
  lib,
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
in
{
  sops.secrets."cert-01-key" = {
    format = "yaml";
    sopsFile = "${secretsPath}/ca.yaml";
    mode = "0400";
    owner = "xrdp";
  };

  sops.secrets."cert-01-crt" = {
    format = "yaml";
    sopsFile = "${secretsPath}/ca.yaml";
    mode = "0444";
    owner = "xrdp";
  };

  services = {
    xserver.enable = true; # optional

    xrdp = {
      enable = true;
      defaultWindowManager = "startplasma-x11";
      openFirewall = true;
      sslCert = config.sops.secrets."cert-01-crt".path;
      sslKey = config.sops.secrets."cert-01-key".path;
    };

    displayManager = {
      sddm = {
        enable = true;
        theme = "breeze";
        wayland.enable = true;
      };
    };
    desktopManager.plasma6.enable = true;
  };

  programs.kdeconnect.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=${wallpaper}
    '')
  ];

  system.activationScripts.script.text = ''
    install -dm755 /var/lib/AccountsService/icons
    install -Dm644 ${assetsPath}/vanilla.png /var/lib/AccountsService/icons/${username}
  '';
}
