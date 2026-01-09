{
  lib,
  username,
  secretsPath,
  osConfig,
  system,
  pkgs,
  ...
}:
let
  homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";
in
{
  imports = osConfig.noa.homeManager.modules;

  config = {
    programs.home-manager.enable = true;

    home = {
      inherit username homeDirectory;
      sessionVariables = {
        LANG = "en_US.UTF-8";
        LANGUAGE = "en_US";
      };
      stateVersion = "25.11";
    };

    sops = {
      age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
      # defaultSopsFile = "${secretsPath}/home.yaml";
    };

    # Disable GPG for sops-nix systemd user service
    # Workaround for https://github.com/Mic92/sops-nix/issues/356
    systemd.user.services.sops-nix.Service.Environment = lib.mkForce [
      "SOPS_GPG_EXEC=${pkgs.coreutils}/bin/false"
    ];

    xdg.userDirs = lib.mkIf (system != "aarch64-darwin") {
      enable = true;
      createDirectories = true;
    };
  };

  options = {
    noa.nixpkgs.allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of unfree packages allowed to be installed.";
    };
  };
}
