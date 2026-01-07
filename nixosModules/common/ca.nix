{
  assetsPath,
  pkgs,
  ...
}:
{
  security.pki.certificateFiles = [
    "${assetsPath}/ca.pem"
    "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt"
  ];
}
