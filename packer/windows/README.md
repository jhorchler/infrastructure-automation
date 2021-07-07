# Windows Build

These files create a minimal Windows Server box for Windows Server 2019
Datacenter Core or 2012 R2 Standard Core.

> **NOTE:**
> This build can not build multiple machines in one call. For that run `packer`
> several times in parallel in different shell sessions using the different
> OS version variables files. See below for instructions.

## Prerequisites and Usage

For this build the evaluation iso from Microsoft is used. To use this project

- clone it
- download [Windos Server Evaluation](https://www.microsoft.com/en-us/evalcenter/)
- install/download [packer](https://www.packer.io/)
- install [VirtualBox](https://www.virtualbox.org/) and/or
- install [QEMU](https://www.qemu.org/)
- download [PowerShell Core](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7) and put as PowerShell.msi in `shell` subfolder
- to build the CD containing the answer file (Floppy is not available in UEFI mode) install a CD build tool and ensure that it is included in your path
  - [xorriso](https://www.gnu.org/software/xorriso/)
  - [mkisofs](https://mkisofs.updatestar.com/de)
  - [oscdimg](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- create an variables file, for example `windows.auto.pkrvars.hcl` containing all vars in `variables.pkr.hcl`
- change directory to `<repo-root>/packer/windows`
- run `packer build .`

As with the OpenSUSE build, Windows needs the password of `Administrator` (or any other user) within
the `Autounattend.xml` file. To inject this into the file, a template `template.xml` is used to
generate `Autoattend.xml` using the HCL function `templatefile` to parse `template.xml` to
replace the variables

- admin_password
- image_name
- driver_path

as these are different between OS versions.

A different approach would be (like I do) to create one global variable file
(for example `windows.auto.pkrvars.hcl`) that contains all OS version independable variables:

- vm_name
- virtio_driver_disk
- output_directory
- box_directory
- winrm_password
- keep_registered
- chipset
- nic_type
- gfx_controller
- qemu_accel
- qemu_disk_if
- qemu_machine_type
- qemu_uefi_firmware
- unattended_directory
- unattended_template

and then one variable file for each image used (see below). For example `2019-datacenter-core.pkrvars.hcl`
containing the os dependant variables:

- iso_url
- iso_checksum
- guest_os_type
- image_name
- os_version
- driver_path

Then run `packer build -var-file=2019-datacenter-core.pkrvars.hcl .`. Then variables needed are
provided by `windows.auto.pkrvars.hcl` and `2019-datacenter-core.pkrvars.hcl`. For multiple builds
then each build must be executed in a separate command line session.

> **NOTE:**
> The template in this repo is installing Windows without GUI. The template _should_ work for
> other versions of 2019 or 2012 R2 but I only tried the versions mentioned above.

## Windows Server Editions

The evaluation discs of 2012 R2 and 2019 contain these editions:

- Windows Server 2019 SERVERDATACENTER
- Windows Server 2019 SERVERDATACENTERCORE
- Windows Server 2019 SERVERSTANDARD
- Windows Server 2019 SERVERSTANDARDCORE

or

- Windows Server 2012 R2 SERVERSTANDARDCORE
- Windows Server 2012 R2 SERVERSTANDARD
- Windows Server 2012 R2 SERVERDATACENTERCORE
- Windows Server 2012 R2 SERVERDATACENTER

Use one of these as `image_name`.
