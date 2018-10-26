pkg_origin=snapp
pkg_name=ssh-exec
pkg_version='13.06'
pkg_maintainer='Christopher A. Snapp'
pkg_description='\
ssh-exec provides a secure method for automating the execution of scripts
on multiple remote hosts.  The automation can be set to either increment
through the list of hosts or run against multiple hosts concurrently.

Other methods exist for running scripts against remote hosts but they tend
to require the installation of a daemon on each remote host (e.g. Func).

By comparison, ssh-exec is a simple wrapper for standard SSH transactions.
This means there are NO server side modifications required and all
automated scripts are tracked the same as if you had logged into each
system and performed the commands manually.
'
pkg_upstream_url='https://github.com/christopher-snapp/ssh-exec'
pkg_license=('gplv3+')
pkg_deps=(
  core/bash
  core/coreutils
  core/expect
  core/which
)
pkg_bin_dirs=(bin)

do_download() {
  return 0
}

do_build() {
  return 0
}

do_install() {
  cp ssh-exec $pkg_prefix/bin
  chmod 755 $pkg_prefix/bin/ssh-exec
  fix_interpreter $pkg_prefix/bin/ssh-exec core/coreutils bin/env
}
