{ pkgs, ... }:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.2"
        "github.com/caddy-dns/powerdns@v1.0.2"
        "github.com/mholt/caddy-l4@v0.0.0-20251209130418-1a3490ef786a"
        "github.com/mholt/caddy-webdav@v0.0.0-20250805175825-7a5c90d8bf90"
        "github.com/ss098/certmagic-s3@v0.0.0-20250922022452-8af482af5f39"
      ];
      hash = "sha256-G7K1B0bcIURBsWETUOrrrF9kxMxrlZleQ/Ey9O+TWLQ=";
    };
  };
}
