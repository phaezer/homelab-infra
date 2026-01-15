#cloud-config
autoinstall:
  version: 1
  locale: "en_US.UTF-8"
  keyboard:
    layout: us
  timezone: "${timezone}"
  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: '${build_password_encrypted}'
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
    - qemu-guest-agent
    - cloud-init
  storage:
    layout:
      name: direct
  user-data:
    disable_root: false
    users:
      - name: "${ansible_username}"
        gecos: Ansible User
        groups: users, admin, sudo, wheel
        shell: /bin/bash
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd: true
        ssh_authorized_keys:
          - ${ansible_ssh_public_key}
