{
  pkgs,
  ...
}:
{
  imports = [
    ./apps/ghostty
  ];

  home.packages = with pkgs; [
    flakePackages.ninjabrain-bot
    hmcl
    ipatool
    vt-cli
    yt-dlp
  ];

  programs.gpg = {
    enable = true;
    settings = {
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
}
