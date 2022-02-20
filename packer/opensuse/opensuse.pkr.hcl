packer {
    required_version = ">= 1.7.0"
    required_plugins {
        hyperv = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/hyperv"
        }
        git = {
            version = ">= 0.3.0"
            source  = "github.com/ethanmdavidson/git"
        }
    }
}

// only two variables are used to set root Password and ssh public key
variable "root_password" {
    description = "Password of root"
    type        = string
    sensitive   = true
}

variable "ssh_ed25519_key" {
    description = "SSH Public ed25519 Key"
    type        = string
    sensitive   = true
}


// locals
locals {
    // the first 8 chars of the HEAD commit will be used in box file name
    truncated_sha        = substr(data.git-commit.cwd-head.hash, 0, 8)
    hyperv_output        = "A:/hyper-v-root/opensuse"
    box_output           = "B:/depot/boxes"
    iso_url              = "B:/depot/iso/openSUSE-15.iso"
    iso_checksum         = "sha256:40DA6B6FD17F552CD5AA3526D1A5EE091A948C8890CA70D03C9F3F8CAA2E0876"
    install_mirror       = "https://rsync.opensuse.org/distribution/leap/15.3/repo/oss/"
    ay_templatefile      = "template/autoyast.xml"
    vagrantfile_template = "template/vagrantfile"
    switch_name          = "iacswitch"
    disk_size            = 81920
    second_disk_size     = 71680
    memory               = 8484
    tmp_size             = 1024
    cpus                 = 4
}

// data sources
data "git-commit" "cwd-head" { }

// define installation source
source "hyperv-iso" "opensuse15" {

    // source ISO file
    iso_checksum = "${local.iso_checksum}"
    iso_url      = "${local.iso_url}"

    // general builder configuration
    output_directory      = "${local.hyperv_output}"
    disk_size             = local.disk_size  # MB
    disk_additional_size  = [local.second_disk_size] # MB
    disk_block_size       = 1                # MB (1 MiB recommended for Linux)
    memory                = local.memory     # MB
    guest_additions_mode  = "none" # Integration services are built-in OpenSUSE
    vm_name               = "${uuidv4()}"
    switch_name           = "${local.switch_name}"
    cpus                  = local.cpus
    generation            = 2
    enable_secure_boot    = true
    secure_boot_template  = "MicrosoftUEFICertificateAuthority"
    enable_dynamic_memory = true

    // autoinst settings
    http_content = {
        "/autoinst.xml" = templatefile("${local.ay_templatefile}", {
            user_password = "${var.root_password}",
            tmpsize       = "${local.tmp_size}"
        })
    }

    // how to shutdown the machine
    shutdown_command      = "/usr/bin/systemctl poweroff"

    // how to boot the machine
    boot_command     = [
        "<esc>",
        "e",
        "<down><down><down><down>",
        "<end>",
        " biosdevname=0 ",
        "net.ifnames=0 ",
        "netdevice=eth0 ",
        "netsetup=dhcp ",
        "lang=en_US ",
        "textmode=1 ",
        "self_update=1 ",
        "install=${local.install_mirror} ",
        "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
        "<f10><wait>"
    ]

    // connector settings
    ssh_username            = "root"
    ssh_password            = "${var.root_password}"
    ssh_timeout             = "15m"
    ssh_pty                 = true
    pause_before_connecting = "3m"

}

build {

    // only one source is defined
    sources = ["hyperv-iso.opensuse15"]

    // online update
    provisioner "shell" {
        expect_disconnect = true
        inline = [
            "zypper --no-color --non-interactive update",
            "systemctl reboot"
        ]
    }

    // install ssh public key and cleanup
    provisioner "shell" {
        pause_before = "1m"
        inline = [
            "set -x",
            "install -v -m 0700 -d ~/.ssh",
            "touch ~/.ssh/authorized_keys",
            "chmod 0600 ~/.ssh/authorized_keys",
            "echo 'ssh-ed25519 ${var.ssh_ed25519_key} jhorchler' > ~/.ssh/authorized_keys",
            "zypper clean --all",
            "rm -vf /var/lib/wicked/*",
            "rm -vf /etc/udev/rules.d/70-persistent-net.rules",
            "sed -i /HWADDR/d /etc/sysconfig/network/ifcfg-eth0",
            "dd if=/dev/zero of=/junk bs=1M || true",
            "rm -f /junk"
        ]
    }

    // export as vagrant box
    post-processor "vagrant" {
        keep_input_artifact  = false
        vagrantfile_template = "${path.root}/${local.vagrantfile_template}"
        output               = "${local.box_output}/${source.type}_${source.name}_${local.truncated_sha}.box"
    }

}
