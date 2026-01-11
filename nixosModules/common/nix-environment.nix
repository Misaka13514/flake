{
  config,
  pkgs,
  lib,
  overlays,
  system,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      nh
      nix-output-monitor
    ];

    nix = {
      channel.enable = false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = lib.mkIf config.noa.nix.enableMirrorSubstituter [
          "https://mirror.iscas.ac.cn/nix-channels/store"
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://mirrors.ustc.edu.cn/nix-channels/store"
        ];
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos-cuda.org"
          "https://uwu.cachix.org"
          # "https://cache.garnix.io"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "uwu.cachix.org-1:nPTYxZaYsAxaLV6+mJLZXQLPvWzEqIy380vQwBzy1gE="
          # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];

        # hard link identical contents
        auto-optimise-store = true;
      };

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    nixpkgs = {
      hostPlatform = { inherit system; };
      config = {
        allowUnfreePredicate =
          pkg:
          let
            pname = lib.getName pkg;
            nixosAllowed = config.noa.nixpkgs.allowedUnfreePackages;
            homeAllowed =
              if (builtins.hasAttr "home-manager" config) then
                lib.concatLists (
                  lib.mapAttrsToList (
                    _: userConfig: userConfig.noa.nixpkgs.allowedUnfreePackages or [ ]
                  ) config.home-manager.users
                )
              else
                [ ];
          in
          builtins.elem pname (nixosAllowed ++ homeAllowed);
      };
      inherit overlays;
    };

    system.stateVersion = "25.11";
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
    noa.nixpkgs.allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of unfree packages allowed to be installed.";
    };
  };
}
