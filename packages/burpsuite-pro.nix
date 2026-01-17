{
  pkgs,
  lib,
}:
let
  loaderJar = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/h3110w0r1d-y/BurpLoaderKeygen/0000118000aca6b2ebe9fdd8b7e9696dde3b7664/BurpLoaderKeygen_v1.18.jar";
    hash = "sha256-2WnidmXz09wJzPp4jvVe1yeBgTbUiTfsa/CDY4y9dLI=";
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

      loaderEnv =
        pkgs.runCommand "burpsuite-loader-env"
          {
            srcDependency = args.runScript;
          }
          ''
            mkdir -p $out
            cp ${loaderJar} $out/loader.jar
            cp "${burpJarPath}" $out/burpsuite_pro.jar
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
