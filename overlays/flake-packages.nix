self: final: prev: {
  flakePackages =
    let
      # for fixed cache
      unstablePkgs = import self.inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config = {
          allowUnfree = prev.config.allowUnfree or false;
          allowUnfreePredicate = prev.config.allowUnfreePredicate or (_: false);
        };
      };
    in
    import ../lib/mkMyPackages.nix {
      pkgs = unstablePkgs;
      inherit (prev) lib;
    };
}
