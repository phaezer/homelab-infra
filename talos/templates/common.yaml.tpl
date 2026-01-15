---
machine:
  type: ${machine_type}
  # Kubelet configuration
  # kubelet:
  #   extraArgs:
  #     rotate-server-certificates: true

  # Enable kernel modules for Ceph RBD
  kernel:
    modules:
      - name: rbd
      - name: ceph

  # Node labels
  nodeLabels: ${node_labels}

  # Time configuration, critical for ceph
  time:
    servers:
      - time.cloudflare.com
    bootTimeout: 2m0s

  # sysctl settings
  sysctls:
    # optimizations for fast networking >= 10Gbps
    fs.inotify.max_user_watches: 1048576
    fs.inotify.max_user_instances: 8192
    net.core.default_qdisc: fq
    net.core.rmem_max: 67108864
    net.core.wmem_max: 67108864
    net.ipv4.tcp_congestion_control: bbr
    net.ipv4.tcp_fastopen: 3
    net.ipv4.tcp_mtu_probing: 1
    net.ipv4.tcp_rmem: 4096 87380 33554432
    net.ipv4.tcp_wmem: 4096 65536 33554432
    net.ipv4.tcp_window_scaling: 1
    vm.nr_hugepages: 1024
    vm.max_map_count: 262144

  # # Network configuration
  network:
    # hostname: ${hostname}
    nameservers: ${nameservers}
  #   interfaces:
  #   # default network interface
  #     - deviceSelector:
  #         hardwareAddr: ${mgmt_mac}
  #       addresses:
  #         - ${mgmt_address}
  #       dhcp: false
  #       routes:
  #         - network: 0.0.0.0/0
  #           gateway: ${mgmt_gateway_ip}
  #       mtu: ${mgmt_mtu}
  #   # ceph network interface
  #     - deviceSelector:
  #         hardwareAddr: ${ceph_mac}
  #       dhcp: false
  #       addresses:
  #         - ${ceph_address}
  #       mtu: ${ceph_mtu}
  #       routes: []  # No default route on storage network

# Kubernetes cluster configuration
cluster:
  # network configuration
  network:
    podSubnets: ${pod_subnet_cidrs}
    serviceSubnets: ${svc_subnet_cidrs}
    cni:
      name: none # no cni, we use Calico

  proxy:
    disabled: true # using calico instead

  # small cluster, we'll schedule on control planes
  allowSchedulingOnControlPlanes: ${allow_scheduling_on_control_planes}
