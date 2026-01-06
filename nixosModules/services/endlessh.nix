{
  pkgs,
  config,
  secretsPath,
  ...
}:
let
  # Scripts modified from https://github.com/elhenro/endlessh-auto-report-abuseipdb (MIT License)
  cacheScript = pkgs.writeShellScriptBin "cache.sh" ''
    DIR="."
    mkdir -p "''${DIR}"
    EXPIRY=900 # default to 15 minutes
    [ "$1" -eq "$1" ] 2>/dev/null && EXPIRY=$1 && shift
    CMD="$@"
    HASH=$(echo "$CMD" | ${pkgs.coreutils}/bin/md5sum | ${pkgs.gawk}/bin/awk '{print $1}')
    CACHE="$DIR/$HASH"

    if test -f "''${CACHE}" && [ $(expr $(date +%s) - $(date -r "''${CACHE}" +%s)) -le $EXPIRY ]; then
      echo 'true'
    else
      echo 'false'
    fi
  '';

  reportScript = pkgs.writeShellScriptBin "report.sh" ''
    APIKEY=$(cat "$CREDENTIALS_DIRECTORY/abuseipdb_api_key")

    while IFS= read -r message; do
      IP=$(echo ''${message} | ${pkgs.gnugrep}/bin/grep -o -P '(?<=host=)[0-9a-fA-F:.]+(?= port)')

      if [ -z "''${IP}" ]; then
        continue
      fi

      HASH=$(echo "echo $IP" | ${pkgs.coreutils}/bin/md5sum | ${pkgs.gawk}/bin/awk '{print $1}')
      LOCK_FILE="./$HASH.lock"

      (
        ${pkgs.util-linux}/bin/flock -n 200 || exit 0

        echo "Processing IP: ''${IP}"

        if [[ $(${cacheScript}/bin/cache.sh 900 "echo $IP") = 'true' ]]; then
          echo "IP ''${IP} is still cached, skipping report."
        else
          comment="SSH tarpit connection (endlessh): ''${message}"
          echo "Reporting ''${IP} to AbuseIPDB with comment: ''${comment}"

          API_RESPONSE=$(${pkgs.curl}/bin/curl -s https://api.abuseipdb.com/api/v2/report \
            --data-urlencode "ip=''${IP}" \
            -d categories=18,22 \
            --data-urlencode "comment=''${comment}" \
            -H "Key: ''${APIKEY}" \
            -H "Accept: application/json")

          if echo "''${API_RESPONSE}" | ${pkgs.jq}/bin/jq -e '.errors' > /dev/null; then
            ERROR_DETAIL=$(echo "''${API_RESPONSE}" | ${pkgs.jq}/bin/jq -r '.errors[0].detail')
            echo "API Error for ''${IP}: ''${ERROR_DETAIL}"
          elif echo "''${API_RESPONSE}" | ${pkgs.jq}/bin/jq -e '.status == 429' > /dev/null; then
            ERROR_DETAIL=$(echo "''${API_RESPONSE}" | ${pkgs.jq}/bin/jq -r '.detail')
            echo "Rate limit for ''${IP}: ''${ERROR_DETAIL}"
          else
            REPORT_INFO=$(echo "''${API_RESPONSE}" | ${pkgs.jq}/bin/jq -r '.data | "Report for \(.ipAddress) successful. Abuse score: \(.abuseConfidenceScore)%"')
            echo "''${REPORT_INFO}"
          fi

          touch "./$HASH"
          echo "''${IP}" >> ./reportedIps.txt
        fi
      ) 200>>"''${LOCK_FILE}"
    done
  '';

  startScript = pkgs.writeShellScript "start-reporter.sh" ''
    set -euo pipefail
    ${pkgs.systemd}/bin/journalctl -u endlessh.service -f -n 0 -q -o cat --grep 'ACCEPT' \
      | ${reportScript}/bin/report.sh
  '';
in
{
  sops.secrets."abuseipdb-api-key" = {
    format = "yaml";
    sopsFile = "${secretsPath}/abuseipdb.yaml";
    mode = "0400";
    owner = "endlessh-reporter";
    restartUnits = [ "endlessh-reporter.service" ];
  };

  services.endlessh = {
    enable = true;
    port = 22;
    openFirewall = true;
    extraOptions = [ "-v" ];
  };

  users.users.endlessh-reporter = {
    isSystemUser = true;
    group = "endlessh-reporter";
    extraGroups = [ "systemd-journal" ];
  };
  users.groups.endlessh-reporter = { };

  systemd.services.endlessh-reporter = {
    description = "Endlessh AbuseIPDB Reporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "endlessh.service" ];

    serviceConfig = {
      User = "endlessh-reporter";
      Group = "endlessh-reporter";
      LoadCredential = "abuseipdb_api_key:${config.sops.secrets."abuseipdb-api-key".path}";
      ExecStart = "${startScript}";
      StateDirectory = "endlessh-reporter";
      WorkingDirectory = "/var/lib/endlessh-reporter";
      Restart = "always";
      RestartSec = "10s";

      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      MemoryDenyWriteExecute = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      RestrictRealtime = true;

      PrivateTmp = true;
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateDevices = true;
      UMask = "0077";

      PrivateUsers = true;

      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;

      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      SystemCallFilter = [
        "@system-service"
        "@network-io"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/endlessh-reporter 0755 endlessh-reporter endlessh-reporter 30d"
  ];
}
