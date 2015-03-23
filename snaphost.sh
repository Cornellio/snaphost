#!/bin/bash
#
# A bare bones shell script to aide in testing a Puppet manifest for Riak
# Can revert or validate a Riak install on RHEL ditros
# Assumes sudo requiretty disabled on remote hosts and sudo as root enabled
#
# https://github.com/Cornellio/puppet-riak

HOSTLIST="ppriakops01-sc9 ppriakops02-sc9 ppriakops03-sc9"

case $1 in

  remove)
    for host in $HOSTLIST; do
      printf "\nREMOVING\nHOST: $host\n"
      ssh -q -t $host "sudo yum -y remove riak erlang-rebar ; sudo rm -fr /etc/riak /var/lib/riak"
    done
    ;;

  check)
    for host in $HOSTLIST; do
      printf "\nCHECKING\nHOST: $host\n"
      ssh -q -t $host "/sbin/service riak status; ls /var/lib/riak"
      ssh -q -t $host "sudo /usr/sbin/riak-admin test"
      ssh -q -t $host "sudo /usr/sbin/riak-admin status | grep ring_creation_size"
      ssh -q -t $host "sudo /usr/sbin/riak-admin status | grep ring_ownership"
    done
    ;;

  *)
    echo "Give something I can use. Try again"
    ;;

esac
