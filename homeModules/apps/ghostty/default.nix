{
  lib,
  system,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = lib.mkIf (system == "aarch64-darwin") null;
    settings = {
      # font-style = "Retina";
      # mouse-hide-while-typing = true;
      # cursor-style = "bar";
      # cursor-style-blink = false;
      shell-integration-features = "ssh-terminfo,ssh-env";
      # adjust-cursor-thickness = 2;
      # adjust-cell-height = 1;
      # command = lib.getExe pkgs.fish;
      # macos-titlebar-proxy-icon = "hidden";
      # background-blur = true;
    };
  };
}
