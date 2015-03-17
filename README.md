# OS X Yosemite on Lenevo Ideapad Y510p

This repository contains all the necessary patches and a autopacther script for DSDT/SSDT's on Y510p.

This script is created for the fact that if you change BIOS settings (a headache for those who have a modded BIOS)
you will have to re-extract and re-patch the ACPI tables so that you will always have a pacthed DSDT specifically
for your BIOS settings. What happens is for some settings you change in BIOS the result is reflected in your ACPI tables.
So if you use someone else's DSDT there may be unexplained behavior on your end (coz both of them are created under different 
settings).

So what this script will do is re-patch your extracted tables with the necessary patches within seconds.

#Guide for installing OS X Yosemite

To install OS X Yosemite on your Y510p you can refer to [this](http://www.insanelymac.com/forum/topic/303276-guide-for-installing-os-x-yosemite-on-lenovo-ideapad-y510p/) excellent guide with all the necessary steps to make your
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

if you do not have a working interet connection, download the repo as zip (option in down-right corner)

This will create a Y510p-OS-X folder with all the patches and autopatcher  script.

In a terminal navigate to the unpacked Y510p git data and execute the following:

Make the script executable:
```javascript
chmod +x Y510p.sh
```
Run the script
```javascript
./Y510p.sh
```
The script will guide you through the process.

#Credits:

Laptop-DSDT: https://github.com/RehabMan/Laptop-DSDT-Patch  (for all the pacthes)

Pike R Alpha: https://github.com/Piker-Alpha/ssdtPRGen.sh  (for the CPUSpeedStep SSDT pacth)

Dell XPS 9530: https://github.com/robvanoostenrijk/XPS9530-OSX (for the idea)
