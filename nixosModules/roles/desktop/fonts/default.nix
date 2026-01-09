{
  pkgs,
  lib,
  ...
}:
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

      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    enableGhostscriptFonts = true;
    enableDefaultPackages = true;

    fontconfig.defaultFonts = {
      serif = lib.mkAfter [
        "Noto Serif CJK SC"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      sansSerif = lib.mkAfter [
        "Noto Sans CJK SC"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      monospace = lib.mkAfter [
        "Noto Sans Mono CJK SC"
        "Symbols Nerd Font Mono"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
