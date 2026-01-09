{
  pkgs,
  lib,
}:
let
  rawPackages = lib.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ../packages;
  };

  overriddenPackages = lib.mapAttrs (
    name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      meta = (oldAttrs.meta or { }) // {
        maintainers = with lib.maintainers; [ Misaka13514 ];
      };
    })
  ) rawPackages;
in
lib.filterAttrs (
  name: pkg:
  if (builtins.hasAttr "meta" pkg && builtins.hasAttr "platforms" pkg.meta) then
    builtins.elem pkgs.stdenv.hostPlatform.system pkg.meta.platforms
  else
    true
) overriddenPackages
