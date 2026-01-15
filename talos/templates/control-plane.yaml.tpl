machine:
  network:
    interfaces:
      - deviceSelector:
          hardwareAddr: ${mgmt_mac}
        vip:
          ip: ${vip_ip}

cluster:
  # Optional Gateway API CRDs
  extraManifests:
    - https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/operator-crds.yaml
    - https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/tigera-operator.yaml