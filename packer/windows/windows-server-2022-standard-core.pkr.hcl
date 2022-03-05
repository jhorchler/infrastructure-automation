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

# only one variable is used to set Windows Administrator Password
variable "winrm_password" {
    description = "Password of Administrator"
    type        = string
    sensitive   = true
}

# data sources
data "git-commit" "cwd-head" { }

// define installation source
source "virtualbox-iso" "win2022stdcore" {

    # general configuration
    chipset              = "ich9"
    firmware             = "efi"
    disk_size            = 71680
    nic_type             = "82545EM"
    gfx_controller       = "vmsvga"
    gfx_vram_size        = 40
    guest_os_type        = "Windows2019_64" # try 2019 as 2022 is not available ...
    hard_drive_interface = "sata"
    sata_port_count      = 5
    iso_interface        = "sata"
    vm_name              = "win2022stdcore-${substr(uuidv4(), 0, 8)}"
    guest_additions_mode = "attach"

    # ISO configuration
    iso_checksum = "sha256:4F1457C4FE14CE48C9B2324924F33CA4F0470475E6DA851B39CCBF98F44E7852"
    iso_url      = "B:/depot/iso/windows-server-2022-eval.iso"

    # cd content configuration
    cd_label = "ANSWERFILE"
    cd_files = [
        "${path.root}/cd/pwsh.msi",                       # new powershell
        "${path.root}/cd/WUA_SearchDownloadInstall.vbs",  # Windows Update Script
        "${path.root}/cd/clear_drive.ps1",                # to delete unneeded data and compact the drive
    ]
    cd_content = {
        "Autounattend.xml" = templatefile("template/server-2022-standard-core.xml", {
            admin_password = "${var.winrm_password}"
        })
    }

    # output configuration
    output_directory = "A:/virtual-disks/win2022stdcore"

    # run configuration
    headless = true

    # shutdown configuration
    shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""

    # hardware configuration
    cpus   = 1
    memory = 8484

    # communication configuration
    communicator   = "winrm"
    winrm_username = "Administrator"
    winrm_password = "${var.winrm_password}"
    winrm_timeout  = "30m"

    # modifyvm
    vboxmanage = [
        [ "modifyvm", "{{.Name}}", "--vrde", "off" ],
    ]

    # boot configuration
    boot_command = [ "<spacebar>" ]
    boot_wait    = "8s"

}

build {

    # only one source available :-)
    sources = [ "virtualbox-iso.win2022stdcore" ]

    # install windows updates
    provisioner "powershell" {
        script = "${path.root}/provisioning/WUA_SearchDownloadInstall.ps1"
    }

    # disable and remove page file
    provisioner "powershell" {
        inline = [
            "Get-CimInstance -ClassName Win32_ComputerSystem | Set-CimInstance -Property @{ AutomaticManagedPageFile = $false }",
            "Get-CimInstance -ClassName Win32_PageFileSetting | Remove-CimInstance"
        ]
    }

    # restart to remove it
    provisioner "windows-restart" {
        restart_timeout = "10m"
    }

    # install Guest Additions
    provisioner "windows-shell" {
        inline = [
            "E:\\cert\\VBoxCertUtil.exe add-trusted-publisher E:\\cert\\vbox-*.cer --root E:\\cert\\vbox-*.cer",
            "E:\\VBoxWindowsAdditions.exe /S"
        ]
    }

    # install new pwsh command
    provisioner "powershell" {
        pause_before = "2m"
        valid_exit_codes = [0, 16001]
        inline = [
            "Start-Process msiexec -ArgumentList '/I F:\\pwsh.msi /passive /norestart REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1' -Wait -NoNewWindow"
        ]
    }

    # disable windows update and cleanup installation image
    provisioner "powershell" {
        inline = [
            "Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\" -Name \"AUOptions\" -Type DWord -Value 1 -Force",
            "Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\" -Name \"NoAutoUpdate\" -Type DWord -Value 1 -Force",
            "Start-Process dism -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup /ResetBase' -Wait -NoNewWindow"
        ]
    }

    # optimize C drive
    provisioner "powershell" {
        inline = [
            "Optimize-Volume -DriveLetter C"
        ]
    }

    # clear drive and expand to maximum as it will be compacted again during export
    provisioner "powershell" {
        inline = [
            "& F:\\clear_drive.ps1"
        ]
    }

    # export as vagrant box
    post-processor "vagrant" {
        keep_input_artifact  = false
        vagrantfile_template = "${path.root}/template/vagrantfile"
        output               = "B:/depot/boxes/${source.type}_${source.name}_${substr(data.git-commit.cwd-head.hash, 0, 8)}.box"
    }

}
