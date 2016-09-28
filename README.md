# OS X on Lenevo Ideapad Y510p

```javascript
Only for Yosemite 10.10 and above.
```

## Update : Same functionality but different method using Clover Hotpatch here : https://github.com/intruder16/Y510p-OS-X-Clover-Hotpatch

This repository contains all the necessary patches and an autopatcher script for DSDT/SSDT's on Y510p.

This will not in any way make any kind of change to your system! You do not need to run this with "sudo"!

This script is created for the fact that if you change BIOS settings (a headache for those who have a modded BIOS)
you will have to re-extract and re-patch the ACPI tables so that you will always have a patched DSDT specifically
for your BIOS settings. What happens is for some settings you change in BIOS the result is reflected in your ACPI tables.
So if you use someone else's DSDT there may be unexplained behavior on your end (coz both of them are created under different 
settings).

So what this script will do is re-patch your extracted tables with the necessary patches within seconds.

#Guide for installing OS X

To install OS X on your Y510p you can refer to [this](http://www.insanelymac.com/forum/topic/303276-guide-for-installing-os-x-yosemite-on-lenovo-ideapad-y510p/) excellent guide with all the necessary steps to make your
Hackintosh up and running.

#Dump ACPI tables

Extract ACPI tables using any method from linux, windows or even mac.
Refer [this](https://github.com/RehabMan/HP-ProBook-4x30s-DSDT-Patch/wiki/How-to-patch-your-DSDT) excellent guide here by RehabMan on how to extract ACPI tables.
#Copy dumped ACPI tables

Make sure to copy the ACPI tables you extracted to a safe place accessible via your newly installed MAC OS.

#Patch DSDT & SSDT's

Git clone of Y510p-OS-X, create one with (in terminal):
```javascript
git clone https://github.com/intruder16/Y510p-OS-X.git
```
OR 

if you do not have a working internet connection, download the repo as zip (option in down-right corner) from an internet enabled pc.

This will create a Y510p-OS-X folder with all the patches and autopatcher  script.

In a terminal navigate to the unpacked Y510p git data and execute the following:

Make the script executable:
```javascript
chmod +x Y510p.sh
```
Run the script
```javascript
./Y510p.sh -h
```

```javascript
./Y510p.sh -t "target dir"
```

The script will guide you through the process.

NOTE: You must specify (--target/-t ) a target folder (containing extracted DSDT/SSDT's)

For more info visit:

http://www.insanelymac.com/forum/topic/305122-dsdtssdt-auto-patcher-for-lenovo-y510p-ideapad/


#Credits:

Laptop-DSDT: https://github.com/RehabMan/Laptop-DSDT-Patch  (for all the patches)

Pike R Alpha: https://github.com/Piker-Alpha/ssdtPRGen.sh  (for the CPUSpeedStep SSDT patch)

Dell XPS 9530: https://github.com/robvanoostenrijk/XPS9530-OSX (for the idea)
