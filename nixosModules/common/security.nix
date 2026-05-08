{ pkgs, ... }:
{
  boot.extraModprobeConfig = ''
    # Mitigate https://dirtyfrag.io
    # https://github.com/V4bel/dirtyfrag
    install esp4 ${pkgs.coreutils}/bin/false
    install esp6 ${pkgs.coreutils}/bin/false
    install rxrpc ${pkgs.coreutils}/bin/false

    # Mitigate CVE-2026-31431 https://copy.fail
    # https://github.com/theori-io/copy-fail-CVE-2026-31431
    install algif_aead ${pkgs.coreutils}/bin/false
  '';
}
