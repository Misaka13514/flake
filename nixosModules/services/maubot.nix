{ config, ... }:
let
  domain = "apeiria.net";
in
{
  virtualisation.oci-containers.containers.maubot = {
    image = "dock.mau.dev/maubot/maubot:v0.6.0@sha256:6968ddea1e08aa7f8ac70ac7a706663fe8d7b4d6f96cd7a6bb8548637fb8cd17";
    ports = [ "127.0.0.1:29316:29316" ];
    volumes = [ "/var/lib/maubot:/data" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/maubot 0700 1337 1337 -"
  ];

  services.nginx.virtualHosts."maubot.${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:29316";
      proxyWebsockets = true;
    };
  };
}
