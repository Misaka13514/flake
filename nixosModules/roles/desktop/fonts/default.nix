{ pkgs, lib, ... }:
{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
    ];

    enableGhostscriptFonts = true;
    enableDefaultPackages = true;

    fontconfig.defaultFonts = {
      serif = lib.mkAfter [
        "Noto Serif CJK SC"
      ];
      sansSerif = lib.mkAfter [
        "Noto Sans CJK SC"
      ];
      monospace = lib.mkAfter [
        "Noto Sans Mono CJK SC"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
