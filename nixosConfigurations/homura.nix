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
  singBoxUsers = [
    "user1"
    "user2"
    "user3"
  ];
  singBoxRoutes = [
    "direct"
    "warp"
    "tor"
  ];
  singBoxAccounts = lib.concatMap (
    u:
    map (r: {
      user = u;
      route = r;
      name = "${u}-${r}";
    }) singBoxRoutes
  ) singBoxUsers;

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
    services.tor
    users.atri
  ];

  sops.secrets = lib.mkMerge [
    {
      "cloudflare-api-token" = {
        format = "yaml";
        sopsFile = "${secretsPath}/cloudflare.yaml";
      };
      "sing-box/warp-private-key" = {
        format = "yaml";
        sopsFile = "${secretsPath}/sing-box.yaml";
        restartUnits = [ "sing-box.service" ];
      };
    }
    (lib.listToAttrs (
      map (acc: {
        name = "sing-box/${acc.user}/${acc.route}";
        value = {
          format = "yaml";
          sopsFile = "${secretsPath}/sing-box.yaml";
          restartUnits = [ "sing-box.service" ];
        };
      }) singBoxAccounts
    ))
  ];

  networking.firewall = {
    enable = true;
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
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    commonHttpConfig = ''
      ${realIpsFromList cfipv4}
      ${realIpsFromList cfipv6}
      real_ip_header CF-Connecting-IP;
    '';

    virtualHosts = {
      "_" = {
        default = true;
        rejectSSL = true;
        extraConfig = ''
          return 444;
        '';
      };

      "${nixSecrets.homuraDomain}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/robots.txt" = {
          extraConfig = ''
            add_header Content-Type text/plain;
            return 200 "User-agent: *\nDisallow: /";
          '';
        };
        locations."${nixSecrets.homuraWsPath}" = {
          proxyPass = "http://127.0.0.1:10000";
          proxyWebsockets = true;
        };
      };

      "${nixSecrets.homuraDomainCdn}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/robots.txt" = {
          extraConfig = ''
            add_header Content-Type text/plain;
            return 200 "User-agent: *\nDisallow: /";
          '';
        };
        locations."${nixSecrets.homuraWsPath}" = {
          proxyPass = "http://127.0.0.1:10000";
          proxyWebsockets = true;
        };
      };
    };
  };

  users.users.sing-box.extraGroups = [ "acme" ];
  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
        timestamp = true;
      };

      dns = {
        servers = [
          {
            type = "https";
            tag = "google-doh";
            server = "dns.google";
            domain_resolver = "google-udp";
          }
          {
            type = "udp";
            tag = "google-udp";
            server = "8.8.8.8";
          }
        ];
        strategy = "prefer_ipv6";
      };

      endpoints = [
        {
          type = "wireguard";
          tag = "warp";
          system = false;
          address = [
            "172.16.0.2/32"
            "2606:4700:110:8dbb:718:1dfe:c619:6e73/128"
          ];
          private_key = {
            _secret = config.sops.secrets."sing-box/warp-private-key".path;
          };
          peers = [
            {
              address = "engage.cloudflareclient.com";
              port = 2408;
              public_key = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
              allowed_ips = [
                "0.0.0.0/0"
                "::/0"
              ];
              reserved = "FiCd";
            }
          ];
        }
      ];

      inbounds = [
        {
          type = "vmess";
          tag = "vmess-in";
          listen = "127.0.0.1";
          listen_port = 10000;
          transport = {
            type = "ws";
            path = "${nixSecrets.homuraWsPath}";
          };
          users = map (acc: {
            name = acc.name;
            uuid = {
              _secret = config.sops.secrets."sing-box/${acc.user}/${acc.route}".path;
            };
          }) singBoxAccounts;
        }
        {
          type = "hysteria2";
          tag = "hy2-in";
          listen = "::";
          listen_port = 443;
          tls = {
            enabled = true;
            certificate_path = "/var/lib/acme/${domain}/fullchain.pem";
            key_path = "/var/lib/acme/${domain}/key.pem";
          };
          users = map (acc: {
            name = acc.name;
            password = {
              _secret = config.sops.secrets."sing-box/${acc.user}/${acc.route}".path;
            };
          }) singBoxAccounts;
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "socks";
          tag = "tor";
          server = "127.0.0.1";
          server_port = 9050;
        }
      ];

      route = {
        final = "direct";
        default_domain_resolver = "google-doh";
        rules = [
          { action = "sniff"; }
        ]
        ++ (lib.concatMap
          (targetRoute: [
            (
              {
                auth_user = map (acc: acc.name) (builtins.filter (x: x.route == targetRoute) singBoxAccounts);
                outbound = targetRoute;
              }
              // (lib.optionalAttrs (targetRoute == "tor") { network = [ "tcp" ]; })
            )
          ])
          [
            "warp"
            "tor"
          ]
        );
      };
    };
  };
}
