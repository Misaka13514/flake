{
  pkgs,
  clientId ? "77185425430.apps.googleusercontent.com",
  clientSecret ? "OTJgUOQcT7lO7GsGZq2G4IlT",
}:
pkgs.symlinkJoin {
  inherit (pkgs.chromium) pname version meta;
  paths = [ pkgs.chromium ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/chromium \
      --set GOOGLE_DEFAULT_CLIENT_ID ${clientId} \
      --set GOOGLE_DEFAULT_CLIENT_SECRET ${clientSecret}
  '';
}
