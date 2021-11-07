packer {
    required_version = ">= 1.7.0"
    required_plugins {
        qemu = {
            version = ">= 1.0.1"
            source = "github.com/hashicorp/qemu"
        }
    }
}

locals {
    build_time = regex_replace(timestamp(), "[- TZ:]", "")
}

source "virtualbox-iso" "opensuse" {
    chipset                 = "${var.chipset}"
    nic_type                = "${var.nic_type}"
    disk_size               = "${var.disk_size}"
    cpus                    = "${var.cpu_count}"
    memory                  = "${var.mem_size}"
    guest_os_type           = "${var.guest_os_type}"
    gfx_controller          = "${var.gfx_controller}"
    gfx_vram_size           = 42
    hard_drive_interface    = "sata"
    guest_additions_mode    = "disable"
    shutdown_command        = "/sbin/halt -p"
    boot_wait               = "10s"
    ssh_username            = "root"
    ssh_password            = "${var.root_password}"
    ssh_timeout             = "15m"
    pause_before_connecting = "3m"
    rtc_time_base           = "UTC"
    ssh_pty                 = true
    headless                = true
    usb                     = true
    keep_registered         = "${var.keep_registered}"
    vboxmanage              = [
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ]
    ]
    http_content            = {
        "/autoinst.xml" = templatefile("${path.root}/${var.http_directory}/${var.autoyast_template}", {
            boot_device   = "sda",
            user_password = "${var.root_password}"
        })
    }
}

source "qemu" "opensuse" {
    accelerator         = "${var.qemu_accel}"
    disk_interface      = "${var.qemu_disk_if}"
    machine_type        = "${var.qemu_machine_type}"
    cpus                = "${var.cpu_count}"
    memory              = "${var.mem_size}"
    disk_size           = "${var.disk_size}"
    shutdown_command    = "/sbin/halt -p"
    boot_wait           = "10s"
    ssh_username        = "root"
    ssh_password        = "${var.root_password}"
    ssh_timeout         = "15m"
    ssh_pty             = true
    headless            = true
    http_content            = {
        "/autoinst.xml" = templatefile("${path.root}/${var.http_directory}/${var.autoyast_template}", {
            boot_device   = "vda",
            user_password = "${var.root_password}"
        })
    }
}

build {
    source "virtualbox-iso.opensuse" {
        name             = "opensuse42"
        iso_url          = "${var.iso_url_42}"
        iso_checksum     = "${var.iso_checksum_42}"
        vm_name          = "opensuse42-${local.build_time}"
        output_directory = "${var.packer_out_path}42"
        boot_command     = [
            "<esc><enter><wait>",
            "linux ",
            "biosdevname=0 ",
            "net.ifnames=0 ",
            "netdevice=eth0 ",
            "netsetup=dhcp ",
            "lang=en_US ",
            "textmode=1 ",
            "self_update=1 ",
            "install=${var.install_mirror_42} ",
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
            "<enter><wait>"
        ]
    }

    source "virtualbox-iso.opensuse" {
        name             = "opensuse15"
        iso_url          = "${var.iso_url_15}"
        iso_checksum     = "${var.iso_checksum_15}"
        vm_name          = "opensuse15-${local.build_time}"
        output_directory = "${var.packer_out_path}15"
        boot_command     = [
            "<esc><enter><wait>",
            "linux ",
            "biosdevname=0 ",
            "net.ifnames=0 ",
            "netdevice=eth0 ",
            "netsetup=dhcp ",
            "lang=en_US ",
            "textmode=1 ",
            "self_update=1 ",
            "install=${var.install_mirror_15} ",
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
            "<enter><wait>"
        ]
    }

    source "qemu.opensuse" {
        name             = "opensuse42"
        iso_url          = "${var.iso_url_42}"
        iso_checksum     = "${var.iso_checksum_42}"
        vm_name          = "opensuse42-${local.build_time}"
        output_directory = "${var.packer_out_path}42"
        boot_command     = [
            "<esc><enter><wait>",
            "linux ",
            "biosdevname=0 ",
            "net.ifnames=0 ",
            "netdevice=eth0 ",
            "netsetup=dhcp ",
            "lang=en_US ",
            "textmode=1 ",
            "self_update=1 ",
            "install=${var.install_mirror_42} ",
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
            "<enter><wait>"
        ]
    }

    source "qemu.opensuse" {
        name             = "opensuse15"
        iso_url          = "${var.iso_url_15}"
        iso_checksum     = "${var.iso_checksum_15}"
        vm_name          = "opensuse15-${local.build_time}"
        output_directory = "${var.packer_out_path}15"
        boot_command     = [
            "<esc><enter><wait>",
            "linux ",
            "biosdevname=0 ",
            "net.ifnames=0 ",
            "netdevice=eth0 ",
            "netsetup=dhcp ",
            "lang=en_US ",
            "textmode=1 ",
            "self_update=1 ",
            "install=${var.install_mirror_15} ",
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
            "<enter><wait>"
        ]
    }

    provisioner "shell" {
        pause_before = "5m"
        inline = [
            "zypper install -y -n curl tar gzip",
        ]
    }

    provisioner "shell" {
        pause_before = "5s"
        only = [
            "virtualbox-iso.opensuse42",
            "virtualbox-iso.opensuse15"
        ]
        inline = [
            "zypper install -y -n virtualbox-guest-tools virtualbox-guest-kmp-default",
            "echo vboxsf >/etc/modules-load.d/vboxsf.conf"
        ]
    }

    provisioner "shell" {
        pause_before = "5s"
        only = [
            "qemu.opensuse42",
            "qemu.opensuse15"
        ]
        inline = [
            "zypper install -y -n qemu-guest-agent"
        ]
    }

    provisioner "file" {
        source      = "${path.root}/${var.http_directory}/${var.user_ssh_key}"
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
            "zypper clean --all",
            "rm /var/lib/wicked/* > /dev/null 2>&1",
            "rm /etc/udev/rules.d/70-persistent-net.rules",
            "sed -i /HWADDR/d /etc/sysconfig/network/ifcfg-eth0",
            "dd if=/dev/zero of=/junk bs=1M || true",
            "rm -f /junk"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/{{.Provider}}_${local.build_time}.box"
    }
}
