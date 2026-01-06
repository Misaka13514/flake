# atri: -My Dear Moments with Nix-
{
  pkgs,
  lib,
  config,
  inputs,
  homeModules,
  nixSecrets,
  ...
}@osSpecialArgs:
let
  username = "atri";
  useKde = config.services.desktopManager.plasma6.enable;
in
{
  options = {
    noa.homeManager = {
      enable = lib.mkEnableOption "Enable home-manager for ${username}";
      modules = lib.mkOption {
        default = [ ];
        description = "Extra modules for home-manager";
      };
    };
  };

  config = {
    users.users."${username}" = {
      isNormalUser = true;
      description = "Misaka13514";
      extraGroups = [
        "wheel"
        "video"
        "docker"
        "networkmanager"
        "input"
        "wireshark"
      ];
      shell = pkgs.fish;
      inherit (nixSecrets) initialHashedPassword;
      openssh.authorizedKeys.keys = nixSecrets.authorizedKeys;
    };

    programs.fish.enable = true;

    home-manager = lib.mkIf config.noa.homeManager.enable {
      sharedModules = [
        inputs.nix-index-database.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
      ]
      ++ lib.optionals useKde [
        inputs.plasma-manager.homeModules.plasma-manager
      ];
      users."${username}".imports = [
        homeModules.base
      ];
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-bak";
      extraSpecialArgs = {
        inherit (osSpecialArgs)
          inputs
          system
          hostname
          unstablePkgs
          secretsPath
          assetsPath
          nixSecrets
          ;
        inherit username;
      };
    };

    nix.settings.trusted-users = [ username ];
  };
}
