{
  description = "Misaka's NixOS Flake";

  inputs = {
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-2511-nixos = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-2511";
    };
    home-manager-unstable-nixos = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager-unstable-nixos";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-secrets.url = "git+ssh://git@github.com/Misaka13514/nix-secrets.git?shallow=1";
  };

  outputs =
    inputs@{
      self,
      nixpkgs-2511,
      nixpkgs-unstable,
      flake-utils,
      nix-secrets,
      ...
    }:
    let
      inherit (inputs.nixpkgs-2511) lib;
      secretsPath = ./secrets;
      assetsPath = ./assets;
      unfreePackages = [
        "b43-firmware"
        "broadcom-bt-firmware"
        "burpsuite"
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "facetimehd-calibration"
        "facetimehd-firmware"
        "ida-pro"
        "libcublas"
        "nvidia-settings"
        "nvidia-x11"
        "obsidian"
        "steam-unwrapped"
        "steam"
        "vscode"
        "xow_dongle-firmware"
      ];
      unfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;

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
          unfreePredicate
          ;
        inherit (self)
          nixosModules
          homeModules
          ;
        overlays = lib.attrValues self.overlays;
        nixSecrets = inputs.nix-secrets.secrets;
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
              # config.allowUnfree = true;
              # overlays = lib.attrValues self.overlays;
            };
            unstableHosts = [
              "Index"
              "nixos"
            ];
            nixpkgs = if builtins.elem hostname unstableHosts then nixpkgs-unstable else nixpkgs-2511;
            home-manager-nixos =
              if builtins.elem hostname unstableHosts then
                inputs.home-manager-unstable-nixos
              else
                inputs.home-manager-2511-nixos;
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = globalSpecialArgs // {
              inherit hostname system unstablePkgs;
            };
            modules = [
              path
              ./hardwares/${hostname}.nix
              self.nixosModules.common
              # inputs.disko.nixosModules.disko
              home-manager-nixos.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.default
              inputs.sops-nix.nixosModules.sops
              inputs.vscode-server.nixosModules.default
              # inputs.stylix.nixosModules.stylix
              # inputs.niri.nixosModules.niri
            ];
          };

        directory = ./nixosConfigurations;
      };

      overlays = {
        flake-packages = import ./overlays/flake-packages.nix self;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs-unstable {
          inherit system;
          # config.allowUnfree = true;
          config.allowUnfreePredicate = unfreePredicate;
          # overlays = lib.attrValues self.overlays;
        };
      in
      {
        packages =
          lib.filterAttrs
            (
              pname: package:
              if (builtins.hasAttr "meta" package && builtins.hasAttr "platforms" package.meta) then
                builtins.elem system package.meta.platforms
              else
                true
            )
            (
              lib.packagesFromDirectoryRecursive {
                inherit (pkgs) callPackage;
                directory = ./packages;
              }
            );

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            just
            deploy-rs
            nixfmt-rfc-style
            ssh-to-age
            sops
            jq
            openssh
            wireguard-tools
            git-agecrypt
            nh
          ];
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
