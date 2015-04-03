# Snaphost

Snaphost is a bare bones script used for Puppet development in cases where reverting a system by removing packages and files is sufficient. I find it useful for quick, incremental development on systems where simply deleting files and removing packages is enough to bring it back to a reasonably clean state. It's not intended to replace true a true testing framework. For that, use rspec and Beaker.

## Usage

    snaphost.sh remove -h [hosts...,] -d [directories...,] -p [packages...,]

Remove given packages and directories on each host. You can list any amount of hosts to operate on. Assumes password-less ssh access and sudo as root access without a tty, e.g. uses `ssh -t`.

Multiple items of each type should be separated by commas.

#### Examples

Remove riak and erlang packages and files on `ppriakops01-sc9` and `ppriakops02-sc9`:

    snaphost.sh -h ppriakops01-sc9,ppriakops02-sc9,ppriakops03-sc9 -p riak,erlang-rebar -d /etc/riak,/var/lib/riak
