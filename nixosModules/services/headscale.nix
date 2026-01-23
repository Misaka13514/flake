{
  config,
  nixSecrets,
  ...
}:
let
  domain = "apeiria.net";
in
{
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 40180;
    settings = {
      server_url = "https://${nixSecrets.headscaleDomain}";
      dns = {
        magic_dns = true;
        base_domain = "paths.${domain}";
        override_local_dns = false;
      };
      prefixes.allocation = "random";
      derp.server.enable = false;
    };
  };

  services.nginx.virtualHosts."${nixSecrets.headscaleDomain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/robots.txt".extraConfig = ''
      add_header Content-Type text/plain;
      return 200 "User-agent: *\nDisallow: /";
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
  };
}
