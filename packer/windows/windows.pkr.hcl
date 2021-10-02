packer {
    required_version = ">= 1.7.5"
    required_plugins {
        qemu = {
            version = ">= 1.0.1"
            source = "github.com/hashicorp/qemu"
        }
    }
}

source "virtualbox-iso" "windows" {
    chipset                 = "${var.chipset}"
    nic_type                = "${var.nic_type}"
    vm_name                 = "${var.vm_name}"
    iso_url                 = "${var.iso_url}"
    iso_checksum            = "${var.iso_checksum}"
    output_directory        = "${var.output_directory}/${var.os_version}"
    disk_size               = "${var.disk_size}"
    cpus                    = "${var.cpu_count}"
    memory                  = "${var.mem_size}"
    guest_os_type           = "${var.guest_os_type}"
    keep_registered         = "${var.keep_registered}"
    winrm_password          = "${var.winrm_password}"
    gfx_controller          = "${var.gfx_controller}"
    gfx_vram_size           = 128
    communicator            = "winrm"
    winrm_timeout           = "12h"
    winrm_username          = "Administrator"
    hard_drive_interface    = "sata"
    iso_interface           = "sata"
    guest_additions_mode    = "attach"
    boot_wait               = "6s"
    shutdown_command        = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    shutdown_timeout        = "15m"
    cd_label                = "ANSWERFILE"
    headless                = true
    usb                     = true
    cd_files                = [
        "cdrom/PowerShell.msi",
        "cdrom/WUA_SearchDownloadInstall.vbs",
        "cdrom/clear_drive.ps1",
        "${var.virtio_driver_files}"
    ]
    cd_content              = {
        "autounattend.xml" = templatefile("${path.root}/${var.unattended_directory}/${var.unattended_template}", {
            admin_password = "${var.winrm_password}",
            image_name     = "${var.image_name}",
            driver_path    = "${var.driver_path}"
        })
    }
    boot_command            = [
        "<spacebar>"
    ]
    vboxmanage              = [
        [ "modifyvm", "{{ .Name }}", "--firmware", "efi" ],
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ]
    ]
}

source "qemu" "windows" {
    vm_name             = "${var.vm_name}"
    iso_url             = "${var.iso_url}"
    iso_checksum        = "${var.iso_checksum}"
    output_directory    = "${var.output_directory}/${var.os_version}"
    accelerator         = "${var.qemu_accel}"
    disk_interface      = "${var.qemu_disk_if}"
    machine_type        = "${var.qemu_machine_type}"
    firmware            = "${var.qemu_uefi_firmware}"
    cpus                = "${var.cpu_count}"
    memory              = "${var.mem_size}"
    disk_size           = "${var.disk_size}"
    winrm_password      = "${var.winrm_password}"
    shutdown_command    = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    shutdown_timeout    = "15m"
    boot_wait           = "2s"
    communicator        = "winrm"
    winrm_timeout       = "12h"
    winrm_username      = "Administrator"
    headless            = true
    cdrom_interface     = "ide"
    cd_label            = "ANSWERFILE"
    cd_files            = [
        "cdrom/PowerShell.msi",
        "cdrom/WUA_SearchDownloadInstall.vbs",
        "cdrom/clear_drive.ps1",
        "${var.virtio_driver_files}"
    ]
    cd_content          = {
        "autounattend.xml" = templatefile("${path.root}/${var.unattended_directory}/${var.unattended_template}", {
            admin_password = "${var.winrm_password}",
            image_name     = "${var.image_name}",
            driver_path    = "${var.driver_path}"
        })
    }
    boot_command            = [
        "<spacebar>"
    ]
}

build {

    sources = [ "virtualbox-iso.windows" , "qemu.windows"]

    provisioner "powershell" {
        script = "cdrom/WUA_SearchDownloadInstall.ps1"
    }

    provisioner "powershell" {
        inline = [
            "Set-PSDebug -Trace 1",
            "Get-CimInstance -ClassName Win32_ComputerSystem | Set-CimInstance -Property @{ AutomaticManagedPageFile = $false }",
            "Get-CimInstance -ClassName Win32_PageFileSetting | Remove-CimInstance"
        ]
    }

    provisioner "windows-restart" {
        restart_timeout = "10m"
    }

    provisioner "powershell" {
        inline = [
            "Set-PSDebug -Trace 1",
            "Start-Process msiexec -ArgumentList '/I E:\\PowerShell.msi /passive /norestart REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1' -Wait -NoNewWindow"
        ]
        valid_exit_codes = [0, 16001]
        pause_before = "5m"
    }

    provisioner "windows-shell" {
        only = [ "virtualbox-iso.windows" ]
        inline = [
            "D:\\cert\\VBoxCertUtil.exe add-trusted-publisher D:\\cert\\vbox-*.cer --root D:\\cert\\vbox-*.cer",
            "D:\\VBoxWindowsAdditions.exe /S"
        ]
    }

    provisioner "windows-shell" {
        inline = [
            "reg add HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU /v AUOptions /t REG_DWORD /d 1 /f",
            "reg add HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f",
            "dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase"
        ]
    }

    provisioner "powershell" {
        inline = [
            "Optimize-Volume -DriveLetter C",
            "& E:\\clear_drive.ps1"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/{{.Provider}}-${var.os_version}.box"
    }
}
