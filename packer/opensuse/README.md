# OpenSUSE build

## Usage

OpenSUSE 42 lacks the possibility to inject the root password to use via boot
parameters. Therefore I decided to create a autoyast template `ay-template.xml`
which contains *HCL variables* for `user_password` of `root` and `boot-device`
for the disk to use.

`boot-device` is needed as `qemu` provides `vda` instead of `sda` for the first
disk.

This template is parsed and the variables replaced by the HCL function
`templatefile` in combination with `http_content` that is provided by `packer`.
This generates the autoyast profile on the fly when `HTTP GET` is used by
autoyast to retrieve the profile.
