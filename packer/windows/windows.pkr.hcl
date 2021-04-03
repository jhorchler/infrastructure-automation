packer {
    required_version = ">= 1.7.0"
}

source "virtualbox-iso" "windows" {
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
    communicator            = "winrm"
    winrm_timeout           = "12h"
    winrm_username          = "Administrator"
    hard_drive_interface    = "sata"
    iso_interface           = "sata"
    guest_additions_mode    = "attach"
    boot_wait               = "6s"
    shutdown_command        = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    shutdown_timeout        = "15m"
    cd_label                = "answerfile"
    headless                = false
    usb                     = true
    cd_files                = [
        "${var.answer_file}",
        "cdrom/PowerShell.msi",
        "cdrom/WUA_SearchDownloadInstall.vbs",
        "cdrom/clear_drive.ps1"
    ]
    boot_command            = [
        "<spacebar>"
    ]
    vboxmanage              = [
        [ "modifyvm", "{{ .Name }}", "--vram", "128" ],
        [ "modifyvm", "{{ .Name }}", "--graphicscontroller", "vboxsvga" ],
        [ "modifyvm", "{{ .Name }}", "--nictype1", "virtio" ],
        [ "modifyvm", "{{ .Name }}", "--firmware", "efi" ],
        [ "modifyvm", "{{ .Name }}", "--paravirtprovider", "${var.paravirtprovider}" ],
        [ "storageattach", "{{ .Name }}", "--storagectl" , "SATA Controller", "--port", "4", "--type", "dvddrive", "--medium", "${var.virtio_driver_disk}" ]
    ]
}

build {

    name = "windows"
    sources = [ "virtualbox-iso.windows" ]

    provisioner "powershell" {
        script = "cdrom\\WUA_SearchDownloadInstall.ps1"
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
            "Start-Process msiexec -ArgumentList '/I F:\\PowerShell.msi /passive /norestart REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1' -Wait -NoNewWindow"
        ]
        valid_exit_codes = [0, 16001]
    }

    provisioner "windows-shell" {
        only = [ "virtualbox-iso.windows" ]
        inline = [
            "E:\\cert\\VBoxCertUtil.exe add-trusted-publisher E:\\cert\\vbox-*.cer --root E:\\cert\\vbox-*.cer",
            "E:\\VBoxWindowsAdditions.exe /S"
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
            "& F:\\clear_drive.ps1"
        ]
    }

    post-processor "vagrant" {
        keep_input_artifact = false
        output              = "${var.box_directory}/${build.ID}-${var.os_version}.box"
    }
}
