#!/bin/sh
#
# Copyright 2018-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA
#

. /usr/local/bin/openbmc-utils.sh

fcm_b_ver=`head -n1 ${BOTTOM_FCMCPLD_SYSFS_DIR}/cpld_ver 2> /dev/null`
fcm_t_ver=`head -n1 ${TOP_FCMCPLD_SYSFS_DIR}/cpld_ver 2> /dev/null`

usage() {
    echo "Usage: $0 [Fan Unit (1..8)]" >&2
}

# Top FCM    (BUS=64) PWM 1 ~ 4 control Fantray 1 3 5 7
# Bottom FCM (BUS=72) PWM 1 ~ 4 control Fantray 2 4 6 8
show_pwm()
{
    pwm="$(i2c_device_sysfs_abspath $1-0033)/fantray$2_pwm"
    val=$(cat $pwm | head -n 1)

    if [ "$fcm_b_ver" == "0x0" ] || [ "$fcm_t_ver" == "0x0" ]; then
        echo "$((val * 100 / 31))%"
    else
        echo "$((val * 100 / 63))%"
    fi
}

show_rpm()
{
    front_rpm="$(i2c_device_sysfs_abspath $1-0033)/fan$((($2 * 2 - 1)))_input"
    rear_rpm="$(i2c_device_sysfs_abspath $1-0033)/fan$((($2 * 2)))_input"
    echo "$(cat $front_rpm), $(cat $rear_rpm)"
}

set -e

# refer to the comments in init_pwn.sh regarding
# the fan unit and tacho mapping
if [ "$#" -eq 0 ]; then
    FANS="1 2 3 4 5 6 7 8"
elif [ "$#" -eq 1 ]; then
    if [ "$1" -le 0 ] || [ "$1" -ge 9 ]; then
        echo "Fan $1: not a valid Fan Unit"
        exit 1
    fi
    FANS="$1"
else
    usage
    exit 1
fi


for fan in $FANS; do
    FAN="${fan}"

    if [ $(($fan % 2)) -eq 0 ]; then
      BUS="72"
      UNIT=$((${FAN} / 2 ))
    else
      BUS="64"
      FAN=$((${FAN} / 2 ))
      UNIT=$((${FAN} + 1))
    fi

    echo "Fan $fan RPMs: $(show_rpm $BUS $UNIT), ($(show_pwm $BUS $UNIT))"
done
