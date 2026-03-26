# byn: 世界第一可爱
{ pkgs, ... }:
{
  config = {
    users.users."byn" = {
      isNormalUser = true;
      description = "baiyuanneko";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqqbY3YayTNcb2Ak9dHm7NYRbJtdhNzZqFOAun6dtH+ byn@neko"
      ];
    };
    programs.fish.enable = true;
  };
}
