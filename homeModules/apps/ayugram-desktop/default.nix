{ pkgs, nixSecrets, ... }:
{
  home.packages = with pkgs; [
    (flakePackages.ayugram-desktop.override {
      tdesktopApiId = nixSecrets.telegramApiId;
      tdesktopApiHash = nixSecrets.telegramApiHash;
    })
  ];
}
