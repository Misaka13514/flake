_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
      upgrade = true;
      extraFlags = [
        "--force-cleanup"
      ];
    };

    masApps = {
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      "VooV Meeting" = 1497685373;
      "Windows App" = 1295203466;
      LINE = 539883307;
      # "WPS Office" = 1443749478;
      # Lark = 1551632588;
      # NeteaseCloudMusic = 944848654;
      # QQ = 451108668;
      # TencentMeeting = 1484048379;
      # Wechat = 836500024;
    };

    taps = [
      # "xpipe-io/tap"
      # "mfkrause/tap"
    ];

    brews = [
      "displayplacer"
      "mole"
      "opencode"
      # "jnsahaj/lumen/lumen"
      # "ollama"
      # "tmux"
    ];

    casks = [
      "antigravity-cli"
      "ayugram"
      "charles"
      "firefox@developer-edition"
      "ghostty"
      "gimp"
      "google-chrome"
      "iina"
      "iina"
      "maccy"
      "monitorcontrol"
      "obs"
      "obsidian"
      "orbstack"
      "playcover-community"
      "scroll-reverser"
      "stats"
      "steam"
      "tailscale-app"
      "v2rayu"
      "visual-studio-code"
      "wechat"
      "yubico-authenticator"
      # "1password-cli"
      # "1password"
      # "alt-tab"
      # "bruno"
      # "codex"
      # "consul" # https://getconsul.app/
      # "dbeaver-community"
      # "figma"
      # "firefox"
      # "font-fira-code-nerd-font"
      # "font-maple-mono-nf-cn"
      # "karabiner-elements"
      # "kitty"
      # "latest"
      # "launchcontrol"
      # "onedrive"
      # "raycast"
      # "rectangle"
      # "shottr"
      # "slack"
      # "telegram-desktop"
      # "thaw"
      # "typora"
      # "warp"
      # "xpipe"
      # "zed"
    ];
  };
}
