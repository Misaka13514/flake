{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      nh
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

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    nixpkgs = {
      config = {
        # allowUnfree = true;
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "b43-firmware"
            "broadcom-bt-firmware"
            "facetimehd-calibration"
            "facetimehd-firmware"
            "nvidia-settings"
            "nvidia-x11"
            "obsidian"
            "steam-unwrapped"
            "steam"
            "vscode"
            "xow_dongle-firmware"
          ];
      };
      # inherit overlays;
    };

    system.stateVersion = "25.11";
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
  };
}
