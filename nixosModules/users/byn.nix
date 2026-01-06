# byn: 世界第一可爱
{
  pkgs,
  ...
}:
{
  config = {
    users.users."byn" = {
      isNormalUser = true;
      description = "baiyuanneko";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtVrKjO4dfvI8Hi6Nn583LfTU6CKjp9Yd7UyLuy0ffx 2026-01-06"
      ];
    };
    programs.fish.enable = true;
  };
}
