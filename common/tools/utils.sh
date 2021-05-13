#!/bin/bash
# shellcheck disable=SC2145,SC2034,SC2124,SC2139,SC2155,SC2086,SC2015,SC2004,SC2059,SC2017,SC2000
# TODO: Refactor this pile of you-know-what
##########################################################################################
#
# Terminal Utility Functions
# Originally by veez21
# Modified for use by Androidacy
#
##########################################################################################
# Colors
G='\e[01;32m'      # GREEN TEXT
R='\e[01;31m'      # RED TEXT
Y='\e[01;33m'      # YELLOW TEXT
B='\e[01;34m'      # BLUE TEXT
V='\e[01;35m'      # VIOLET TEXT
Bl='\e[01;30m'     # BLACK TEXT
C='\e[01;36m'      # CYAN TEXT
W='\e[01;37m'      # WHITE TEXT
BGBL='\e[1;30;47m' # Background W Text Bl
N='\e[0m'          # How to use (example): echo "${G}example${N}"
loadBar=' '        # Load UI
COLUMNS="$(stty size | cut -d" " -f2)"
div="${Bl}$(printf '%*s' $((COLUMNS * 90 / 100)) '' | tr " " "=")${N}"
e_spinner() {
  PID=$!
  h=0
  anim='⠋⠙⠴⠦'
  while [ -d /proc/$PID ]; do
    h=$(((h + 1) % 4))
    sleep 0.05
    printf "\r${@} [${anim:$h:1}]"
  done
}
it_failed() {
  set +euxo pipefail
  if test -z "$1" || test "$1" -ne 0; then
    echo -e "$div"
    echo -e "${R} ⓧ ERROR ⓧ ${N}"
    echo -e "${R}Something bad happened and the script has encountered an issue${N}"
    echo -e "${R}Make sure you're following instructions and try again!${N}"
    echo -e "${R} ⓧ ERROR ⓧ ${N}"
    echo -e "$div"
    echo -e "Exiting the script now!"
  fi
  exit "$1" || exit 1
}

# Versions
MODUTILVER=v2.6.1
MODUTILVCODE=261
MODDIR=/data/adb/modules/fontrevival
# Check A/B slot
if [ -d /system_root ]; then
  isABDevice=true
  SYSTEM=/system_root/system
  SYSTEM2=/system
  CACHELOC=/data/cache
else
  isABDevice=false
  SYSTEM=/system
  SYSTEM2=/system
  CACHELOC=/cache
fi
[ -z "$isABDevice" ] && {
  echo "Something went wrong!"
  exit 1
}

#=========================== Set Busybox up
# Variables:
#  BBok - If busybox detection was ok (true/false)
#  _bb - Busybox binary directory
#  _bbname - Busybox name

# set_busybox <busybox binary>
# alias busybox applets
set_busybox() {
  if [ -x "$1" ]; then
    for i in $(${1} --list); do
      if [ "$i" != 'echo' ]; then
        # shellcheck disable=SC2140
        alias "$i"="${1} $i" &>/dev/null
      fi
    done
    _busybox=true
    _bb=$1
  fi
}
_busybox=false
if [ -x $SYSTEM2/xbin/busybox ]; then
  _bb=$SYSTEM2/xbin/busybox
elif [ -x $SYSTEM2/bin/busybox ]; then
  _bb=$SYSTEM2/bin/busybox
else
  _bb=/data/adb/magisk/busybox
fi
if ! set_busybox $_bb; then
  it_failed 1
fi
[ -n "$ANDROID_SOCKET_adbd" ] && alias clear='echo'
_bbname="$($_bb | head -n1 | awk '{print $1,$2}')"
BBok=true
if [ "$_bbname" == "" ]; then
  _bbname="${R}BusyBox not found!${N}"
  it_failed
fi

#=========================== Default Functions and Variables
alias curl='$MODDIR/tools/curl -kLs --fail --compressed --tcp-fastopen --create-dirs --http2-prior-knowledge --retry 3 --retry-all-errors'

# Set perm
set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  (if [ -z $5 ]; then
    case $1 in
    *"system/vendor/app/"*) chcon 'u:object_r:vendor_app_file:s0' $1 ;;
    *"system/vendor/etc/"*) chcon 'u:object_r:vendor_configs_file:s0' $1 ;;
    *"system/vendor/overlay/"*) chcon 'u:object_r:vendor_overlay_file:s0' $1 ;;
    *"system/vendor/"*) chcon 'u:object_r:vendor_file:s0' $1 ;;
    *) chcon 'u:object_r:system_file:s0' $1 ;;
    esac
  else
    chcon $5 $1
  fi) || return 1
}

# Set perm recursive
set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read -r dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read -r file; do
    set_perm $file $2 $3 $5 $6
  done
}

# Mktouch
mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 >$1
  chmod 644 $1
}

# Grep prop
grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

# Is mounted
is_mounted() {
  grep -q " $(readlink -f $1) " /proc/mounts 2>/dev/null
  return $?
}

# Abort
abort() {
  echo "$1"
  exit 1
}

# Device Info
# Variables: BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
API=$(grep_prop ro.build.version.sdk)
ABI=$(grep_prop ro.product.cpu.abi | cut -c-3)
ABI2=$(grep_prop ro.product.cpu.abi2 | cut -c-3)
ABILONG=$(grep_prop ro.product.cpu.abi)
ARCH=arm
ARCH32=arm
IS64BIT=false
if [ "$ABI" = "x86" ]; then
  ARCH=x86
  ARCH32=x86
fi
if [ "$ABI2" = "x86" ]; then
  ARCH=x86
  ARCH32=x86
fi
if [ "$ABILONG" = "arm64-v8a" ]; then
  ARCH=arm64
  ARCH32=arm
  IS64BIT=true
fi
if [ "$ABILONG" = "x86_64" ]; then
  ARCH=x64
  ARCH32=x86
  IS64BIT=true
fi
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release) && D=$(resetprop ro.product.model || resetprop ro.product.device || resetprop ro.product.vendor.device || resetprop ro.product.system.model || resetprop ro.product.vendor.model || resetprop ro.product.name) && S=$(su -c "wm size | cut -c 16-") && L=$(resetprop persist.sys.locale || resetprop ro.product.locale) && M="fm" && P="m=$M&av=$A&a=$ARCH&d=$D&ss=$S&l=$L" && U="https://api.androidacy.com"
test_connection() {
  (curl "$P" "$U"/ping >/dev/null 2>&1) && return 0 || return 1
}
dl() {
  if ! curl --data "$P$1" "$U"/"$3" -o "$2"; then
    ui_print "⚠ Download failed! Bailing out!"
    it_failed
  fi
}
# Version Number
VER=$(grep_prop version $MODDIR/module.prop)
# Version Code
REL=$(grep_prop versionCode $MODDIR/module.prop)
# Author
AUTHOR=$(grep_prop author $MODDIR/module.prop)
# Mod Name/Title
MODTITLE=$(grep_prop name $MODDIR/module.prop)

COLUMNS="$(stty size | cut -d" " -f2)"
div="${Bl}$(printf '%*s' $((COLUMNS * 90 / 100)) '' | tr " " "-")${N}"

# title_div [-c] <title>
# based on $div with <title>
title_div() {
  [ "$1" == "-c" ] && local character_no=$2 && shift 2
  [ -z "$1" ] && {
    local message=
    no=0
  } || {
    local message="$@ "
    local no=$(echo "$@" | wc -c)
  }
  [ $character_no -gt $no ] && local extdiv=$((character_no - no)) || {
    echo "Invalid!"
    return
  }
  echo "${W}$message${N}${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# set_file_prop <property> <value> <prop.file>
set_file_prop() {
  if [ -f "$3" ]; then
    if grep -q "$1=" "$3"; then
      sed -i "s/${1}=.*/${1}=${2}/g" "$3"
    else
      echo "$1=$2" >>"$3"
    fi
  else
    echo "$3 doesn't exist!"
  fi
}

# https://github.com/fearside/ProgressBar
# ProgressBar <progress> <total>
ProgressBar() {
  # Determine Screen Size
  if [[ "$COLUMNS" -le "57" ]]; then
    local var1=2
    local var2=20
  else
    local var1=4
    local var2=40
  fi
  # Process data
  local _progress=$(((${1} * 100 / ${2} * 100) / 100))
  local _done=$(((${_progress} * ${var1}) / 10))
  local _left=$((${var2} - $_done))
  # Build progressbar string lengths
  local _done=$(printf "%${_done}s")
  local _left=$(printf "%${_left}s")

  # Build progressbar strings and print the ProgressBar line
  printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

#https://github.com/fearside/SimpleProgressSpinner
# Spinner <message>
Spinner() {

  # Choose which character to show.
  case ${_indicator} in
  "|") _indicator="/" ;;
  "/") _indicator="-" ;;
  "-") _indicator="\\" ;;
  "\\") _indicator="|" ;;
  # Initiate spinner character
  *) _indicator="\\" ;;
  esac

  # Print simple progress spinner
  printf "\r${@} [${_indicator}]"
}

# Log files will be uploaded to termbin.com
# Logs included: VERLOG LOG oldVERLOG oldLOG
upload_logs() {
  # TODO: Change this to our logging API
  # Until then, let's no-op it
  return 0
}

# Print Random
# Prints a message at random
# CHANCES - no. of chances <integer>
# TARGET - target value out of CHANCES <integer>
prandom() {
  local CHANCES=2
  local TARGET=2
  [ "$1" == "-c" ] && {
    local CHANCES=$2
    local TARGET=$3
    shift 3
  }
  [ "$((RANDOM % CHANCES + 1))" -eq "$TARGET" ] && echo "$@"
}

# Print Center
# Prints text in the center of terminal
pcenter() {
  local CHAR=$(printf "$@" | sed 's|\\e[[0-9;]*m||g' | wc -m)
  local hfCOLUMN=$((COLUMNS / 2))
  local hfCHAR=$((CHAR / 2))
  local indent=$((hfCOLUMN - hfCHAR))
  echo "$(printf '%*s' "${indent}" '') $@"
}

# Heading
mod_head() {
  clear
  echo "$div"
  echo "${W}$MODTITLE $VER${N}(${Bl}$REL${N})"
  echo "by ${W}$AUTHOR${N}"
  echo "$div"
  echo "${W}$_bbname${N}"
  echo "${Bl}$_bb${N}"
  echo "$div"
  [ -s $LOG ] && echo "Enter ${W}logs${N} to upload logs" && echo $div
}
