{
  description = "Misaka's private flake";

  outputs =
    { self }:
    {
      secrets = {
        initialHashedPassword = null;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7DuYiwiKT6VCfWLCE/OTALtgqujaZWWoco9pKmGKGP openpgp:0x88613226"
        ];
      };
    };
}
