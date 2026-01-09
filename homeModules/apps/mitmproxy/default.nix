{
  config,
  pkgs,
  secretsPath,
  ...
}:

let
  mitmDir = "${config.home.homeDirectory}/.mitmproxy";
  pemFile = "${mitmDir}/mitmproxy-ca.pem";

  derCert = "${mitmDir}/mitmproxy-ca-cert.der";
  derKey = "${mitmDir}/mitmproxy-ca-key.der";

  charlesDir = "${config.home.homeDirectory}/.charles";
  charlesCfg = "${config.home.homeDirectory}/.charles.config";

  charlesConfigContent = ''
    <?xml version='1.0' encoding='UTF-8' ?>
    <?charles serialisation-version='2.0' ?>
    <configuration>
      <proxyConfiguration>
        <port>8080</port>
        <sslLocations>
          <locationPatterns>
            <locationMatch>
              <location>
                <host>*</host>
              </location>
            </locationMatch>
          </locationPatterns>
        </sslLocations>
      </proxyConfiguration>
      <startupConfiguration>
        <checkUpdates>false</checkUpdates>
        <maximised>true</maximised>
        <acceptedEulaVersion>20240608</acceptedEulaVersion>
      </startupConfiguration>
      <userInterfaceConfiguration>
        <promptToSaveSessions>true</promptToSaveSessions>
        <promptToClearSession>true</promptToClearSession>
        <showMemoryUsage>true</showMemoryUsage>
      </userInterfaceConfiguration>
      <registrationConfiguration>
        <name>atri</name>
        <key>C6F84FACE0C9526589</key>
      </registrationConfiguration>
    </configuration>
  '';
  defaultCharlesConfigFile = pkgs.writeText "charles.config.default" charlesConfigContent;
in
{
  home.packages = with pkgs; [
    flakePackages.burpsuite-pro
    charles
    mitmproxy
    openssl
  ];

  sops.secrets."ca" = {
    format = "yaml";
    sopsFile = "${secretsPath}/ca.yaml";
    mode = "0400";
    path = pemFile;
  };

  systemd.user.paths.mitmproxy-ca-watcher = {
    Unit = {
      Description = "Watch mitmproxy CA PEM file for changes";
    };
    Path = {
      PathChanged = pemFile;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.mitmproxy-ca-watcher = {
    Unit = {
      Description = "Convert mitmproxy CA and Init Charles";
    };
    Service = {
      Type = "oneshot";
      ExecStart = toString (
        pkgs.writeShellScript "convert-mitm-pem" ''
          set -e

          if [ ! -f "${charlesCfg}" ]; then
            echo "Initializing Charles Config..."
            install -Dm600 "${defaultCharlesConfigFile}" "${charlesCfg}"
          fi

          if [ ! -f "${pemFile}" ]; then
            echo "Warning: ${pemFile} not found, skipping conversion."
            exit 0
          fi

          echo "Generating DER certificates from PEM..."
          ${pkgs.openssl}/bin/openssl x509 \
            -in "${pemFile}" \
            -outform DER \
            -out "${derCert}"
          ${pkgs.openssl}/bin/openssl pkey \
            -in "${pemFile}" \
            -outform DER \
            -out "${derKey}"

          echo "Generating Charles Keystore..."
          mkdir -p "${charlesDir}/ca"
          rm -f "${charlesDir}/ca/keystore"

          ${pkgs.openssl}/bin/openssl pkcs12 -export \
            -in "${pemFile}" \
            -out "${charlesDir}/ca/keystore" \
            -name "charles" \
            -passout "pass:Q6uKCvhD6AmtSNn7rAGxrN8pv9t93" \
            -legacy

          ${pkgs.openssl}/bin/openssl x509 \
            -in "${pemFile}" \
            -out "${charlesDir}/ca/charles-proxy-ssl-proxying-certificate.pem"
          ${pkgs.openssl}/bin/openssl x509 \
            -in "${pemFile}" \
            -outform DER \
            -out "${charlesDir}/ca/charles-proxy-ssl-proxying-certificate.cer"

          echo "Done."
        ''
      );
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  noa.nixpkgs.allowedUnfreePackages = [
    "burpsuite"
    "charles"
  ];
}
