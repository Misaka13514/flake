{
  inputs = {
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-2511-nixos = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-2511";
    };
    home-manager-unstable-nixos = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs-2511,
      nixpkgs-unstable,
      home-manager-2511-nixos,
      home-manager-unstable-nixos,
      ...
    }:
    let
      inherit (inputs.nixpkgs-2511) lib;
      secretsPath = ./secrets;
      assetsPath = ./assets;
      # This recursive attrset pattern is forbidden, but we use it here anyway.
      #
      # The following flake output attributes must be NixOS modules:
      # - nixosModule
      # - nixosModules.name
      modulesFromDirectoryRecursive =
        _dirPath:
        lib.packagesFromDirectoryRecursive {
          callPackage = path: _: import path;
          directory = _dirPath;
        };
      globalSpecialArgs = {
        inherit
          inputs
          secretsPath
          assetsPath
          ;
        inherit (self)
          nixosModules
          homeModules
          ;
        # overlays = lib.attrValues self.overlays;
      };
    in
    {
      nixosModules = modulesFromDirectoryRecursive ./nixosModules;

      # darwinModules = modulesFromDirectoryRecursive ./darwinModules;

      homeModules = modulesFromDirectoryRecursive ./homeModules;

      nixosConfigurations = lib.packagesFromDirectoryRecursive {
        callPackage =
          path: _:
          let
            hostname = lib.removeSuffix ".nix" (builtins.baseNameOf path);
            system = "x86_64-linux";
            unstablePkgs = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              # overlays = lib.attrValues self.overlays;
            };
          in
          nixpkgs-unstable.lib.nixosSystem {
            inherit system;
            specialArgs = globalSpecialArgs // {
              inherit hostname system unstablePkgs;
            };
            modules = [
              path
              ./hardwares/${hostname}.nix
              self.nixosModules.common
              # inputs.disko.nixosModules.disko
              inputs.home-manager-unstable-nixos.nixosModules.home-manager
              # inputs.sops-nix.nixosModules.sops
              # inputs.stylix.nixosModules.stylix
              # inputs.niri.nixosModules.niri
            ];
          };

        directory = ./nixosConfigurations;
      };
    };
}
