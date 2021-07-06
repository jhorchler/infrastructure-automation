# CentOS build

## Usage

Just clone the repository, install packer and (VirtualBox or QEMU) and create a
`*.auto.pkrvars.hcl` file that sets all variables defined in `variables.pkr.hcl`.

From root of the repository run `cd packer` and `packer build centos`. This will
build all artifacts for VirtualBox and QEMU by default. To build a specific
version run for example `packer build -only=qemu.centos8 centos` for CentOS 8
build using QEMU.

## Kickstart

As the options between CentOS 7 and 8 are a bit different these options are
injected via `/proc/cmdline` that is parsed in the `%pre`-script:

- `inst_repo` is set in the variables to the online repository to fetch sources from
- `ssh_password` is the root password to set
- `os_version` is set to `7` or `8` to easily change the options that are different between these versions
  - `install` is not used in `8`
  - `text` has the additional switch `--non-interactive` in `8`
  - `authconfig` is replaced by `authselect` in `8`
  - `%packages` included `--excludeWeakdeps` to make the build even smaller

Setting `os_version` is not really needed. There are different other possible
methods to determine whether this is `7` or `8 `, like parsing the URL of the
installation source. But that way it's - IMO - the most easy method.

> ATTENTION: Ensure that the kickstart file has UNIX line endings (LF).
