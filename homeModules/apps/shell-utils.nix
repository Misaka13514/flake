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
    settings = {
      add_newline = true;
      directory = {
        fish_style_pwd_dir_length = 1;
      };
      line_break = {
        disabled = true;
      };
    };
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
      "ls" = "eza --classify=auto --icons=auto --group-directories-first";
      "l" = "eza --classify=auto --icons=auto --group-directories-first -l";
      "ll" = "eza --classify=auto --icons=auto --group-directories-first -al";
      "tree" = "eza --classify=auto --icons=auto --tree";
      "gg" = "lazygit";
    };
    functions = {
      fish_title = {
        body = "echo $(pwd)";
      };
      pb = {
        body = ''
          set -l target_url "https://p.apeiria.net"
          if test (count $argv) -ge 1; and test -f "$argv[1]"
            curl -F "c=@$argv[1]" $target_url
          else if not isatty stdin
            set -l temp_file (mktemp)
            cat > $temp_file
            curl -F "c=@$temp_file" $target_url
            rm $temp_file
          else
            echo "Usage: pb <filename> OR command | pb"
            return 1
          end
        '';
      };
    };
  };

  programs.lazygit = {
    enable = true;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "https";
    };
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
