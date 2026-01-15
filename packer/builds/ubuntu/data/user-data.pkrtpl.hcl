#cloud-config
autoinstall:
  version: 1
  locale: "${locale}"
  keyboard:
    layout: "${keyboard}"
  timezone: "${timezone}"
  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: '${build_password_encrypted}'
  ssh:
    install-server: true
    allow-pw: true
    authorized_keys:
      - ${build_key}
  packages:
%{ for pkg in packages ~}
    - ${pkg}
%{ endfor ~}
  storage:
    layout:
      name: direct
  user-data:
    users:
      - name: "${build_username}"
        gecos: Init User
        groups: users, admin, sudo, wheel
        shell: /bin/bash
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        passwd: '${build_password_encrypted}'
        ssh_authorized_keys:
          - ${build_key}
