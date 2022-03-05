packer {
    required_version = ">= 1.7.0"
    required_plugins {
        virtualbox = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/virtualbox"
        }
        git = {
            version = ">= 0.3.0"
            source  = "github.com/ethanmdavidson/git"
        }
    }
}

# only two variables are used to set root Password and ssh public key
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

# data sources
data "git-commit" "cwd-head" { }

# define installation source
source "virtualbox-iso" "opensuse15" {

    # general configuration
    chipset              = "ich9"
    firmware             = "efi"
    rtc_time_base        = "UTC"
    disk_size            = 81920
    nic_type             = "virtio"
    gfx_controller       = "vmsvga"
    gfx_vram_size        = 40
    guest_os_type        = "OpenSUSE_64"
    hard_drive_interface = "sata"
    sata_port_count      = 5
    iso_interface        = "sata"
    disk_additional_size = [71680]
    vm_name              = "opensuse-${substr(uuidv4(), 0, 8)}"
    guest_additions_mode = "disable"

    # ISO configuration
    iso_checksum = "sha256:40DA6B6FD17F552CD5AA3526D1A5EE091A948C8890CA70D03C9F3F8CAA2E0876"
    iso_url      = "B:/depot/iso/openSUSE-15.iso"

    # Http directory configuration
    http_content = {
        "/autoinst.xml" = templatefile("template/autoyast.xml", {
            user_password = "${var.root_password}",
            tmpsize       = "1024m"
        })
    }

    # output configuration
    output_directory = "A:/virtual-disks/opensuse"

    # run configuration
    headless = true

    # shutdown configuration
    shutdown_command = "/usr/bin/systemctl poweroff"

    # hardware configuration
    cpus   = 1
    memory = 8484

    # communicator configuration
    ssh_username            = "root"
    ssh_password            = "${var.root_password}"
    ssh_timeout             = "25m"
    ssh_pty                 = true
    pause_before_connecting = "1m"

    # modifyvm
    vboxmanage = [
        [ "modifyvm", "{{.Name}}", "--vrde", "off" ],
    ]

    # boot configuration
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
        "install=https://rsync.opensuse.org/distribution/leap/15.3/repo/oss/ ",
        "autoyast=http://{{.HTTPIP}}:{{.HTTPPort}}/autoinst.xml ",
        "<f10><wait>"
    ]

}

build {

    # only one source is defined
    sources = ["virtualbox-iso.opensuse15"]

    # load vbox modules at next startup
    provisioner "shell" {
        expect_disconnect = true
        inline = [
            "set -x",
            "echo 'allow_unsupported_modules 1' > /etc/modprobe.d/10-unsupported-modules.conf",
            "printf '%s\n%s\n%s\n%s\n' vboxdrv vboxnetadp vboxnetflt vboxsf > /etc/modules-load.d/vbox-guest-additions.conf",
            "systemctl reboot"
        ]
    }

    # install pwsh prereq: .NET
    provisioner "shell" {
        pause_before = "1m"
        inline = [
            "set -x",
            "zypper --no-color --non-interactive install --allow-unsigned-rpm https://packages.microsoft.com/opensuse/15/prod/packages-microsoft-prod.rpm",
            "ln -s /etc/yum.repos.d/microsoft-prod.repo /etc/zypp/repos.d/microsoft-prod.repo",
            "zypper --no-color --non-interactive modifyrepo --refresh packages-microsoft-com-prod",
            "zypper --no-color --non-interactive --gpg-auto-import-keys install dotnet-sdk-6.0"
        ]
    }

    # install pwsh / https://docs.microsoft.com/de-de/powershell/scripting/install/install-other-linux?view=powershell-7.2
    provisioner "shell" {
        inline = [
            "set -x",
            "dotnet tool install --global PowerShell"
        ]
    }

    # install ssh public key and cleanup
    provisioner "shell" {
        inline = [
            "set -x",
            "install -v -m 0700 -d ~/.ssh",
            "touch ~/.ssh/authorized_keys",
            "chmod 0600 ~/.ssh/authorized_keys",
            "echo 'ssh-ed25519 ${var.ssh_ed25519_key} jhorchler' > ~/.ssh/authorized_keys",
        ]
    }

    # cleanup and fill up file space for compression later during export
    provisioner "shell" {
        inline = [
            "set -x",
            "zypper clean --all",
            "rm -vf /var/lib/wicked/*",
            "rm -vf /etc/udev/rules.d/70-persistent-net.rules",
            "sed -i /HWADDR/d /etc/sysconfig/network/ifcfg-eth0",
            "findmnt --output=target --real --list --noheadings | while read TARGET; do dd if=/dev/zero of=$TARGET/junk bs=1M status=none || rm -vf $TARGET/junk; done",
        ]
    }

    # export as vagrant box
    post-processor "vagrant" {
        keep_input_artifact  = false
        vagrantfile_template = "${path.root}/template/vagrantfile"
        output               = "B:/depot/boxes/${source.type}_${source.name}_${substr(data.git-commit.cwd-head.hash, 0, 8)}.box"
    }

}
