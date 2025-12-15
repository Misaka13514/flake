{
  pkgs,
  lib,
  hostname,
  nixSecrets,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
  ];

  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = nixSecrets.authorizedKeys;
  };

  networking.hostName = lib.mkDefault hostname;
  networking.firewall.enable = true;
  networking.nftables.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
  };

  programs.ssh.knownHosts = {
    "github.com" = {
      publicKey = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
        ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
      '';
    };
    "aur.archlinux.org" = {
      publicKey = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN
        ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLMiLrP8pVi5BFX2i3vepSUnpedeiewE5XptnUnau+ZoeUOPkpoCgZZuYfpaIQfhhJJI5qgnjJmr4hyJbe/zxow=
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKF9vAFWdgm9Bi8uc+tYRBmXASBb5cB5iZsB7LOWWFeBrLp3r14w0/9S2vozjgqY5sJLDPONWoTTaVTbhe3vwO8CBKZTEt1AcWxuXNlRnk9FliR1/eNB9uz/7y1R0+c1Md+P98AJJSJWKN12nqIDIhjl2S1vOUvm7FNY43fU2knIhEbHybhwWeg+0wxpKwcAd/JeL5i92Uv03MYftOToUijd1pqyVFdJvQFhqD4v3M157jxS5FTOBrccAEjT+zYmFyD8WvKUa9vUclRddNllmBJdy4NyLB8SvVZULUPrP3QOlmzemeKracTlVOUG1wsDbxknF1BwSCU7CmU6UFP90kpWIyz66bP0bl67QAvlIc52Yix7pKJPbw85+zykvnfl2mdROsaT8p8R9nwCdFsBc9IiD0NhPEHcyHRwB8fokXTajk2QnGhL+zP5KnkmXnyQYOCUYo3EKMXIlVOVbPDgRYYT/XqvBuzq5S9rrU70KoI/S5lDnFfx/+lPLdtcnnEPk=
      '';
    };
    "build.archlinuxcn.org" = {
      extraHostNames = [ "[build.archlinuxcn.org]:8122" ];
      publicKey = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiYTB+9JVjER580kp4YTgldaAG9NgjbL+EFh9LD1LIt
        ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIC+WMGWNvy78GyHWTmpAbXtNQil/p2xuCx358RT5bw+LgMwbVgBAQg1cYZWy3X7s3jeXZ9Re0iNS2WD6QPTnUA=
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD6UdX1Ii/xi9ZPa9Yi37iYpxW+D5t6eC6zVWquImLWELjwudA1l/O1fCAoeSQEtgqu0ChIpYtyBsTpGxX7PxYS+f5MZsOXeRn83hYhghqVgBtviAJB0CbFmSZEYzkRH1y/cqecTo9INAsMtBMA9KN/AZQM7e9FBM3OHbyryseAcC/KSD7xpD3tCF91kjroiEEPAb+dD5O/qNccq1RWEuKsIRmTW9PytIgQBipOUYgZuY3UeHng4TxCXe5gIgspkYVDFEmllTRWRvF79HeK7XwtOGGY4r2h0jj+435AMLRUHFMDnI2ra2kfvynniVh3/EgIamEhbA4iTf8PI00x+k9T
      '';
    };
  };

  programs.git.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
