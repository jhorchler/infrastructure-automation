# OpenSUSE build

## Usage

OpenSUSE 42 lacks the possibility to inject the root password to use via boot
parameters. Therefore I decided to create a autoyast template `ay-template.xml`
which contains `@@USER_PASSWORD@@` as value for `user_password` of `root`.

To create two autoyast profiles I use [Task](https://taskfile.dev/) as replacement
of `make` on Windows. Inside `Taskfile.yml` all OS-Tasks are sourced from
`Taskfile_windows.yml`. The only currently existing task here is to generate
the profiles using Powershell Core.

For Linux and MacOS you need to create `Taskfile_linux.yml` or `Taskfile_darwin.yml`
providing a similar task (e.g. using cat and sed). Using a different task
executor like `make` or `tup` etc. will work as well.

That way the variables `http_directory`, `autoyast_15` and `autoyast_42` are
set via the command line when executing packer.

`task` must then be executed inside `<repo-root>/packer/opensuse` to work.
