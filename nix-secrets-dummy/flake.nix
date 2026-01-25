{
  description = "Misaka's private flake";

  outputs = _: {
    secrets = {
      initialHashedPassword = null;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7DuYiwiKT6VCfWLCE/OTALtgqujaZWWoco9pKmGKGP openpgp:0x88613226"
      ];
      homeDomain = "example.org";
      telegramApiId = null;
      telegramApiHash = null;
      homuraIpv4Address = null;
      homuraIpv4Gateway = null;
      homuraIpv6Address = null;
      homuraIpv6Gateway = null;
      homuraDomain = "example.org";
      homuraDomainCdn = "cdn.example.org";
      homuraDomainHack = "hack.example.org";
      homuraWsPath = "/vmess";
      headscaleDomain = "hs.example.org";
      webdavDomain = "dav.example.org";
      webdavDomainCdn = "cdn.example.org";
    };
  };
}
