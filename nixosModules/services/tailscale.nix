{
  lib,
  pkgs,
  config,
  secretsPath,
  ...
}:
{
  options.noa.tailscale = {
    ssh.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable tailscale SSH";
    };
    advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Tags to advertise";
    };
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Routes to advertise";
    };
    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise as an exit node";
    };
    pickupRoutes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable subnet routes";
    };
    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags to pass to tailscale up";
    };
  };

  config = {
    sops.secrets.ts_authkey = {
      format = "yaml";
      sopsFile = "${secretsPath}/tailscale.yaml";
      restartUnits = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
    };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.ts_authkey.path;
      extraUpFlags =
        config.noa.tailscale.extraUpFlags
        ++ lib.optionals (config.noa.tailscale.advertiseRoutes != [ ]) [
          "--advertise-routes=${lib.strings.concatStringsSep "," config.noa.tailscale.advertiseRoutes}"
        ]
        ++ lib.optionals (config.noa.tailscale.advertiseTags != [ ]) [
          "--advertise-tags=tag:${lib.strings.concatStringsSep "," config.noa.tailscale.advertiseTags}"
        ]
        ++ lib.optionals config.noa.tailscale.advertiseExitNode [
          "--advertise-exit-node"
        ]
        ++ lib.optionals config.noa.tailscale.ssh.enable [
          "--ssh"
        ]
        ++ lib.optionals config.noa.tailscale.pickupRoutes [
          "--accept-routes"
        ];
      useRoutingFeatures = lib.mkDefault (
        if (config.noa.tailscale.advertiseRoutes != [ ] || config.noa.tailscale.advertiseExitNode) then
          "both"
        else
          "client"
      );
    };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    systemd.services.tailscaled.serviceConfig.Environment =
      lib.optionals config.networking.nftables.enable
        [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;
  };
}
