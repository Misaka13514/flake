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
  programs.chromium = {
    enable = true;
    package = pkgs.flakePackages.chromium;
    extensions = [
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      { id = "pfnededegaaopdmhkdmcofjmoldfiped"; } # ZeroOmega
    ]
    ++ lib.optionals useKde [
      { id = "cimiefiiaegbelhefglklhhakcgmhkai"; } # Plasma Integration
    ];
  };
}
