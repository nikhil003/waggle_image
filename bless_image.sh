#!/bin/bash

# By default 1) install the registration key, 2) install the wvdial.conf with the AoT APN,
# 3) disable sudo, and 4) set the AoT root password.
#
# Disable any of these actions except #1 with approprite options


DISABLE_WVDIAL=0
DISABLE_APN=0
DISABLE_NO_SUDO=0
DISABLE_ROOT_PASS=0
CLEAN_UP=0
KEY_PATH='/root/id_rsa_waggle_aot_config'
MOUNT_POINT=''
while [[ $# -gt 0 ]]; do
  key="$1"
  echo "Key: $key"
  case $key in
    -w|--disable-wvdial)
      DISABLE_WVDIAL=1
      shift
      ;;
    -a|--disable-apn)
      DISABLE_APN=1
      shift
      ;;
    -s|--disable-no-sudo)
      DISABLE_NO_SUDO=1
      shift
      ;;
    -r|--disable-wvdial)
      DISABLE_ROOT_PASS=1
      shift
      ;;
    -c|--clean-up)
      CLEAN_UP=1
      shift
      ;;
    -k)
      KEY_PATH="$2"
      shift
      ;;
    --key-path=*)
      KEY_PATH="${key#*=}"
      ;;
    -m)
      MOUNT_POINT="$2"
      shift
      ;;
    --mount-point=*)
      MOUNT_POINT="${key#*=}"
      ;;
      *)
      ;;
  esac
  shift
done

if [ "x${MOUNT_POINT}" == "x" ]; then
  echo "Error: no mount point specified (use -m <mount-point> or --mount-point=<mount-point>)"
  exit 1
fi

if [ ! -e 'private_config' ]; then
  if [ ! -e ${KEY_PATH} ]; then
    echo "Error: no such key path ${KEY_PATH}"
    exit 2
  fi

  agent_pid=$(eval "$(ssh-agent -s)" | awk '{print $3}')
  ssh-add ${KEY_PATH}

  ssh -T git@github.com > /dev/null 2>&1
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "Error: unable to authenticate to GitHub"
    kill -9 ${agent_pid}
    exit 3
  fi
  git clone git@github.com:waggle-sensor/private_config.git
fi


# install registration key
cp private_config/id_rsa_waggle_aot_registration ${MOUNT_POINT}/root/id_rsa_waggle_aot_registration

# install wvdial.conf
if [ ${DISABLE_WVDIAL} -eq 0 ]; then
  cp private_config/wvdial.conf ${MOUNT_POINT}/etc/wvdial.conf
fi

# disable sudo
if [ ${DISABLE_NO_SUDO} -eq 0 ]; then
  deluser waggle sudo
fi

# set AoT root password
if [ ${DISABLE_ROOT_PASS} -eq 0 ]; then
  aot_root_shadow_entry=$(cat private_config/root_shadow)
  sed -i -e "s/^root:..*/${aot_root_shadow_entry}/" /etc/shadow
fi

kill -9 ${agent_pid}


if [ ${CLEAN_UP} -eq 1 ]; then
  rm -rf private_config
fi
