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
    package = pkgs.symlinkJoin {
      name = "chromium";
      paths = [ pkgs.chromium ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/chromium \
          --set GOOGLE_DEFAULT_CLIENT_ID 77185425430.apps.googleusercontent.com \
          --set GOOGLE_DEFAULT_CLIENT_SECRET OTJgUOQcT7lO7GsGZq2G4IlT
      '';
    };
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
