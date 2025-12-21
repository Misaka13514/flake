{
  pkgs,
  lib,
  tdesktopApiId ? null,
  tdesktopApiHash ? null,
}:

let
  ayugram = pkgs.ayugram-desktop;

  customAyugram = ayugram.override {
    telegram-desktop = pkgs.telegram-desktop.override {
      unwrapped = pkgs.telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          (lib.cmakeFeature "TDESKTOP_API_ID" (toString tdesktopApiId))
          (lib.cmakeFeature "TDESKTOP_API_HASH" (toString tdesktopApiHash))
        ];
      });
    };
  };
in

if tdesktopApiId != null && tdesktopApiHash != null then customAyugram else ayugram
