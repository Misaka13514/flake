{
  pkgs,
  ...
}:
{
  imports = [
    ./apps/ghostty
  ];

  home.packages = with pkgs; [
    ipatool
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
