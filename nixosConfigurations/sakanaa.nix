# sakanaa: takina-touching NixOS configuration
# CN.PVG Homelab
{
  lib,
  pkgs,
  config,
  nixosModules,
  homeModules,
  secretsPath,
  nixSecrets,
  ...
}:
let
  domain = nixSecrets.homeDomain;
  openwrtHost = "root@immortalwrt.${domain}";
  openwrtPort = "2201";
  pveHost = "root@pve.${domain}";
  pvePort = "2250";
  nasHost = "root@dsm.${domain}";
  nasPort = "2251";

  sshKeyPath = config.sops.secrets."acme-deploy-key".path;
  sshOpts = "-i ${sshKeyPath} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";

  deployCertsScript = pkgs.writeShellScript "deploy-certs" ''
    export PATH=$PATH:${lib.makeBinPath [ pkgs.openssh ]}

    if [ ! -f "${sshKeyPath}" ]; then
      echo "Error: SSH Key not found at ${sshKeyPath}"
      exit 1
    fi

    deploy_to() {
      local host=$1
      local port=$2
      local name=$3
      shift 3
      local cmds=("$@")

      echo "Deploying to $name ($host:$port)..."

      (
        set -e
        "''${cmds[@]}"
      )

      if [ $? -eq 0 ]; then
        echo "✅ Success: $name"
      else
        echo "⚠️ WARNING: Failed to deploy to $name. Continuing..."
      fi
    }

    echo "--- Starting Deploy ---"

    deploy_to "${openwrtHost}" "${openwrtPort}" "OpenWrt" \
      bash -c "
        scp -P ${openwrtPort} ${sshOpts} -q fullchain.pem ${openwrtHost}:/etc/uhttpd.crt && \
        scp -P ${openwrtPort} ${sshOpts} -q key.pem       ${openwrtHost}:/etc/uhttpd.key && \
        ssh -p ${openwrtPort} ${sshOpts} ${openwrtHost} '/etc/init.d/uhttpd reload'
      "

    deploy_to "${pveHost}" "${pvePort}" "PVE" \
      bash -c "
        scp -P ${pvePort} ${sshOpts} -q fullchain.pem ${pveHost}:/etc/pve/local/pveproxy-ssl.pem && \
        scp -P ${pvePort} ${sshOpts} -q key.pem       ${pveHost}:/etc/pve/local/pveproxy-ssl.key && \
        ssh -p ${pvePort} ${sshOpts} ${pveHost} 'systemctl reload pveproxy'
      "

    SYNO_DIR="/usr/syno/etc/certificate/system/default"
    deploy_to "${nasHost}" "${nasPort}" "Synology" \
      bash -c "
        echo 'Uploading to Synology /tmp...'
        cat fullchain.pem | ssh -p ${nasPort} ${sshOpts} ${nasHost} \"cat > /tmp/acme.crt\" && \
        cat key.pem       | ssh -p ${nasPort} ${sshOpts} ${nasHost} \"cat > /tmp/acme.key\" && \

        echo 'Applying on Synology...'
        ssh -p ${nasPort} ${sshOpts} ${nasHost} '
          set -e
          DEFAULT_ID=\$(cat /usr/syno/etc/certificate/_archive/DEFAULT)
          TARGET_DIR=\"/usr/syno/etc/certificate/_archive/\$DEFAULT_ID\"

          echo \"Target Certificate Dir: \$TARGET_DIR\"

          cp /tmp/acme.crt \"\$TARGET_DIR/fullchain.pem\"
          cp /tmp/acme.crt \"\$TARGET_DIR/cert.pem\"
          cp /tmp/acme.key \"\$TARGET_DIR/privkey.pem\"

          rm /tmp/acme.crt /tmp/acme.key

          echo \"Running synow3tool...\"
          /usr/syno/bin/synow3tool --gen-all

          echo \"Restarting Nginx...\"
          /usr/syno/bin/synosystemctl restart nginx
        '
      "

    echo "--- Deployment Finished ---"
  '';
in
{
  imports = with nixosModules; [
    roles.container
    users.atri
  ];

  sops.secrets."acme-deploy-key" = {
    format = "yaml";
    sopsFile = "${secretsPath}/home-acme-deploy.yaml";
  };

  sops.secrets."cloudflare-api-token" = {
    format = "yaml";
    sopsFile = "${secretsPath}/cloudflare.yaml";
  };

  sops.templates."acme-credentials" = {
    content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@apeiria.net";
    certs = {
      "${domain}" = {
        extraDomainNames = [ "*.${domain}" ];
        dnsProvider = "cloudflare";
        extraLegoFlags = [
          "--dns.propagation-wait"
          "20s"
        ]; # poor CN DNS
        environmentFile = config.sops.templates."acme-credentials".path;
        postRun = ''
          ${deployCertsScript}
        '';
      };
    };
  };

  noa.nix.enableMirrorSubstituter = true;
}
