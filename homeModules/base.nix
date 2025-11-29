{
  lib,
  username,
  secretsPath,
  osConfig,
  system,
  ...
}:
let
  homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";
in
{
  imports = osConfig.noa.homeManager.modules;

  programs.home-manager.enable = true;

  home = {
    inherit username homeDirectory;
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LANGUAGE = "en_US";
    };
    stateVersion = "25.11";
  };

  # sops = {
  #   age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
  #   defaultSopsFile = "${secretsPath}/home.yaml";
  # };

  xdg.userDirs = lib.mkIf (system != "aarch64-darwin") {
    enable = true;
    createDirectories = true;
  };
}
