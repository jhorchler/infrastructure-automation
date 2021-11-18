packer {
    required_version = ">= 1.7.8"
    required_plugins {
        qemu = {
            version = ">= 1.0.1"
            source = "github.com/hashicorp/qemu"
        }
        virtualbox = {
            version = ">= 1.0.1"
            source  = "github.com/hashicorp/virtualbox"
        }
    }
}

source "virtualbox-iso" "centos" {
    chipset                = "${var.chipset}"
    disk_size              = "${var.disk_size}"
    nic_type               = "${var.nic_type}"
    guest_os_type          = "${var.guest_os_type}"
    guest_additions_path   = "${var.ga_upload_path}"
    guest_additions_sha256 = "${var.ga_sha256sum}"
    guest_additions_url    = "${var.ga_source_path}"
    keep_registered        = "${var.keep_registered}"
    cpus                   = "${var.cpu_count}"
    memory                 = "${var.mem_size}"
    gfx_controller         = "${var.gfx_controller}"
    gfx_vram_size          = 42
    http_directory         = "${path.root}/kickstart"
    shutdown_command       = "/bin/systemctl poweroff"
    boot_wait              = "10s"
    rtc_time_base          = "UTC"
    hard_drive_interface   = "sata"
    guest_additions_mode   = "upload"
    headless               = false
    usb                    = true
    ssh_username           = "root"
    ssh_password           = "${var.root_password}"
    ssh_timeout            = "15m"
    ssh_pty                = true
    vboxmanage             = [
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ],
        [ "setextradata", "{{ .Name }}", "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", "1" ],
    ]
}

source "qemu" "centos" {
    accelerator         = "${var.qemu_accel}"
    disk_interface      = "${var.qemu_disk_if}"
    machine_type        = "${var.qemu_machine_type}"
    cpus                = "${var.cpu_count}"
    memory              = "${var.mem_size}"
    disk_size           = "${var.disk_size}"
    http_directory      = "${path.root}/kickstart"
    shutdown_command    = "/bin/systemctl poweroff"
    boot_wait           = "10s"
    ssh_username        = "root"
    ssh_password        = "${var.root_password}"
    ssh_timeout         = "15m"
    ssh_pty             = true
    headless            = false
}

build {
    source "virtualbox-iso.centos" {
        name             = "centos7"
        iso_url          = "${var.iso_url_7}"
        iso_checksum     = "${var.iso_checksum_7}"
        vm_name          = "centos7"
        output_directory = "${var.packer_out_path}7"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg ",
            "ip=dhcp inst.text inst.nosave=all ",
            "os_version=7 ",
            "inst_repo=${var.install_mirror_7} ",
            "ssh_password=${var.root_password}",
            "<enter>"
        ]
    }

    source "virtualbox-iso.centos" {
        name             = "centos8"
        iso_url          = "${var.iso_url_8}"
        iso_checksum     = "${var.iso_checksum_8}"
        vm_name          = "centos8"
        output_directory = "${var.packer_out_path}8"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg ",
            "ip=dhcp inst.text inst.nosave=all ",
            "os_version=8 ",
            "inst_repo=${var.install_mirror_8} ",
            "ssh_password=${var.root_password}",
            "<enter>"
        ]
    }

    source "qemu.centos" {
        name             = "centos7"
        iso_url          = "${var.iso_url_7}"
        iso_checksum     = "${var.iso_checksum_7}"
        vm_name          = "centos7"
        output_directory = "${var.packer_out_path}7"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg ",
            "ip=dhcp inst.text inst.nosave=all ",
            "os_version=7 ",
            "inst_repo=${var.install_mirror_7} ",
            "ssh_password=${var.root_password}",
            "<enter>"
        ]
    }

    source "qemu.centos" {
        name             = "centos8"
        iso_url          = "${var.iso_url_8}"
        iso_checksum     = "${var.iso_checksum_8}"
        vm_name          = "centos8"
        output_directory = "${var.packer_out_path}8"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg ",
            "ip=dhcp inst.text inst.nosave=all ",
            "os_version=8 ",
            "inst_repo=${var.install_mirror_8} ",
            "ssh_password=${var.root_password}",
            "<enter>"
        ]
    }

    provisioner "shell" {
        inline = [
            "/usr/bin/yum -y update",
            "/usr/bin/systemctl reboot"
        ]
        expect_disconnect = true
    }

    provisioner "shell" {
        pause_before = "5s"
        only = [
            "virtualbox-iso.centos7",
            "virtualbox-iso.centos8"
        ]
        inline = [
            "/usr/bin/yum -y install make gcc bzip2 tar kernel-devel elfutils-libelf-devel",
            "/usr/bin/mount -o loop ${var.ga_upload_path} /mnt",
            "/mnt/VBoxLinuxAdditions.run",
            "/usr/bin/umount /mnt",
            "/usr/bin/rm -vf ${var.ga_upload_path}"
        ]
    }

    provisioner "shell" {
        pause_before = "5s"
        only = [
            "qemu.centos7",
            "qemu.centos8"
        ]
        inline = [
            "/usr/bin/yum -y install qemu-guest-agent nfs-utils"
        ]
    }

    provisioner "file" {
        source      = "${path.root}/kickstart/${var.user_ssh_key}"
        destination = "/tmp/${var.user_ssh_key}"
    }

    provisioner "shell" {
        inline = [
            "mkdir -pv ~/.ssh",
            "cat /tmp/${var.user_ssh_key} >> ~/.ssh/authorized_keys",
            "rm -v /tmp/${var.user_ssh_key}"
        ]
    }

    provisioner "shell" {
        pause_before = "5s"
        inline = [
            "set -x",
            "/usr/bin/yum clean all",
            "/bin/rm -rf /var/cache/yum || true",
            "/bin/rm -rf /var/cache/dnf || true",
            "/usr/bin/dd if=/dev/zero of=/junk bs=1M || true",
            "/bin/rm -f /junk"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/${source.type}_${source.name}.box"
    }
}
