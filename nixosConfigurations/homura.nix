# homura: Magical NixOS configuration
# US.SFO DC3
{
  lib,
  pkgs,
  config,
  nixosModules,
  secretsPath,
  nixSecrets,
  ...
}:
let
  domain = "apeiria.net";
  davPath = "/mnt/cloud";
  realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
  cfipv4 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v4";
      sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
    }
  );
  cfipv6 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v6";
      sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
    }
  );

in
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat
    services.docker
    services.endlessh
    services.headscale
    services.maubot
    services.rclone
    services.sing-box
    services.tor
    users.atri
    users.byn
  ];

  sops.secrets."cloudflare-api-token" = {
    format = "yaml";
    sopsFile = "${secretsPath}/cloudflare.yaml";
  };

  sops.secrets."rclone-conf" = {
    format = "yaml";
    sopsFile = "${secretsPath}/rclone.yaml";
  };

  sops.secrets."webdav-htpasswd" = {
    format = "yaml";
    sopsFile = "${secretsPath}/rclone.yaml";
    owner = "nginx";
  };

  noa.rclone = {
    enable = true;
    mountPoint = davPath;
    rcloneRemote = "crypt:";
    rcloneConfigPath = config.sops.secrets."rclone-conf".path;
    allowUsers = true;
    extraArgs = [
      "uid=${toString config.users.users.nginx.uid}"
      "gid=${toString config.users.groups.nginx.gid}"
      "umask=007"
      "default_permissions"
    ];
    consistencyCheck = {
      enable = true;
      sourceRemote = "gdrive:cloud";
      targetRemote = "onedrive:cloud";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ];
  };

  services.openssh = {
    ports = [ 50721 ];
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
        ];
        reloadServices = [
          "nginx"
          "sing-box"
        ];
        credentialFiles = {
          "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare-api-token".path;
        };
      };
    };
  };

  services.tor = {
    settings = {
      EntryNodes = "{us}";
      ExitNodes = "{us}";
      StrictNodes = true;
      CircuitBuildTimeout = 5;
      KeepalivePeriod = 60;
      MaxCircuitDirtiness = 7200;
      NewCircuitPeriod = 120;
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];
  systemd.services.nginx.unitConfig.RequiresMountsFor = [ davPath ];
  systemd.services.nginx.serviceConfig.ReadWritePaths = [ davPath ];
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline.override {
      modules = [
        pkgs.nginxModules.dav
        pkgs.nginxModules.fancyindex
        pkgs.nginxModules.moreheaders
      ];
    };
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    appendHttpConfig = ''
      dav_ext_lock_zone zone=dav_lock:10m;
    '';

    commonHttpConfig = ''
      ${realIpsFromList cfipv4}
      ${realIpsFromList cfipv6}
      real_ip_header CF-Connecting-IP;
    '';

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = "return 444;";
    };

    virtualHosts."${nixSecrets.webdavDomain}" = {
      serverAliases = [ nixSecrets.webdavDomainCdn ];
      useACMEHost = domain;
      forceSSL = true;
      basicAuthFile = config.sops.secrets."webdav-htpasswd".path;
      locations."/robots.txt".extraConfig = ''
        add_header Content-Type text/plain;
        return 200 "User-agent: *\nDisallow: /";
      '';
      locations."~* ^/(?:\\._|\\.DS_Store|Thumbs\\.db|desktop\\.ini)" = {
        extraConfig = ''
          access_log off;
          log_not_found off;

          if ($request_method ~ ^(PUT|MKCOL)$) {
            return 204;
          }

          return 404;
        '';
      };
      locations."/" = {
        root = davPath;
        # ref: http://netlab.dhis.org/wiki/ru:software:nginx:webdav
        extraConfig = ''
          fancyindex on;
          fancyindex_exact_size off;
          fancyindex_localtime on;

          create_full_put_path off;
          client_max_body_size 0;
          client_body_timeout 3600s;
          send_timeout 3600s;

          if ($request_method = PROPPATCH) {
            add_header Content-Type 'text/xml';
            return 207 '<?xml version="1.0"?><a:multistatus xmlns:a="DAV:"><a:response><a:propstat><a:status>HTTP/1.1 200 OK</a:status></a:propstat></a:response></a:multistatus>';
          }

          if ($request_method = MKCOL) {
            rewrite ^(.*[^/])$ $1/ break;
          }

          if (-d $request_filename) {
            more_set_input_headers 'Destination: $http_destination/';
            rewrite ^(.*[^/])$ $1/ break;
          }

          if ($request_method = OPTIONS) {
            add_header DAV '1, 2';
          }

          dav_access user:rw group:rw;
          dav_methods PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
          dav_ext_lock zone=dav_lock;
        '';
      };
    };
  };
}
