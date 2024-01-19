QnapFreeLCD
===========
Original author Dirk Brenken (dibdot@gmail.com)


WARNING
========
This is a beta version, at the time of writing it was only tested on a TS-469 Pro.
https://www.qnap.com/en/product/ts-469%20pro

This script is only for QNAP-devices running TrueNAS CORE (stock QNAP firmware is not supported!).

SCOPE
======
This script does the following:
- read input for LCD status messages from a separate helper script (see sample function library)
- display status messages on LCD panel
- auto-cycling through status messages
- non-blocking manual navigation via LCD front panel buttons between messages
- fully configurable input-, message-,display- cycles & timeouts

REQUIREMENTS
=============
- QNAP device with LCD display & TrueNAS CORE

GET STARTED
============
Thanks to zeronic (https://www.reddit.com/r/truenas/comments/rumhb4/the_qnap_lcd_script_tutorial_from_a_linux_dummy/)
First:
- Copy the scripts to your nas via FTP (suggested: /usr/local/bin/lcd).
In the TrueNAS Web Ui go to Shell and:
- Make each script executable (for example: chmod a+x /usr/local/bin/lcd/lcd_preinit.sh).
- Adjust path no path adjustment needed if you use the suggested path /usr/local/bin/lcd (nano /usr/local/bin/lcd/lcd-control.ksh or via FTP).
- Adjust timeout parameters to your needs (nano /usr/local/bin/lcd/lcd-control.ksh or via FTP)
In the TrueNAS Web Ui go to Tasks/Init/Shutdown Scripts and create the following:

![Screenshot 2024-01-19 at 10 01 26 AM](https://github.com/mrarrieta/QnapFreeLCD/assets/85945105/dc603851-706c-4b05-9ac0-eb2826aa2d40)

CHANGELOG
==========
- Added multiple network interfaces support (up to 2)
- Added HDD temps
- Added Automatic ZFS Pool Detection

TODO
=====
For some reason, button presses are not detected consistently, after running the script multiple times it works, 
I'm still investigating the issue, the software is the current version I'm running in my Qnap TS-469 Pro.

