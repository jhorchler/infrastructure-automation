variable "mem_size" {
    description = "Size of RAM to assign."
    type        = number
    default     = 4242
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

variable "ga_upload_path" {
    description = "Upload path of Guest Additions ISO."
    type        = string
    default     = "/tmp/guest_additions.iso"
}

variable "ga_sha256sum" {
    description = "SHA256 checksum of local Guest Additions ISO."
    type        = string
}

variable "ga_source_path" {
    description = "Path to local Guest Additions ISO."
    type        = string
}

variable "guest_os_type" {
    description = "Type of Guest OS. Use 'vboxmanage list ostypes' to see possible values."
    type        = string
    default     = "RedHat_64"
}

variable "iso_url_7" {
    description = "URL to the ISO file to install Centos7 from."
    type        = string
}

variable "iso_url_8" {
    description = "URL to the ISO file to install Centos8 from."
    type        = string
}

variable "iso_checksum_7" {
    description = "Checksum of the Centos7 installation iso."
    type        = string
}

variable "iso_checksum_8" {
    description = "Checksum of the Centos8 installation iso."
    type        = string
}

variable "install_mirror_7" {
    description = "URL to the Centos7 installation mirror if network based installation is used."
    type        = string
}

variable "install_mirror_8" {
    description = "URL to the Centos8 installation mirror if network based installation is used."
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

variable "packer_out_path" {
    description = "Output directory of packer. Must not exist and will be empty after build."
    type        = string
}

variable "box_directory" {
    description = "Path to the directory the vagrant boxes are exported to."
    type        = string
}

variable "user_ssh_key" {
    description = "Name of the ssh key file (public) appended to ~/.ssh/authorized_keys of root user"
    type        = string
}

variable "keep_registered" {
    description = "Should the source vm stay registered in VirtualBox after completed build."
    type        = bool
}
