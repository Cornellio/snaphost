#!/usr/bin/env bash
#
# A bare bones shell script to aide in testing Puppet manifests
# Can revert the install of packages and files or validate a good install
# Assumes sudo requiretty disabled on remote hosts and sudo as root enabled
#
# https://github.com/Cornellio/snaphost

# TODO
# add check functions

SSH_REMOTE="/usr/bin/ssh -q -t"


parse_args () {

  if [ $# -lt 2 ] ; then
    usage
  fi

  while getopts "d:p:h:" OPTION; do
    case ${OPTION} in
      d)
        dirs_to_remove="$OPTARG"
        ;;
      p)
        pkgs_to_remove="$OPTARG"
        ;;
      h)
        hosts="$OPTARG"
        hosts=${hosts/,/ }
        hosts_num=$( echo ${hosts} | wc -w )
        hosts_num=${hosts_num// /}
        ;;
      *)
        usage
        ;;
    esac
  done
  shift
}


usage () {
  PROGNAME=$(basename $0)
  cat -<< EOF

  $PROGNAME usage:

  Removal commands:
  $PROGNAME remove -d [directories to remove,] -p [packages to remove,]
  Remove given packages and directories on each host. Use a comma separated list.

  Check commands:
  $PROGNAME check
  Check status of services on each host

  Examples:

  Remove Riak
  snaphost.sh -p riak,erlang-rebar -d /etc/riak,/var/lib/riak -h ppriakops01-sc9

EOF
exit
}


remove_objects () {

  object_type="$1"
  shift
  OBJECTS=$*
  OBJECTS_NUM="$#"

  case $object_type in
    packages)
      object_description="packages"
      command="sudo yum -y remove"
      ;;
    directories)
      object_description="directories"
      command="sudo rm -vfr"
  esac

  printf "\n${OBJECTS_NUM} ${object_description} marked for removal: ${OBJECTS}\n"

  for host in $hosts; do
    printf "\nAccessing host: ${host}\n\n"
    for object in $OBJECTS; do
      $SSH_REMOTE $host "${command} ${object}"
    done
  done

}


parse_args $*

printf "\nStarting removal process on ${hosts_num} hosts.\n"

if [ $pkgs_to_remove ]; then
  pkgs_to_remove=${pkgs_to_remove/,/ }
  remove_objects packages $pkgs_to_remove
fi

if [ $dirs_to_remove ]; then
  dirs_to_remove=${dirs_to_remove/,/ }
  remove_objects directories $dirs_to_remove
fi
