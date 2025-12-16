# sakanaa: takina-touching NixOS configuration
# CN.PVG Homelab
{
  lib,
  config,
  nixosModules,
  homeModules,
  secretsPath,
  ...
}:
let
  cloudflareSecrets = [
    "cloudflare-api-token"
    "cloudflare-account-id"
    "cloudflare-r2-access-key"
    "cloudflare-r2-secret-key"
  ];
in
{
  imports = with nixosModules; [
    roles.container
    users.atri
    services.caddy
  ];

  sops.secrets = lib.genAttrs cloudflareSecrets (name: {
    format = "yaml";
    sopsFile = "${secretsPath}/cloudflare.yaml";
    key = name;
  });

  sops.templates."caddy-env" = {
    content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}
      CLOUDFLARE_ACCOUNT_ID=${config.sops.placeholder."cloudflare-account-id"}
      CLOUDFLARE_R2_ACCESS_KEY=${config.sops.placeholder."cloudflare-r2-access-key"}
      CLOUDFLARE_R2_SECRET_KEY=${config.sops.placeholder."cloudflare-r2-secret-key"}
    '';
    owner = "caddy";
    restartUnits = [ "caddy.service" ];
  };

  services.caddy = {
    logFormat = ''
      level INFO
    '';
    environmentFile = config.sops.templates."caddy-env".path;
    globalConfig = ''
      admin unix//run/caddy/admin.sock
      dns cloudflare {$CLOUDFLARE_API_TOKEN}
      acme_ca https://acme-v02.api.letsencrypt.org/directory
      auto_https disable_redirects
      storage s3 {
        host       "{$CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
        bucket     "certmagic-s3"
        access_id  "{$CLOUDFLARE_R2_ACCESS_KEY}"
        secret_key "{$CLOUDFLARE_R2_SECRET_KEY}"
      }
    '';
  };

  systemd.services.caddy.serviceConfig = {
    RuntimeDirectory = "caddy";
  };

  noa.nix.enableMirrorSubstituter = true;
}
