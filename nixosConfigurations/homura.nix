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
    services.sing-box
    services.tor
    users.atri
    users.byn
  ];

  sops.secrets."cloudflare-api-token" = {
    format = "yaml";
    sopsFile = "${secretsPath}/cloudflare.yaml";
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

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = "return 444;";
    };
  };
}
