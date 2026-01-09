self: final: prev: {
  flakePackages =
    let
      # for fixed cache
      unstablePkgs = import self.inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (prev) config;
      };
    in
    import ../lib/mkMyPackages.nix {
      pkgs = unstablePkgs;
      inherit (prev) lib;
    };
}
