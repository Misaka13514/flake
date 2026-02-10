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
      homuraIpv4Address = "127.0.0.2";
      homuraIpv4Gateway = "127.0.0.1";
      homuraIpv6Address = "::2";
      homuraIpv6Gateway = "::1";
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
