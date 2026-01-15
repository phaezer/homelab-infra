# Locale and Keyboard
d-i debian-installer/locale string ${locale}
d-i keyboard-configuration/xkb-keymap select ${keyboard}

d-i auto-install/enable boolean true
d-i debian-installer/framebuffer boolean false

# Clock and Timezone
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
d-i time/zone string ${timezone}

# Grub
d-i grub-installer/only_debian boolean true

# Storage
d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Network configuration
d-i netcfg/choose_interface select ${network_device}
d-i netcfg/disable_dhcp boolean false

# Turn CD Off
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-next boolean false
d-i apt-setup/cdrom/set-failed boolean false

# Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string cdn-fastly.deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# User Configuration
d-i passwd/root-login boolean false
d-i passwd/user-fullname string ${build_username}
d-i passwd/username string ${build_username}
d-i passwd/user-password-crypted password ${build_password_encrypted}

# Software Selection
d-i debconf debconf/frontend select noninteractive
tasksel tasksel/first multiselect standard, ssh-server

d-i apt-setup/contrib boolean true
d-i apt-setup/non-free boolean true
d-i apt-setup/security_host string security.debian.org
d-i apt-setup/services-select multiselect security, updates

d-i pkgsel/include string openssh-server qemu-guest-agent python3-apt curl
d-i pkgsel/upgrade select full-upgrade
d-i pkgsel/update-policy select none
d-i pkgsel/updatedb boolean true

# Disable Popularity Contest
popularity-contest popularity-contest/participate boolean false

# Late Commands
d-i preseed/late_command string \
    echo '${build_username} ALL=(ALL) NOPASSWD: ALL' > /target/etc/sudoers.d/${build_username}; \
    in-target chmod 440 /etc/sudoers.d/${build_username};


# Bootloader
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev  string default

# Finishing up
d-i finish-install/reboot_in_progress note