#!/usr/local/bin/ksh93
#
# function library sample for lcd-control 
# original author Dirk Brenken (dibdot@gmail.com)
#
#   LICENSE
#   ============
#   QnapFreeLcd Copyright (C) 2014 Dirk Brenken and Justin Duplessis
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# GET STARTED
# ============
# This is a sample script to gather and prepare system information for a QNAP TS-453A box with 2x16 LCD display.
# It's a helper script which will be automatically sourced by lcd-control.ksh during runtime as input.
# All query results have to fill up the "ROW" array and increment the array index accordingly.
# Please make sure, that the result sets match your LCD dimensions/rows,
# For most QNAP boxes (maybe all?) every single result set should consist of two rows.
# Please keep in mind, that this function library acts as a normal shell script,
# therefore it might be a good idea to test your queries and result sets stand alone before lcd-control.ksh integration.
# Feel free to build your own system queries and result sets (see examples below).
# Contributions for other QNAP boxes or better examples to enlarge this function library are very welcome!

# enable shell debug mode
#
#set -x

# treats unset variables as an error
#
set -u

# reset pre-defined message array
#
set -A ROW

#-------------------------------------------------------------------------------
# 1. network
# get host and ip address
#-------------------------------------------------------------------------------
#
# get current index count as start value
echo "////////////////////////////////////////////"
INDEX=${#ROW[@]}
# query
HOST="$(hostname -s)"
IP1=$(ifconfig em0 | grep "inet " | cut -f 2 -d " " | grep -v "127.0.")
IP2=$(ifconfig em1 | grep "inet " | cut -f 2 -d " " | grep -v "127.0.")
IP1_RESULT=""
IP1_NUMBER=0
for IP1_PARTIAL in $IP1; do
	echo "IP1: $IP1_PARTIAL"
	IP1_LAST_DIGIT=(${IP1_PARTIAL//./ })
	IP1_RESULT="${IP1_RESULT}${IP1_LAST_DIGIT[3]}|"
	((IP1_NUMBER++))
	done
echo "IP1_RESULT: ${IP1_RESULT}"
IP2_RESULT=""
IP2_NUMBER=0
for IP2_PARTIAL in $IP2; do
	echo "IP2: $IP2_PARTIAL"
	IP2_LAST_DIGIT=(${IP2_PARTIAL//./ })
	if [[ $IP1_RESULT != *"${IP2_LAST_DIGIT[3]}"* ]]
	then
		IP2_RESULT="${IP2_RESULT}${IP2_LAST_DIGIT[3]}|"
		((IP2_NUMBER++))
	else
		echo "Repeated IP Ignored ${IP2_LAST_DIGIT[3]}"
	fi
	done
echo "IP2_RESULT: ${IP2_RESULT}"
# result
ROW[${INDEX}]="${HOST}"
(( INDEX ++ ))
echo "IP1_NNUMBER: ${IP1_NUMBER} IP2_NNUMBER: ${IP2_NUMBER}"
if [ $IP1_NUMBER == 1 -a $IP2_NUMBER == 1 ]
then
	echo "Final IP: ${IP1}/${IP2_RESULT}"
	echo ""
	ROW[${INDEX}]="${IP1}/${IP2_RESULT}"
else
	echo "Final IP: ${IP1_RESULT}${IP2_RESULT}"
	ROW[${INDEX}]="${IP1_RESULT}${IP2_RESULT}"
fi

#-------------------------------------------------------------------------------
# 2. os/kernel
# get kernel and OS information
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
OS_LINE="Unknown";
if [ -f /etc/version ];then
	OS_LINE=$(cut -d' ' -f1 /etc/version)
else
	echo "Could not find proper file to retrieve OS info."
fi
#kernel info
KERNEL=$(uname -r)
# result
ROW[${INDEX}]=$OS_LINE
(( INDEX ++ ))
ROW[${INDEX}]="${KERNEL}"

#-------------------------------------------------------------------------------
# 4. Pool info (zfs)
# detect which is installed and how many pools are present
#-------------------------------------------------------------------------------
#
ZFS_POOLS=0
R_DEVICES=""

if (( $(whereis zfs | wc -w) != 1 ))
then
	ZFS_POOLS=$(zpool list -H | wc -l)
	echo "Found $ZFS_POOLS zfs pools !"
fi


#-------------------------------------------------------------------------------
# 4.1 Pool info zfs
# TODO add support for multiple pools ?
#-------------------------------------------------------------------------------
#
# get current index count as start value
if (( $ZFS_POOLS > 0 ))
then
	INDEX=${#ROW[@]}
	# query
	PREV_TOTAL=0
	PREV_IDLE=0
	POOL_NAME="$(zpool list -H | cut -f 1 )"
	POOL_NAME_CUTTED=${POOL_NAME%$'\n'*}
	echo "pool name: ${POOL_NAME_CUTTED}"
	FREE=$(zpool list -H "${POOL_NAME_CUTTED}" | cut -f 4)
	echo "free: ${FREE[0]}"
	HEALTH=$(zpool list -H "${POOL_NAME_CUTTED}" | cut -f 10)
	echo "health: ${HEALTH[0]}"
	CAP=$(zpool list -H "${POOL_NAME_CUTTED}" | cut -f 8)
	echo "capacity: ${CAP[0]}"
	SIZE=$(zpool list -H "${POOL_NAME_CUTTED}" | cut -f 2)
	echo "size: ${SIZE[0]}"
	# result
	ROW[${INDEX}]="$(zpool list -H "${POOL_NAME_CUTTED}" | cut -f 1)"
	(( INDEX ++ ))
	ROW[${INDEX}]="${FREE}/${SIZE}"
	(( INDEX ++ ))
	R_DEVICES=$(ls -l /dev/ada[0-9] | awk '{print$9}')
	#echo "devices: ${R_DEVICES}"
fi

#-------------------------------------------------------------------------------
# 5. HDD temps
# get hdd temperature (re-use device information from zfs)
#-------------------------------------------------------------------------------
#
# get current index count as start value
if [ "$R_DEVICES" != "" ]; then
	INDEX=${#ROW[@]}
	# query
	DEVICES="${R_DEVICES}"
        DRIVE_TEMPS=""
	for DEVICE in $DEVICES; do
		INDIVIDUAL_TEMP=$(smartctl -A $DEVICE | grep Temperature_Celsius | awk '{print$10}')
		echo "device: ${DEVICE} temp: ${INDIVIDUAL_TEMP}"
		DRIVE_TEMPS="${DRIVE_TEMPS}${INDIVIDUAL_TEMP} "
	done
	echo "temps: ${DRIVE_TEMPS}"
	# result
	ROW[${INDEX}]="Drive Temps"
	(( INDEX ++ ))
	ROW[${INDEX}]="${DRIVE_TEMPS}C"
	(( INDEX ++ ))
else
	echo "No devices were found to probe for temperature !"
fi
#-------------------------------------------------------------------------------
# 6. CPU load
# get current cpu load
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Load Average"
(( INDEX ++ ))
ROW[${INDEX}]=$(uptime | awk -F'load averages: ' '{ print $2 }')
(( INDEX ++ ))

#-------------------------------------------------------------------------------
# 7. update
# display uptime
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Uptime"
(( INDEX ++ ))
ROW[${INDEX}]=$(uptime | grep -ohe 'up .*' | sed 's/,//g' | awk '{ print $2" "$3 }')
(( INDEX ++ ))

#-------------------------------------------------------------------------------
# 8. last update
# display the data update time
#-------------------------------------------------------------------------------
#
# get current index count as start value
INDEX=${#ROW[@]}
# query
PREV_TOTAL=0
PREV_IDLE=0
# result
ROW[${INDEX}]="Last Updated"
(( INDEX ++ ))
ROW[${INDEX}]=$(date +"%H:%M %D")
(( INDEX ++ ))
