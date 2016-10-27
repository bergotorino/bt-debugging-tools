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
cat <<EOF
usage: $0 [DEVICE-PASSWORD]
$1
EOF
exit 1
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

[ -x /usr/bin/sudo               ] || { echo "Please install 'sudo'"; exit 1; }
[ -x /usr/bin/add-apt-repository ] || { echo "Please install 'software-properties-common'"; exit 1; }

PASSWORD="$1"
[ $# -gt 0 ] && shift || usage "Missing DEVICE-PASSWORD"

# Bluetooth and PulseAudio conf files
BTCONF2=/etc/init/bluetooth.conf
PACONF=/usr/share/upstart/sessions/pulseaudio.conf

check_devices

loudly "echo -e '#\x21/bin/sh\necho $PASSWORD' >/tmp/askpass.sh"
loudly chmod +x /tmp/askpass.sh
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A mount -o remount,rw /
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/exec \/usr\/sbin\/bluetoothd/exec \/usr\/sbin\/bluetoothd -d/g' $BTCONF
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A sed -i 's/--start/--start --log-level=debug/g' $PACONF
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A reboot
echo kthxbye
