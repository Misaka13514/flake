# QEMU x86_64 guest
{
  lib,
  modulesPath,
  nixSecrets,
  ...
}:
{
  hardware.facter.reportPath = ./homura.json;

  networking = {
    useDHCP = false;

    # nameservers = [ "67.207.67.3" "67.207.67.2" ];
    nameservers = [ "8.8.8.8" ];

    defaultGateway = {
      address = nixSecrets.homuraIpv4Gateway;
      interface = "eth0";
    };
    defaultGateway6 = {
      address = nixSecrets.homuraIpv6Gateway;
      interface = "eth0";
    };

    interfaces = {
      eth0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = nixSecrets.homuraIpv4Address;
            prefixLength = 20;
          }
          {
            address = "10.48.0.5";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = nixSecrets.homuraIpv6Address;
            prefixLength = 64;
          }
        ];
      };
      eth1 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "10.124.0.2";
            prefixLength = 20;
          }
        ];
      };
    };
  };

  systemd.network.links = {
    "10-eth0" = {
      matchConfig.MACAddress = "be:67:45:c7:9b:df";
      linkConfig.Name = "eth0";
    };
    "10-eth1" = {
      matchConfig.MACAddress = "d2:8b:77:82:46:da";
      linkConfig.Name = "eth1";
    };
  };

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because DO uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };
}
