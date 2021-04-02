packer {
    required_version = ">= 1.7.0"
}

locals {
    build_time = regex_replace(timestamp(), "[- TZ:]", "")
}

source "virtualbox-iso" "opensuse" {
    disk_size               = "${var.disk_size}"
    cpus                    = "${var.cpu_count}"
    memory                  = "${var.mem_size}"
    guest_os_type           = "${var.guest_os_type}"
    http_directory          = "${var.http_directory}"
    hard_drive_interface    = "sata"
    guest_additions_mode    = "disable"
    shutdown_command        = "/sbin/halt -p"
    boot_wait               = "10s"
    ssh_username            = "root"
    ssh_password            = "${var.root_password}"
    ssh_timeout             = "15m"
    pause_before_connecting = "3m"
    ssh_pty                 = true
    headless                = true
    usb                     = true
    keep_registered         = "${var.keep_registered}"
    vboxmanage              = [
        [ "modifyvm", "{{ .Name }}", "--rtcuseutc", "on" ],
        [ "modifyvm", "{{ .Name }}", "--nictype1", "virtio" ],
        [ "modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga" ],
        [ "modifyvm", "{{ .Name }}", "--vram", "42" ],
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ]
    ]
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
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.autoyast_42} ",
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
            "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.autoyast_15} ",
            "<enter><wait>"
        ]
    }

    provisioner "shell" {
        inline = [
            "zypper install -y -n curl tar gzip virtualbox-guest-tools",
        ]
    }

    provisioner "file" {
        source      = "${path.root}/autoyast/${var.user_ssh_key}"
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
        inline = [
            "zypper clean --all",
            "dd if=/dev/zero of=/junk bs=1M || true",
            "rm -f /junk"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/${build.ID}.box"
    }
}
