#!/bin/bash
##############################################
##                                          ##
##  swcursor-autoset                        ##
##                                          ##
##############################################

#get some variables
SCRIPT_TITLE="swcursor-autoset"
SCRIPT_VERSION="1.0"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
BOOT_DIR="NOT_FOUND"
mountpoint -q /boot && BOOT_DIR="/boot"
mountpoint -q /boot/firmware && BOOT_DIR="/boot/firmware"
CONFIG_FILE="$BOOT_DIR/config.txt"
TARGET_DIR="/etc/X11/xorg.conf.d"
TARGET_FILE="$TARGET_DIR/20-swcursor.conf"
EXITCODE=0

#!!!RUN RESTRICTIONS!!!
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi="rpi5|rpi4|rpi3"
#only for Raspbian OS (trixie|bookworm|bullseye|all) can combined!
rasos="trixie|bookworm"
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""
#this aptpaks need to be installed!
aptpaks=( xserver-xorg-core xserver-xorg-input-all )

#check commands
for i in "$@"
do
  case $i in
    --remove)
    [ "$CMD" == "" ] && CMD="remove" || CMD="help"
    shift # past argument
    ;;
    --service)
    [ "$CMD" == "" ] && CMD="service" || CMD="help"
    shift # past argument
    ;;
    -v|--version)
    [ "$CMD" == "" ] && CMD="version" || CMD="help"
    shift # past argument
    ;;
    -h|--help)
    CMD="help"
    shift # past argument
    ;;
    *)
    if [ "$i" != "" ]
    then
      echo "Unknown option: $i"
      exit 1
    fi
    ;;
  esac
done
[ "$CMD" == "" ] && CMD="help"

function do_check_start() {
  #check if superuser
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    exit 1
  fi
  #check if raspberry pi 
  if [ "$raspi" != "" ]; then
    raspi_v="$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
    local raspi_res="false"
    [[ "$raspi_v" =~ "Raspberry Pi" ]] && [[ "$raspi" =~ "all" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "$raspi" =~ "rpi3" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "$raspi" =~ "rpi4" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "$raspi" =~ "rpi5" ]] && raspi_res="true"
    if [ "$raspi_res" == "false" ]; then
      echo "This Device seems not to be an Raspberry Pi ($raspi)! Can not continue with this script!"
      exit 1
    fi
  fi
  #check if raspbian
  if [ "$rasos" != "" ]
  then
    rasos_v="$(lsb_release -d -s 2>/dev/null)"
    [ -f /etc/rpi-issue ] && rasos_v="Raspbian ${rasos_v}"
    local rasos_res="false"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos" =~ "all" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bullseye" ]] && [[ "$rasos" =~ "bullseye" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bookworm" ]] && [[ "$rasos" =~ "bookworm" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "trixie" ]] && [[ "$rasos" =~ "trixie" ]] && rasos_res="true"
    if [ "$rasos_res" == "false" ]; then
      echo "You need to run Raspbian OS ($rasos) to run this script! Can not continue with this script!"
      exit 1
    fi
  fi
  #check cpu architecture
  if [ "$cpuarch" != "" ]; then
    cpuarch_v="$(dpkg --print-architecture 2>/dev/null)"
    if [[ ! "$cpuarch" =~ "$cpuarch_v" ]]; then
      echo "Your CPU Architecture ($cpuarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check os architecture
  if [ "$bsarch" == "32" ] || [ "$bsarch" == "64" ]; then
    bsarch_v="$(getconf LONG_BIT 2>/dev/null)"
    if [ "$bsarch" != "$bsarch_v" ]; then
      echo "Your OS Architecture ($bsarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check apt paks
  local apt
  local apt_res
  IFS=$' '
  if [ "${#aptpaks[@]}" != "0" ]; then
    for apt in ${aptpaks[@]}; do
      [[ ! "$(dpkg -s $apt 2>/dev/null)" =~ "Status: install" ]] && apt_res="${apt_res}${apt}, "
    done
    if [ "$apt_res" != "" ]; then
      echo "Not installed apt paks: ${apt_res%?%?}! Can not continue with this script!"
      exit 0
    fi
  fi
  unset IFS
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file $CONFIG_FILE not found! Can not continue!"
    exit 0
  fi
}

function cmd_main() {
  local -a stack files
  declare -A seen
  stack=("$CONFIG_FILE")
  files=()
  while ((${#stack[@]})); do
    local f="${stack[-1]}"; unset 'stack[-1]'
    [[ -z "$f" || -n "${seen[$f]:-}" ]] && continue
    [[ -f "$f" ]] || continue
    seen["$f"]=1
    files+=("$f")
    local dir; dir="$(dirname "$f")"
    while IFS= read -r inc; do
      [[ -z "$inc" ]] && continue
      [[ "$inc" = /* ]] || inc="$dir/$inc"
      stack+=("$inc")
    done < <(grep -vE '^\s*#' "$f" | sed -n -E 's/^[[:space:]]*include(_if_exists)?[[:space:]]+([^[:space:]]+).*/\2/p')
  done
  if grep -h -iEv '^\s*#' "${files[@]}" 2>/dev/null | sed -E 's/#.*$//' | sed -E 's/[[:space:]]+//g; s/,/ /g' | grep -iE '^[[:space:]]*dtoverlay=vc4-kms-dsi-waveshare-panel' | grep -qiE '(^| )rotation=180( |$)'; then
    echo "[swcursor-autoset] waveshare-panel + rotation=180 found → add SWcursor-Config"
    mkdir -p "$TARGET_DIR"
    cat >"$TARGET_FILE" <<'EOF'
Section "Device"
  Identifier "VC4"
  Driver "modesetting"
  Option "SWcursor" "on"
EndSection
EOF
  else
    echo "[swcursor-autoset] No matching Overlay/Rotation found → remove SWcursor-Config if existing"
    mkdir -p "$TARGET_DIR"
    [ -f "$TARGET_FILE" ] && rm -f "$TARGET_FILE"
  fi
}

function cmd_remove() {
  echo "[swcursor-autoset] Manual remove triggered → remove SWcursor-Config if existing"
  mkdir -p "$TARGET_DIR"
  [ -f "$TARGET_FILE" ] && rm -f "$TARGET_FILE"
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $SCRIPT_NAME [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo " "
  echo "Small helper to automatically enable or remove a software cursor X11 config on"
  echo "Raspberry Pi devices that use certain Waveshare displays. The script inspects"
  echo "the device boot config and writes or removes an X11 snippet ('20-swcursor.conf')"
  echo "in '/etc/X11/xorg.conf.d/' to enable 'SWcursor' when a rotation/overlay match is"
  echo "detected."
  echo " "
  echo "-v, --version           print version info and exit"
  echo "-h, --help              print this help and exit"
  echo " "
  echo "Only one option at same time is allowed!"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

[[ "$CMD" != "version" ]] && [[ "$CMD" != "help" ]] && do_check_start
[[ "$CMD" == "version" ]] && cmd_print_version
[[ "$CMD" == "help" ]] && cmd_print_help
[[ "$CMD" == "service" ]] && cmd_main
[[ "$CMD" == "remove" ]] && cmd_remove

exit $EXITCODE