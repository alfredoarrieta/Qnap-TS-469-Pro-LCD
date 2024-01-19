#!/bin/sh

NAME="`hostname -s`"

stty -f /dev/cuau1.lock 1200
stty -f /dev/cuau1.init 1200
stty -f /dev/cuau1 1200

# clear display
printf '\115\015' > /dev/cuau1
sleep 1

# turn on display
printf '\115\136\001' > /dev/cuau1
sleep 1

# print hostname on line 1
printf '\115\014\000 '$NAME > /dev/cuau1 
sleep 1

# print message on line 2
printf '\115\014\001 Startup Complete' > /dev/cuau1 
sleep 30

# turn off display
printf '\115\136\000' > /dev/cuau1

# run service
(/usr/local/bin/lcd/lcd-control.ksh) >/dev/null 2>&1 &



