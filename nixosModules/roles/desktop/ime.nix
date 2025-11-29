{ config, pkgs, ... }:

{
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
