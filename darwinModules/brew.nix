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
      Wechat = 836500024;
      # "WPS Office" = 1443749478;
      # Lark = 1551632588;
      # NeteaseCloudMusic = 944848654;
      # QQ = 451108668;
      # TencentMeeting = 1484048379;
    };

    taps = [
      # "xpipe-io/tap"
      # "mfkrause/tap"
    ];

    brews = [
      "opencode"
      # "jnsahaj/lumen/lumen"
      # "ollama"
      # "tmux"
    ];

    casks = [
      "antigravity-cli"
      "ayugram"
      "firefox@developer-edition"
      "ghostty"
      "google-chrome"
      "obs"
      "obsidian"
      "orbstack"
      "playcover-community"
      "tailscale-app"
      "v2rayu"
      "visual-studio-code"
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
      # "maccy"
      # "onedrive"
      # "raycast"
      # "rectangle"
      # "shottr"
      # "slack"
      # "stats"
      # "telegram-desktop"
      # "thaw"
      # "typora"
      # "warp"
      # "xpipe"
      # "zed"
    ];
  };
}
