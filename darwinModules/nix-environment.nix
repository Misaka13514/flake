{
  config,
  inputs,
  pkgs,
  lib,
  overlays,
  system,
  ...
}:
{
  config = {
    nix = {
      package = pkgs.nixVersions.latest;
      registry = {
        noa.flake = inputs.self;
      };
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
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

    nixpkgs = {
      hostPlatform = { inherit system; };
      config.allowUnfree = true;
      inherit overlays;
    };

    # do garbage collection weekly to keep disk usage low
    nix = {
      gc.automatic = true;
      optimise.automatic = true;
    };
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
  };
}
