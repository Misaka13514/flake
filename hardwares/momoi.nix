# QEMU x86_64 guest
{
  lib,
  modulesPath,
  ...
}:
{
  hardware.facter.reportPath = ./momoi.json;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200n8"
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.tempAddresses = "disabled";

  systemd.network.enable = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = "ens18";
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
      IPv6PrivacyExtensions = "no";
    };

    ipv6AcceptRAConfig = {
      Token = "::3";
    };
  };
}
