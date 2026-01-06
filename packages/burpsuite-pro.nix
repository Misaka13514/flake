{ pkgs, lib }:

let
  loaderJar = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/h3110w0r1d-y/BurpLoaderKeygen/a95136d57f65e814b327142b1f2bdce1bc06bdf9/BurpLoaderKeygen_v1.17.jar";
    hash = "sha256-3N8orPNgVUpamNePQDyWzOpQC+JLJ9ArAg4UKCBjfAo=";
  };
in
(pkgs.burpsuite.override {
  proEdition = true;

  buildFHSEnv =
    args:
    let
      jarMatch = builtins.match ".*-jar ([^ ]+).*" args.runScript;
      burpJarPath =
        if jarMatch != null then
          builtins.head jarMatch
        else
          throw "Failed to extract Burp Jar path from runScript: ${args.runScript}";

      loaderEnv = pkgs.runCommand "burpsuite-loader-env" { } ''
        mkdir -p $out
        cp ${loaderJar} $out/loader.jar
        ln -s "${burpJarPath}" $out/burpsuite_pro.jar
      '';
    in
    pkgs.buildFHSEnv (
      args
      // {
        name = "burpsuite-pro-h3110w0r1d";
        runScript = "${pkgs.jdk}/bin/java -jar ${loaderEnv}/loader.jar";
      }
    );
}).overrideAttrs
  (old: {
    meta = (old.meta or { }) // {
      platforms = lib.platforms.linux;
    };
  })
