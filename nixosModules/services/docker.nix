{
  config,
  lib,
  ...
}:
{
  options.noa.docker = {
    enableWatchTower = lib.mkEnableOption "Watchtower auto update";
    useRegistryMirror = lib.mkEnableOption "Registry mirror";
  };

  config = {
    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        # ================= IP Address Management (IPAM) Strategy =================
        # To prevent routing table conflicts with existing overlay networks,
        # the following ranges MUST BE AVOIDED:
        # - 10.0.0.0/8      -> Reserved for NeoNetwork.
        # - 100.64.0.0/10   -> Reserved for Tailscale/Headscale (CGNAT).
        # - 172.20.0.0/14   -> Reserved for DN42.
        # - 192.168.0.0/16  -> Avoided to prevent collision with local Wi-Fi/LAN.
        # =========================================================================

        # Default Bridge (docker0)
        # Sized to /24 (254 IPs). Sufficient for standalone 'docker run' containers.
        "bip" = "172.26.0.1/24";

        # Dynamic Network Pools (used by Docker Compose)
        # Base: 172.26.16.0/20 covers 172.26.16.0 to 172.26.31.255 (4096 IPs).
        # Size: 27 means each Compose project gets a /27 subnet (32 IPs).
        # Capacity: This allows for exactly 128 distinct Docker Compose networks.
        "default-address-pools" = [
          {
            "base" = "172.26.16.0/20";
            "size" = 27;
          }
        ];

        "registry-mirrors" = lib.mkIf config.noa.docker.useRegistryMirror [
          "https://docker.1ms.run"
        ];
      };
    };
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.watch-tower = lib.mkIf config.noa.docker.enableWatchTower {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
