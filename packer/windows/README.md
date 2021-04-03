# Windows Build

These files create a minimal Windows Server box for Windows Server 2019
Datacenter Core or 2012 R2 Standard Core.

> **NOTE:**
> This build can not build multiple machines in one call. For that run `task`
> several times in parallel in different shell sessions.

## Prerequisites and Usage

For this build the evaluation iso from Microsoft is used. To use this project

- clone it
- download [Windos Server Evaluation](https://www.microsoft.com/en-us/evalcenter/)
- install/download [packer](https://www.packer.io/)
- install/download [Task](https://taskfile.dev)
- install [VirtualBox](https://www.virtualbox.org/)
- download [PowerShell Core](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7) and put as PowerShell.msi in `shell` subfolder
- to build the CD containing the answer file (Floppy is not available in UEFI mode) install a CD build tool and ensure that it is included in your path
  - [xorriso](https://www.gnu.org/software/xorriso/)
  - [mkisofs](https://mkisofs.updatestar.com/de)
  - [oscdimg](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- create an variables file, for example `windows.auto.pkrvars.hcl` containing all vars in `variables.pkr.hcl`
- change directory to `<repo-root>/packer/windows`
- run `task` for Windows Server 2019 Datacenter Core (the default) or `task OSVERSION=2012R2-standard-core` for 2012 R2 Standard Core

> **ATTENTION:**
> Task uses powershell to inject the Administrator password into the Autounattended.xml file.
> This command is shown on stdout. If this is a security problem use `task -s` to hide the command.

As with the OpenSUSE build, Windows needs the password of `Administrator` (or any other user) within
the `Autounattend.xml` file. To inject this into the file, a template `template.xml` is used to
generate `Autoattend.xml` using  `Task`.

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
