{
  lib,
  pkgs,
  config,
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

in
{
  sops.secrets = lib.mkMerge [
    {
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
            inherit (acc) name;
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
            inherit (acc) name;
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

  services.nginx.virtualHosts."${nixSecrets.homuraDomain}" = {
    serverAliases = [
      nixSecrets.homuraDomainCdn
      nixSecrets.homuraDomainHack
    ];
    useACMEHost = domain;
    forceSSL = true;
    locations."/robots.txt".extraConfig = ''
      add_header Content-Type text/plain;
      return 200 "User-agent: *\nDisallow: /";
    '';
    locations."${nixSecrets.homuraWsPath}" = {
      proxyPass = "http://127.0.0.1:10000";
      proxyWebsockets = true;
    };
  };
}
