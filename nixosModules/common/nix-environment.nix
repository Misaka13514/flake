{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  config = {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = lib.mkIf config.noa.nix.enableMirrorSubstituter [
          "https://mirror.iscas.ac.cn/nix-channels/store"
        ];
        # extra-substituters = [
        #   "https://nix-community.cachix.org"
        #   "https://cache.garnix.io"
        # ];
        # trusted-public-keys = [
        #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        #   "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        # ];

        # hard link identical contents
        auto-optimise-store = true;
      };

      # extraOptions = ''
      #   eval-cores = 0
      #   lazy-trees = true
      # '';

      # Suppress nix-shell channel errors on a flake system
      # nixPath = [ "/etc/nix/path" ];

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    nixpkgs = {
      config.allowUnfree = true;
      # inherit overlays;
    };

    system.stateVersion = "25.11";
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
  };
}
