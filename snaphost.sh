#!/usr/bin/env bash
#
# A bare bones shell script to aide in testing Puppet manifests
# Can revert the install of packages and files or validate a good install
# Assumes sudo requiretty disabled on remote hosts and sudo as root enabled
#
# https://github.com/Cornellio/snaphost

SSH_REMOTE="/usr/bin/ssh -q -t"


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
      ;;
  esac

  printf "\n${OBJECTS_NUM} ${object_description} marked for removal: ${OBJECTS}\n"

  for host in $hosts; do
    printf "\nAccessing host: ${host}\n\n"
    for object in $OBJECTS; do
      $SSH_REMOTE $host "${command} ${object}"
    done
  done

}


run_commands () {

  COMMANDS="$*"

  printf "\nCommands marked for execution: \'${COMMANDS}\'\n"

  for host in $hosts; do
    printf "\nAccessing host: ${host}\n\n"
    $SSH_REMOTE $host "${COMMANDS}"
  done

}


parse_args_main () {

  case $1 in
    remove)
      shift
      parse_args_removal $*
      ;;
    *) usage
      ;;
  esac

}


parse_args_removal () {

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
  $PROGNAME remove -h [hosts,] -d [directories to remove,] -p [packages to remove,]
  Remove given packages and directories on each host. Use a comma separated list.

  Examples:

  Remove Riak packages and files on ppriakops01-sc9 and ppriakops02-sc9:

  snaphost.sh -h ppriakops01-sc9,ppriakops02-sc9 -p riak,erlang-rebar -d /etc/riak,/var/lib/riak

EOF
exit
}


# Main Section #

parse_args_main $*


printf "\nStarting removal process on ${hosts_num} hosts.\n"

if [ "${pkgs_to_remove}" ]; then
  pkgs_to_remove=${pkgs_to_remove/,/ }
  remove_objects packages $pkgs_to_remove
fi

if [ "${dirs_to_remove}" ]; then
  dirs_to_remove=${dirs_to_remove/,/ }
  remove_objects directories $dirs_to_remove
fi
