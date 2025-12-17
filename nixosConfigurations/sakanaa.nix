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
  deployCerts = pkgs.callPackage ../lib/home-deploy-certs.nix {
    inherit domain;
    sshKeyPath = config.sops.secrets."acme-deploy-key".path;
  };
in
{
  imports = with nixosModules; [
    roles.container
    users.atri
  ];

  environment.systemPackages = [ deployCerts ];

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
          ${deployCerts}/bin/deploy-certs
        '';
      };
    };
  };

  noa.nix.enableMirrorSubstituter = true;
}
