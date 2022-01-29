packer {
    required_version = ">= 1.7.0"
    required_plugins {
        hyperv = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/hyperv"
        }
    }
}

// only one variable is used to set Windows Administrator Password
variable "winrm_password" {
    description = "Password of Administrator"
    type        = string
    sensitive   = true
}

// define installation source
source "hyperv-iso" "win2022stdcore" {

    // source ISO file
    iso_checksum = "sha256:4F1457C4FE14CE48C9B2324924F33CA4F0470475E6DA851B39CCBF98F44E7852"
    iso_url      = "B:/depot/iso/windows-server-2022-eval.iso"

    // general builder configuration
    output_directory     = "A:/hyper-v-root/packer-win2022stdcore"
    disk_size            = 71680  # MB
    memory               = 8484   # MB
    guest_additions_mode = "none" # Integration services are built-in Windows Server 2022
    vm_name              = "win2022base"
    switch_name          = "ExtPacker"
    cpus                 = 4
    generation           = 2
    enable_secure_boot   = true

    // how to shutdown the machine
    shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    shutdown_timeout = "15m"

    // CD containing autounattend.xml , scripts and powershell msi file
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

    // how to connect to the VM - it's Windows .. hence, use WINRM
    communicator   = "winrm"
    winrm_username = "Administrator"
    winrm_password = "${var.winrm_password}"
    winrm_timeout  = "1h" # gives enough time for unattended installation to finish

    // boot configuration
    boot_command = [ "<spacebar>" ]
    boot_wait    = "2s"
}

// build the machine
build {

    // only one source available :-)
    sources = [ "hyperv-iso.win2022stdcore" ]

    // install windows updates
    provisioner "powershell" {
        script = "${path.root}/provisioning/WUA_SearchDownloadInstall.ps1"
    }

    // disable and remove page file
    provisioner "powershell" {
        inline = [
            "Get-CimInstance -ClassName Win32_ComputerSystem | Set-CimInstance -Property @{ AutomaticManagedPageFile = $false }",
            "Get-CimInstance -ClassName Win32_PageFileSetting | Remove-CimInstance"
        ]
    }
    // restart to remove it
    provisioner "windows-restart" {
        restart_timeout = "10m"
    }

    // install new pwsh command
    provisioner "powershell" {
        pause_before = "5m"
        valid_exit_codes = [0, 16001]
        inline = [
            "Start-Process msiexec -ArgumentList '/I E:\\pwsh.msi /passive /norestart REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1' -Wait -NoNewWindow"
        ]
    }

    // disable windows update and cleanup installation image
    provisioner "powershell" {
        inline = [
            "Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\" -Name \"AUOptions\" -Type DWord -Value 1 -Force",
            "Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\" -Name \"NoAutoUpdate\" -Type DWord -Value 1 -Force",
            "Start-Process dism -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup /ResetBase' -Wait -NoNewWindow"
        ]
    }

    // optimize C drive
    provisioner "powershell" {
        inline = [
            "Optimize-Volume -DriveLetter C"
        ]
    }

    // clear drive and expand to maximum as it will be compacted again during export
    provisioner "powershell" {
        inline = [
            "& E:\\clear_drive.ps1"
        ]
    }

    // export as vagrant box
    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "B:/depot/${source.type}_win2022stdcore.box"
    }


}
