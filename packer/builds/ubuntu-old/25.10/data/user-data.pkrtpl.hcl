#cloud-config
autoinstall:
  version: 1
  # early-commands:
  #   - sudo systemctl stop ssh
  locale: "en_US.UTF-8"
  keyboard:
    layout: us
  timezone: "${timezone}"
  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: "${build_password_encrypted}"
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
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
  # late-commands:
  #   - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
  #   - curtin in-target -- apt-get update