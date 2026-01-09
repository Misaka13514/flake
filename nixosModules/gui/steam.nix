_: {
  programs.steam.enable = true;

  noa.nixpkgs.allowedUnfreePackages = [
    "steam-unwrapped"
    "steam"
  ];
}
