{
  pkgs,
  lib,
  tdesktopApiId ? null,
  tdesktopApiHash ? null,
}:
pkgs.ayugram-desktop.override {
  telegram-desktop = pkgs.telegram-desktop.override {
    unwrapped = pkgs.telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
      cmakeFlags =
        (oldAttrs.cmakeFlags or [ ])
        ++ lib.optionals (tdesktopApiId != null && tdesktopApiHash != null) [
          (lib.cmakeFeature "TDESKTOP_API_ID" (toString tdesktopApiId))
          (lib.cmakeFeature "TDESKTOP_API_HASH" (toString tdesktopApiHash))
        ];
    });
  };
}
