variable "unattended_template" {
    description = "Name of the template used to generate Autounattended.xml"
    type        = string
}

variable "unattended_directory" {
    description = "Path to template file used to generate Autounattended.xml"
    type        = string
}

variable "cpu_count" {
    description = "Number of CPUs to assign."
    type        = number
    default     = 2
}

variable "disk_size" {
    description = "Disk size of the initial os-disk."
    type        = number
    default     = 71680
}

variable "guest_os_type" {
    description = "Type of Guest OS. Use 'vboxmanage list ostypes' to see possible values."
    type        = string
}


variable "iso_checksum" {
    description = "Checksum of the installation iso."
    type        = string
}

variable "iso_url" {
    description = "URL to the ISO file to install Windows from."
    type        = string
}

variable "keep_registered" {
    description = "Should the source vm stay registered in VirtualBox after completed build."
    type        = bool
}

variable "mem_size" {
    description = "Size of RAM to assign."
    type        = number
    default     = 4242
}

variable "os_version" {
    description = "Short Name of the Server image used to generate the output path."
    type        = string
}

variable "image_name" {
    description = "Name of the Server image (see README)"
    type        = string
}

variable "output_directory" {
    description = "Path to the directory in which the VM will be created."
    type        = string
}

variable "paravirtprovider" {
    description = "Paravirtualization Provider used by VirtualBox. Use 'vboxmanage mofivyvm' to see possible values."
    type        = string
    default     = "hyperv"
}

variable "virtio_driver_disk" {
    description = "Full path to the VIRTIO iso that contains network drivers for virtio."
    type        = string
}

variable "driver_path" {
    description = "Directory on the VIRTIO disk where to find the drivers. Must be injected into template.xml"
}

variable "box_directory" {
    description = "Path to the directory the vagrant boxes are exported to."
    type        = string
}

variable "vm_name" {
    description = "Name of the VM to create in VirtualBox."
    type        = string
}

variable "winrm_password" {
    description = "Password of the Administrator."
    type        = string
    sensitive   = true
}

variable "gfx_controller" {
    description = "The graphics controller type to be used."
    type        = string
}

variable "chipset" {
    description = "The chipset to be used: PIIX3 or ICH9."
    type        = string
}

variable "nic_type" {
    description = "The driver to use for the network interface."
    type        = string
}

variable "qemu_accel" {
    description = "Accelerator used for qemu."
    type        = string
}

variable "qemu_disk_if" {
    description = "This option defines on which type on interface the drive is connected."
    type        = string
    default     = "ide"
}

variable "qemu_machine_type" {
    description = "The type of machine emulation to use."
    type        = string
}

variable "qemu_uefi_firmware" {
    description = "The UEFI firmware file to use."
    type        = string
}

variable "virtio_driver_files" {
    description = "Path to contents of the virtio NetKVM files"
    type        = string
}
