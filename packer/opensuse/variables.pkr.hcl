variable "chipset" {
    description = "The chipset to be used: PIIX3 or ICH9."
    type        = string
}

variable "nic_type" {
    description = "The driver to use for the network interface."
    type        = string
}

variable "box_directory" {
    description = "Path to the directory the vagrant boxes are exported to."
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
    default     = "RedHat_64"
}

variable "install_mirror_15" {
    description = "URL to the OpenSUSE 15 installation mirror if network based installation is used."
    type        = string
}

variable "install_mirror_42" {
    description = "URL to the OpenSUSE 42 installation mirror if network based installation is used."
    type        = string
}

variable "iso_checksum_15" {
    description = "Checksum of the OpenSUSE 15 installation iso."
    type        = string
}

variable "iso_checksum_42" {
    description = "Checksum of the OpenSUSE 42 installation iso."
    type        = string
}

variable "iso_url_15" {
    description = "URL to the ISO file to install OpenSUSE 15 from."
    type        = string
}

variable "iso_url_42" {
    description = "URL to the ISO file to install OpenSUSE 42 from."
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

variable "packer_out_path" {
    description = "Output directory of packer. Must not exist and will be empty after build."
    type        = string
}

variable "paravirtprovider" {
    description = "Paravirtualization Provider used by VirtualBox. Use 'vboxmanage mofivyvm' to see possible values."
    type        = string
    default     = "hyperv"
}

variable "root_password" {
    description = "Password of the root-User. Is set during kickstart installation."
    type        = string
    sensitive   = true
}

variable "user_ssh_key" {
    description = "Name of the ssh key file (public) appended to ~/.ssh/authorized_keys of root user"
    type        = string
}

variable "http_directory" {
    description = "Directory where autoyast profile and ssh-key are stored."
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

variable "gfx_controller" {
    description = "The graphics controller type to be used."
    type        = string
}

variable "autoyast_template" {
    description = "The template autoyast file which is used."
    type        = string
}
