{
  description = "Misaka's private flake";

  outputs =
    { self }:
    {
      secrets = {
        initialHashedPassword = null;
      };
    };
}
