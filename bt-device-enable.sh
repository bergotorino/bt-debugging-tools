#!/bin/bash
# This program is free software: you can redistribute it and/or modify it
# under the terms of the the GNU General Public License version 3, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the applicable version of the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright (C) 2016 Canonical, Ltd.

usage () {
    echo "Usage: $0 [OPTION...]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this mesage and exit"
    echo "  -p, --password CODE     Use the CODE as device unlock code"
    echo "  -e, --enable            Enable debugging"
    echo "  -d, --disable           Disable debugging"
}

loudly () {
    echo adb shell "$@"
    adb shell "$@"
}

check_devices() {
    # Quick way to make sure that we fail gracefully if more than one device 
    # is connected and no serial is passed
    set +e
    adb wait-for-device
    err=$?
    set -e
    if [ $err != 0 ]; then
        echo "E: more than one device or emulator"
        adb devices
        exit 1
    fi
}

# Disable debug logging for bluetoothd, pulseaudio and ofonod
disable_debug_logs_on_device() {
    loudly "echo -e '#\x21/bin/sh\necho $PASSWORD' >/tmp/askpass.sh"
    loudly "chmod +x /tmp/askpass.sh"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A mount -o remount,rw /"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/bluetoothd -d/bluetoothd/g' $BTCONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/--start --log-level=debug/--start/g' $PACONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/ofonod -d/ofonod/g' $OFCONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A reboot"
}

# Enable debug logging for bluetoothd, pulseaudio and ofonod
enable_debug_logs_on_device() {
    loudly "echo -e '#\x21/bin/sh\necho $PASSWORD' >/tmp/askpass.sh"
    loudly "chmod +x /tmp/askpass.sh"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A mount -o remount,rw /"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/bluetoothd/bluetoothd -d/g' $BTCONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/--start/--start --log-level=debug/g' $PACONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/ofonod/ofonod -d/g' $OFCONF"
    loudly "SUDO_ASKPASS=/tmp/askpass.sh sudo -A reboot"
}

[ -x /usr/bin/sudo               ] || { echo "Please install 'sudo'"; exit 1; }
[ -x /usr/bin/add-apt-repository ] || { echo "Please install 'software-properties-common'"; exit 1; }

# Default action is to enable device
ACTION="enable"

while [ -n "$1" ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --disable|-d)
            ACTION="disable"
            shift
            ;;
        --enable|-e)
            ACTION="enable"
            shift
            ;;
        --password|-p)
            shift
            PASSWORD="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z $PASSWORD ]; then
    usage
    exit 1
fi

# Bluetooth and PulseAudio conf files
BTCONF=/etc/init/bluetooth.conf
PACONF=/usr/share/upstart/sessions/pulseaudio.conf
OFCONF=/etc/init/ofono.override

check_devices

if [ "$ACTION" == "disable" ]; then
    disable_debug_logs_on_device
fi

if [ "$ACTION" == "enable" ]; then
    enable_debug_logs_on_device
fi

echo kthxbye
