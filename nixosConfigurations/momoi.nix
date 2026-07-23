# momoi: NixOS of Unique Idea
{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.single-disk-ext4
    users.atri
  ];

  networking.firewall = {
    trustedInterfaces = [
      "cni0"
      "flannel.1"
      "flannel-v6.1"
    ];

    allowedTCPPorts = [
      80 # traefik in k3s
      443 # traefik in k3s
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      8999 # syncplay in k3s
      # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    ];
    allowedUDPPorts = [
      443 # hysteria2 in k3s
      # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"
      "--disable=servicelb"
      "--cluster-cidr=172.24.0.0/16,fc42::/48"
      "--service-cidr=172.25.0.0/16,fc43::/112"
      "--flannel-ipv6-masq=true"
      # "--debug" # Optionally add additional args to k3s
    ];
  };
}
