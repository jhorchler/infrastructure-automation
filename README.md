# Infrastructure as Code

My research about infrastructure automation with [packer](https://www.packer.io/),
vagrant, terraform etc.

## Packer builds

Inside `packer` I store three subdirectories named

- **centos**: Code to create Vagrant base boxes using CentOS 7 and 8.
- **opensuse**: Code to create Vagrant base boxes using openSUSE 42 or 15.
- **windows**: Code to create Vagrant base boxes using Windows Server 2019 or 2012 R2.

I created these instead of using the great builds already existing (for example
[chef/bento](https://github.com/chef/bento/tree/master/packer_templates)) because
I wanted to learn how `packer` works.

**Note**: I'm already using HCL for these builds. Hence, packer of version _1.7_
is needed.

These builds are only installing a minimal set of software and only add the
VirtualBox guest additions. The user used inside the VM is always `root`, and
`Administrator` respectively.

### Packer builder used

As packer can use many builders and and can build all builds in parallel I would
be able to create all artifacts from one build definition. I decided not to do
that for several reasons.

First I used Hyper-V and Docker for my builds. But I had problems with corrupted
files that were downloaded inside the VMs (for example when running
`yum install some_package`). I needed to disable some Windows Components, and to
remove Docker.

As I mainly use [VirtualBox](https://www.virtualbox.org/) anyway for automated
[Vagrant](https://www.vagrantup.com/) boxes, I'm using these now and now only
use the "virtualbox-iso" builder.

Finally to have cleaner build definitions, I decided to split the builds by
operating system.

### Usage

Just clone the repository, install packer and VirtualBox and create a
`*.auto.pkrvars.hcl` file that sets all variables defined in `variables.pkr.hcl`
without defaults for each subdirectory.

### OS Versiones

I'm creating two versions per OS as I want to use these for automatic builds
of these Oracle products:

- Oracle Database 11.2.0.4 / 12.1.0.2 / 19c
- Oracle Clusterware 11.2.0.4 / 12.1.0.2 / 19c
- Oracle Database Client 11.2.0.4 / 12.1.0.2 / 19c

These versions are used as MOS Note 742060.1 shows that

- for 11.2.0.4 Market Driven Support might be bought until end of 2022,
- for 12.1.0.2 Extended Support ends mid of 2022,
- Oracle 19c is the long term Release,
- 12.2 is not in focus as only limited error correction policy applies and
- 18c is not getting any support from mid of 2021 anymore.

As seen in below certified versions the older version of each OS is needed for
all three products (CentOS 7, openSUSE 42, Windows Server 2012 R2).

The newer version is used for tests with Oracle 19c only.

#### Oracle Certified SLES Versions

- 11.2.0.4: SLES 10 / SLES 11 / SLES 12 SP1+
- 12.1.0.2: SLES 11 SP2+ / SLES 12 SP1+
- 12.2.0.1: SLES 12 SP1+ / SLES 15
- 18.0.0.0: SLES 12 SP1+
- 19.0.0.0: SLES 12 SP3+ / SLES 15

#### Oracle Certified RHEL Versions

- 11.2.0.4: RHEL 4 / RHEL 5 / RHEL 6 / RHEL 7
- 12.1.0.2: RHEL 5 U6+ / RHEL 6 / RHEL 7 / RHEL 8 U1+
- 12.2.0.1: RHEL 6 U4+ / RHEL 7
- 18.0.0.0: RHEL 6 U4+ / RHEL 7
- 19.0.0.0: RHEL 7 U5+ / RHEL 8

#### Oracle Certified OL Versions

- 11.2.0.4: OL 4 / OL 5 / OL 6 / OL 7
- 12.1.0.2: OL 5 U6+ / OL 6 / OL 7 / OL 8 U1+
- 12.2.0.1: OL 6 U4+ / OL 7
- 18.0.0.0: OL 6 U4+ / OL 7
- 19.0.0.0: OL 7 U4+ / OL 8 U1+
