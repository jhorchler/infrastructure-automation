packer {
    required_version = ">= 1.7.0"
}

locals {
    build_time = regex_replace(timestamp(), "[- TZ:]", "")
}

source "virtualbox-iso" "centos" {
    disk_size              = "${var.disk_size}"
    cpus                   = "${var.cpu_count}"
    memory                 = "${var.mem_size}"
    guest_os_type          = "${var.guest_os_type}"
    guest_additions_path   = "${var.ga_upload_path}"
    guest_additions_sha256 = "${var.ga_sha256sum}"
    guest_additions_url    = "${var.ga_source_path}"
    http_directory         = "${path.root}/kickstart"
    hard_drive_interface   = "sata"
    guest_additions_mode   = "upload"
    shutdown_command       = "/bin/systemctl poweroff"
    boot_wait              = "10s"
    ssh_username           = "root"
    ssh_password           = "${var.root_password}"
    ssh_timeout            = "15m"
    ssh_pty                = true
    headless               = true
    usb                    = true
    keep_registered        = "${var.keep_registered}"
    vboxmanage             = [
        [ "modifyvm", "{{ .Name }}", "--rtcuseutc", "on" ],
        [ "modifyvm", "{{ .Name }}", "--nictype1", "virtio" ],
        [ "modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga" ],
        [ "modifyvm", "{{ .Name }}", "--vram", "42" ],
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ],
        [ "setextradata", "{{ .Name }}", "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", "1" ],
    ]
}

build {
    source "virtualbox-iso.centos" {
        name             = "centos7"
        iso_url          = "${var.iso_url_7}"
        iso_checksum     = "${var.iso_checksum_7}"
        vm_name          = "centos7-${local.build_time}"
        output_directory = "${var.packer_out_path}7"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg ",
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
        vm_name          = "centos8-${local.build_time}"
        output_directory = "${var.packer_out_path}8"
        boot_command     = [
            "<up><wait>",
            "<tab><wait>",
            "<bs><bs><bs><bs><bs>",
            "inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg ",
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
        inline = [
            "/usr/bin/yum -y install make gcc bzip2 tar kernel-devel elfutils-libelf-devel",
            "/usr/bin/mount -o loop ${var.ga_upload_path} /mnt",
            "/mnt/VBoxLinuxAdditions.run",
            "/usr/bin/umount /mnt",
            "/usr/bin/rm -vf ${var.ga_upload_path}"
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
        inline = [
            "yum clean all",
            "rm -rf /var/cache/yum",
            "dd if=/dev/zero of=/junk bs=1M || true",
            "rm -f /junk"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/${build.ID}.box"
    }
}
