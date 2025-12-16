# sakanaa: takina-touching NixOS configuration
# CN.PVG Homelab
{
  lib,
  config,
  nixosModules,
  homeModules,
  secretsPath,
  nixSecrets,
  ...
}:
let
  domain = nixSecrets.homeDomain;
in
{
  imports = with nixosModules; [
    roles.container
    users.atri
  ];

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
        dnsPropagationCheck = false; # poor CN DNS
        environmentFile = config.sops.templates."acme-credentials".path;
      };
    };
  };

  noa.nix.enableMirrorSubstituter = true;
}
