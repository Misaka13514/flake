# sakanaa: takina-touching NixOS configuration
# CN.PVG Homelab
{
  pkgs,
  config,
  nixosModules,
  secretsPath,
  nixSecrets,
  ...
}:
let
  domain = nixSecrets.homeDomain;
  deployCerts = pkgs.callPackage ../lib/home-deploy-certs.nix {
    inherit domain;
    sshKeyPath = config.sops.secrets."acme-deploy-key".path;
  };
in
{
  imports = with nixosModules; [
    roles.container
    services.docker
    users.atri
  ];

  environment.systemPackages = [ deployCerts ];

  sops.secrets."acme-deploy-key" = {
    format = "yaml";
    sopsFile = "${secretsPath}/home-acme-deploy.yaml";
    owner = "acme";
  };

  sops.secrets."cloudflare-api-token" = {
    format = "yaml";
    sopsFile = "${secretsPath}/cloudflare.yaml";
  };

  sops.secrets."syncplay-salt" = {
    format = "yaml";
    sopsFile = "${secretsPath}/home-syncplay.yaml";
  };

  sops.secrets."syncplay-motd" = {
    format = "yaml";
    sopsFile = "${secretsPath}/home-syncplay.yaml";
    mode = "0444";
  };

  services.openssh = {
    ports = [ 2252 ];
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
        credentialFiles = {
          "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare-api-token".path;
        };
        postRun = ''
          ${deployCerts}/bin/deploy-certs
        '';
      };
    };
  };

  services.syncplay = {
    enable = true;
    useACMEHost = domain;
    saltFile = config.sops.secrets."syncplay-salt".path;
    motdFile = config.sops.secrets."syncplay-motd".path;
    roomsDBFile = "rooms.db";
    statsDBFile = "stats.db";
  };

  noa.nix.enableMirrorSubstituter = true;
}
