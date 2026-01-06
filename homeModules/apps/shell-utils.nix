{
  lib,
  config,
  pkgs,
  ...
}:
let
  extraPackages = with pkgs; [
    any-nix-shell
    fastfetch
    ldns
    nmap
    p7zip
    pciutils
    usbutils
    whois
    dust
    duf
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.git = {
    enable = true;
    settings = {
      user.name = "Misaka13514";
      user.email = "Misaka13514@gmail.com";
      init.defaultBranch = "main";
      commit.gpgsign = true;
      diff.sopsdiffer.textconv = "${pkgs.sops}/bin/sops -d";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
  };

  programs.fish = {
    enable = true;
    plugins = map (x: { inherit (x) name src; }) (
      with pkgs.fishPlugins;
      [
        plugin-git
        fzf-fish
        puffer
      ]
    );
    shellInit = "set -g fish_greeting";
    interactiveShellInit = ''
      any-nix-shell fish --info-right | source
    '';
    shellAliases = {
      ".." = "cd ../";
      "n" = "nvim";
      "ls" = "eza -l";
      "l" = "eza -l";
      "ll" = "eza -al";
      "tree" = "eza --tree";
      "gg" = "lazygit";
    };
  };

  programs.lazygit = {
    enable = true;
  };

  # Replace command-not-found with nix-index and comma
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Modern unix series
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat.enable = true;

  programs.btop.enable = true;

  programs.jq.enable = true;

  programs.ripgrep.enable = true;

  programs.fd = {
    enable = true;
    ignores = [
      ".git/"
      "node_modules/"
    ];
  };

  programs.tealdeer.enable = true;
}
