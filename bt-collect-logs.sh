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
    echo "Usage: $0 PASSWORD [DESTINATION]"
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
if [ -z $PASSWORD ]; then
    usage
    exit 1
fi

DESTINATION="$2"
if [ -z $DESTINATION ]; then
    DESTINATION=.
fi

check_devices

DIRNAME=/tmp/logs
ARCHIVENAME=/tmp/logs-$(date +"%m-%d-%Y").tar.gz

loudly "echo -e '#\x21/bin/sh\necho $PASSWORD' >/tmp/askpass.sh"
loudly chmod +x /tmp/askpass.sh
loudly mkdir $DIRNAME
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A cp /var/log/syslog $DIRNAME
loudly cp /home/phablet/.cache/upstart/application-legacy-ubuntu-system-settings.log $DIRNAME
loudly cp /home/phablet/.cache/upstart/dbus.log $DIRNAME
loudly SUDO_ASKPASS=/tmp/askpass.sh sudo -A chmod 666 /tmp/logs/syslog
loudly tar -zcvf $ARCHIVENAME $DIRNAME
loudly rm -rf $DIRNAME
adb pull $ARCHIVENAME $DESTINATION

echo kthxbye
