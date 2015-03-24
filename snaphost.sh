#!/usr/bin/env bash
#
# A bare bones shell script to aide in testing a Puppet manifest for Riak
# Can revert or validate a Riak install on RHEL ditros
# Assumes sudo requiretty disabled on remote hosts and sudo as root enabled
#
# https://github.com/Cornellio/puppet-riak

# TODO
# dry-ify
# add check functions

HOSTLIST="ppriakops01-sc9 ppriakops02-sc9 ppriakops03-sc9"
# HOSTLIST="ppriakops01-sc9"
SSH_REMOTE="/usr/bin/ssh -q -t"

parse_args () {

  while getopts "d:p:" OPTION; do

    case ${OPTION} in
      d)
        dirs_to_remove="$OPTARG"
        ;;
      p)
        pkgs_to_remove="$OPTARG"
        ;;
      ?) usage
        ;;
    esac

  done

  shift
  # shift $(($OPTIND-1))

}


usage () {
  PROGNAME=$(basename $0)
  cat -<< EOF

  $PROGNAME usage:

  Removal commands:
  $PROGNAME remove -d [directories to remove] -p [packages to remove]
  Remove given packages and directores on each host

  Check commands:
  $PROGNAME check
  Check status of services on each host

EOF
}


worker () {

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

}


remove_pkgs () {

  pkgs_to_remove=$*
  pkgs_to_remove_num="$#"

  printf "\nPackages marked for removal: ${pkgs_to_remove}\n"

  for host in $HOSTLIST; do
    printf "\nHOST ${host}:\n\n"
    for pkg in $pkgs_to_remove; do
      $SSH_REMOTE $host "sudo yum -y remove ${pkg}"
    done
  done

}

remove_dirs () {

  dirs_to_remove=$*
  dirs_to_remove_num="$#"

  printf "\nDirectories marked for removal: ${dirs_to_remove}\n"

  for host in $HOSTLIST; do
    printf "\nHOST ${host}:\n\n"
    for dir in $dirs_to_remove; do
      $SSH_REMOTE $host "sudo rm -vfr ${dir}"
    done
  done

}




parse_args $*

# echo ${dirs_to_remove}

# Remove packages
if [ $pkgs_to_remove ]; then
  printf "\nStarting removal process for packages.\n"
  pkgs_to_remove=${pkgs_to_remove/,/ }
  remove_pkgs ${pkgs_to_remove}
fi

# Remove files
if [ $dirs_to_remove ]; then
  printf "\nStarting removal process for directores.\n"
  dirs_to_remove=${dirs_to_remove/,/ }
  remove_dirs ${dirs_to_remove}
fi
