#!/bin/sh

#  Y510p.sh
#
#  Created by Intruder16 on 14/03/15.

# Debug
# set -x

# Changelog:
#
#   v1.1 :
#           -Internet check - the script will check for internet conn. if its available it will download all up-to-date patches required else it will use patches from "patches/" folder (i'll keep them up-to-date)
#           -Multiple runs - if you run the script more than once, you won't have to worry about previous leftovers they won't be overwritten simply copied to new folder inside "tmp/" like "tmp-1", "tmp-2" etc.
#           -Added "logging system"
#           -Added "patches check"
#           -Added choice for both Synaptics & ELAN Touchpad users (needed for brightness keys to work)
#           -Added choice for debug methods (DSDT, _WAK/_PTC, Qxx)
#           -Intelligent SSDT patching, that is, no matter how you extract acpi tables they will be patched always right. For Ex.
#               Every method has unique naming of ssdt's.
#               If extracted from linux then ssdt1,ssd2,etc and ssdt6, ssdt7 & ssdt8 inside dynamic folder.
#               If extracted using clover then ssdt-0, ssdt-1, ssd-2, ssdt3x, ssdt-4x etc.
#               Now the script will look at the contents of SSDT and patch it with required patches.
#           -Added brief description at the start of script about what it is going to do.
#   v1.2 :
#           -Cleanup -Removed Bogus SSDT's
#                    -Using "OS Check Windows 12" patch now.
#           -Added choice for "LID Sleep"
#           -Added choice for "Wake On USB"
#           -Added an option to use native CPU PM SSDT, but that's experimental and that's why commented.
#   v1.3 :
#           -Added "MCHC" patch
#           -patches updated for offline use
#   v1.4 :
#           -Added new option (-k) to keep all SSDT's
#           -minor improvements/optimizations
#           -using "getops" now


clear # Make some space xD

# Script version
sVersion=1.3

# Set the colours you can use
black='\033[0;30m'
white='\033[0;37m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
normal="\033[m"
bold="\033[1m"

# Set continue to false by default
CONTINUE=false

# Keep all SSDT's to 0 (flase) by default
keep_all="0"

# The version info of the running system i.e. '10.10.2'
ProductVersion="$(sw_vers -productVersion)"

copy_tables()
{
    # Specify log location
    logFile="$tmp_d/script_run.log"
    decompile_log="${tmp_d}/decompile.log"
    patch_log="${tmp_d}/patch.log"
    compile_log="${tmp_d}/compile.log"

    echo "${green}${bold}[ PreRun ]${normal}${bold}: Copying tables...${normal}"
    # Cleaning & creating working dirs
    mkdir -p "${tmp_d}/DSDT/"
    mkdir -p "${tmp_d}/patches/"
    # Creating log file
    touch $logFile
    touch $decompile_log
    touch $patch_log
    touch $compile_log
    # Copying patches
    echo "\n    >>>>   Copying Pacthes   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    cp -v patches/mine/*.txt ${tmp_d}/patches/  >> $logFile 2>&1
    # Copying orig DSDT/SSDT's
    echo "\n    >>>>   Copying DSDT/SSDT's   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    cp -v "${target_dir}/DSDT"*"" "${tmp_d}/DSDT/" >> $logFile 2>&1
    find "${target_dir}" -name \SSDT\* -exec cp -vR '{}' "${tmp_d}/DSDT/" ";" >> $logFile 2>&1
}

decompile_dsdt()
{
    echo "${green}${bold}[(D/S)SDT]${normal}${bold}: Decompiling DSDT...${normal}"
    echo "\n    >>>>   Decompiling Started   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    ./tools/iasl -da -dl ${tmp_d}/DSDT/* >> $decompile_log 2>&1
    mkdir -pv ${tmp_d}/DSDT/Decompiled/Not\ Necessary/  >> $logFile 2>&1
    mkdir -pv ${tmp_d}/DSDT/Compiled  >> $logFile 2>&1
    mkdir -pv ${tmp_d}/DSDT/Original  >> $logFile 2>&1
    find ${tmp_d}/DSDT/ -type f -name "*.dsl" -maxdepth 1 -exec mv -v '{}' ${tmp_d}/DSDT/Decompiled/ >> $logFile 2>&1 \;
    find ${tmp_d}/DSDT/ -type f -maxdepth 1 -exec mv -v '{}' ${tmp_d}/DSDT/Original/ >> $logFile 2>&1 \;
}

renaming_ssdt()
{
# Renaming SSDT's based on their actual content so that SSDT's extracted from any methods can be renamed correctly
    echo "${green}${bold}[(D/S)SDT]${normal}${bold}: Renaming SSDTs...${normal}"
    echo "\n    >>>>   Renaming SSDT's Started   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only

# PTID (SSDT1)
    if [ "$keep_all" == "1" ] ; then
        grep PTID ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $logFile 2>&1
    else
        grep PTID ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT1-PTID.dsl >> $logFile 2>&1
    fi
# OEM CPU PM (SSDT2)
    # Note : No need to patch PNOT if included
    if [ "$keep_all" == "1" ] ; then
        grep 'Name (_PSS, Package' ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $logFile 2>&1
    else
        grep 'Name (_PSS, Package' ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT2-CPU.dsl >> $logFile 2>&1
    fi
# CPU related (SSDT3)
    # Note : No need to patch PNOT if included
    if [ "$keep_all" == "1" ] ; then
        grep _PDC ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-2.dsl >> $logFile 2>&1
    else
        grep _PDC ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT3-CPU.dsl >> $logFile 2>&1
    fi
# iGPU (SSDT4)
    if [ "$keep_all" == "1" ] ; then
        grep 0x00020000 ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $logFile 2>&1
    else
        grep 0x00020000 ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $logFile 2>&1
    fi
# dGPU - /using this just to disable Nvidia GFX (SSDT5)
    if [ "$keep_all" == "1" ] ; then
        grep SB.PCI0.PEG0.PEGP ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $logFile 2>&1
    else
        grep SB.PCI0.PEG0.PEGP ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $logFile 2>&1
    fi
# Dynamic SSDT's (loaded on demand - recommend to not use) :

    # SSDT6 (if linux)
    grep C1TM ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT6-dynamic.dsl >> $logFile 2>&1
    # SSDT7 (if linux)
    grep PR.CPU0._PCT ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT7-dynamic.dsl >> $logFile 2>&1
    # SSDT8 (if linux)
    grep PR.CPU0._CST ${tmp_d}/DSDT/Decompiled/SSDT* | awk '{print $1}' | sed 's/://' | head -1 | xargs -I {} mv -v {} ${tmp_d}/DSDT/Decompiled/Not\ Necessary/SSDT8-dynamic.dsl >> $logFile 2>&1
}

acquire_patches()
{
    echo "${green}${bold}[(D/S)SDT]${normal}${bold}: Acquiring Pacthes...${normal}"
    echo "\n    >>>>   Downloading Patches Started   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    curl -o ${tmp_d}/patches/remove_DSM.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/syntax/remove_DSM.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_WAK2.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_WAK2.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_HPET.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_HPET.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_SMBUS.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_SMBUS.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_IRQ.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_IRQ.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_RTC.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_RTC.txt >> $logFile 2>&1
    # OS check Vista patch
    curl -o ${tmp_d}/patches/system_OSYS.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_OSYS.txt >> $logFile 2>&1
    # OS Check Windows 12 patch (Using this for now)
    curl -o ${tmp_d}/patches/system_OSYS_win8.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_OSYS_win8.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_Mutex.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_Mutex.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_PNOT.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_PNOT.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_IMEI.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_IMEI.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/usb_7-series.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/usb/usb_7-series.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/graphics_Rename-GFX0.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/graphics/graphics_Rename-GFX0.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/misc_Haswell-LPC.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/misc/misc_Haswell-LPC.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/debug.txt https://raw.githubusercontent.com/RehabMan/OS-X-ACPI-Debug/master/debug.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/instrument_WAK_PTS.txt https://raw.githubusercontent.com/RehabMan/OS-X-ACPI-Debug/master/instrument_WAK_PTS.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/instrument_Qxx.txt https://raw.githubusercontent.com/RehabMan/OS-X-ACPI-Debug/master/instrument_Qxx.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/graphics_PNLF_haswell.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/graphics/graphics_PNLF_haswell.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/misc_Lid_PRW.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/misc/misc_Lid_PRW.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/syntax_ppc.txt https://raw.githubusercontent.com/RehabMan/Lenovo-U430-Touch-DSDT-Patch/master/patches/syntax_ppc.txt >> $logFile 2>&1
    curl -o ${tmp_d}/patches/system_MCHC.txt https://raw.githubusercontent.com/RehabMan/Laptop-DSDT-Patch/master/system/system_MCHC.txt >> $logFile 2>&1
}

check_patches()
{
    echo "${green}${bold}[(D/S)SDT]${normal}${bold}: Checking Pacthes...${normal}"
    echo "\n    >>>>   Checking Patches Started   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    foundc=0
    nfoundc=0
    fflist=""
    nflist=""
    patch_list='patches/Patch_list.txt' # file with list of patches to search for

    echo "For patches in $patch_list" >> $logFile 2>&1
    exec 3< $patch_list
    while read file_a <&3; do
        if [[ ! -f "${tmp_d}/patches/${file_a}" ]];then    # file is not found or is 0 bytes
            nfoundc=$((nfoundc + 1))
            nflist=" ${nflist} ${file_a}"
            echo '...Not Found: ' "${file_a}" '...' >> $logFile 2>&1
        else    # file is found and is > 0 bytes.
            foundc=$((foundc + 1))
            fflist=" ${fflist} ${file_a}"
            echo '...Found: ' "${file_a}" '...' >> $logFile 2>&1
        fi
    done

    exec 3<&-
    #echo "List of patches Found: "${fflist}" "
    #echo "List of patches NOT Found: "${nflist}" "
    echo "Number of patches found     =  [${foundc}]  " >> $logFile 2>&1
    echo "Number of patches NOT found =  [${nfoundc}] " >> $logFile 2>&1
    if [ "${nfoundc}" -gt "0" ] ; then echo "     ...    '${nfoundc}' patch(es) missing! For more info see "$logFile"! Exiting!" $red; exit ; else patch_dsdt ; fi
}

patch_dsdt()
{
    echo "${green}${bold}[--DSDT--]${normal}${bold}: Patching DSDT in Decompiled/${normal}"
    echo "\n    >>>>   DSDT Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only

    echo "     ...    [syn] Remove _DSM methods"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/remove_DSM.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [syn] Fix _WAK Arg0 v2"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_WAK2.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    #echo "     ...    [sys] HPET Fix" # Check if boot / wakeup works
    #If you have panic "No HPETs available..." or have a abrupt restart after waking from sleep, you may need this patch. The patch makes sure the HPET device is always available.
    #./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_HPET.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $logFile

    echo "     ...    [sys] IRQ Fix"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_IRQ.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [sys] RTC Fix"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_RTC.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [sys] Add IMEI"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_IMEI.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [sys] Add MCHC"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_MCHC.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    # Using Windows 12 patch for now
    echo "     ...    [sys] OS Check Fix"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_OSYS_win8.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [sys] SMBus Fix"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_SMBUS.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [sys] Fix Mutex with non-zero SyncLevel"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_Mutex.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    if [ "$keep_all" != "1" ] ; then
    echo "     ...    [sys] Fix PNOT/PPNT"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/system_PNOT.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
    fi

    echo "     ...    [usb] 7-series/8-series USB"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/usb_7-series.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Rename GFX0 to IGPU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/graphics_Rename-GFX0.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [misc] Add Haswell LPC"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/misc_Haswell-LPC.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [misc] Insert DTGP"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/insert_DTGP.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [misc] ACPIKeyboard"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/ACPIKeyboard.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Battery Management"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/BatteryManagement.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [mine] IAOE Patch"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/iaoe.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Fix Error"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/Fix_Error.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Compilation"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/Compilation.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Brightness Key Fix"

    while true
    do
    read -p "     -------->     Which touchpad do you have? Synaptics (Default) or ELAN?  (Synaptics[s]/ELAN[e])  " answer
    #Thats asked because both VoodooPS2 & ELAN comes with their on versions of keyboard and can break brightness key function if not applied properly
    case $answer in
    [sS]* ) echo "                   Synaptics selected!"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/Brightness_Key_Voodoo.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
    [eE]* ) echo "                   ELAN selected!"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/Brightness_Key_ELAN.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
        * ) echo "                   Dude, just enter s(S) or e(E), please.";;
    esac
    done

    while true
    do
    read -p "     -------->     Do you want \"Wake on USB?\" (clicking mouse will wake from sleep)? (y/n) " answer
    case $answer in
    [yY]* ) echo "     ...    That's already enabled xD"
            break;;
    [nN]* ) echo "     ...    [mine] Disable Wake on USB"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/usb.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
        * ) echo "                   Dude, just enter Y or N, please.";;
    esac
    done

    while true
    do
    read -p "     -------->     Do you want to enable LID sleep (closing the lid will put the pc to sleep)? (y/n) " answer
    case $answer in
    [yY]* ) echo "     ...    [misc] Enable LID Sleep"
        ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/misc_Lid_PRW.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
        break;;
    [nN]* ) break;;
        * ) echo "                   Dude, just enter Y or N, please.";;
    esac
    done

    while true
    do
    read -p "     -------->     Do you want to add DSDT debug methods? (y/n) " answer
    case $answer in
    [yY]* ) echo "     ...    [debug] Add DSDT Debug Methods"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/debug.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
    [nN]* ) break;;
        * ) echo "                   Dude, just enter Y or N, please.";;
    esac
    done

    while true
    do
    read -p "     -------->     Do you want to add _WAK/_PTS debug methods? (y/n) " answer
    case $answer in
    [yY]* ) echo "     ...    [debug] Instrument _WAK/_PTS"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/instrument_WAK_PTS.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
    [nN]* ) break;;
        * ) echo "                   Dude, just enter Y or N, please.";;
    esac
    done

    while true
    do
    read -p "     -------->     Do you want to add EC Queries debug methods? (y/n) " answer
    case $answer in
    [yY]* ) echo "     ...    [debug] Instrument EC Queries"
            ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/DSDT.dsl ${tmp_d}/patches/instrument_Qxx.txt ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $patch_log 2>&1
            break;;
    [nN]* ) break;;
        * ) echo "                   Dude, just enter Y or N, please.";;
    esac
    done
    patch_ssdt
}

patch_ssdt()
{

if [ "$keep_all" == "1" ] ; then

    ########################
    # SSDT-0 (PTID) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-0 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-0 (PTID) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only
    echo "     ...    Nothing to patch here...moving on..."

    ########################
    # SSDT-1 (CPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-1 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-1 (CPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only
    echo "     ...    [syn] Remove Duplicate Packages buffer"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/syntax_ppc.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1

    ########################
    # SSDT-2 (CPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-2 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-2 (CPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only
    echo "     ...    Nothing to patch here...moving on..."

    ########################
    # SSDT-3 (iGPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-3 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-3 (iGPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only

    echo "     ...    [syn] Remove _DSM methods"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl ${tmp_d}/patches/remove_DSM.txt ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Rename GFX0 to IGPU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl ${tmp_d}/patches/graphics_Rename-GFX0.txt ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Brightness fix (Haswell)"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl ${tmp_d}/patches/graphics_PNLF_haswell.txt ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $patch_log 2>&1

    echo "     ...    [hdm] Rename B0D3 to HDAU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl ${tmp_d}/patches/HDMI.txt ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $patch_log 2>&1

    echo "     ...    [hdm] Add Intel HD4600 HDMI"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl ${tmp_d}/patches/Haswell-HDMI.txt ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $patch_log 2>&1

    ########################
    # SSDT-4 (dGPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-4 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-4 (dGPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only

    echo "     ...    [syn] Remove _DSM methods"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl ${tmp_d}/patches/remove_DSM.txt ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $patch_log 2>&1

    echo "     ...    [syn] Remove WMMX method"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl ${tmp_d}/patches/WMMX_remove.txt ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Rename GFX0 to IGPU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl ${tmp_d}/patches/graphics_Rename-GFX0.txt ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Compilation"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl ${tmp_d}/patches/Compilation.txt ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Disable Nvidia card (Won't work & disabling this saves significant battery)"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl ${tmp_d}/patches/graphics_Disable_Nvidia.txt ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $patch_log 2>&1
    compile_dsdt

else

    ########################
    # SSDT-0 (iGPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-0 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-0 (iGPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only

    echo "     ...    [syn] Remove _DSM methods"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl ${tmp_d}/patches/remove_DSM.txt ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Rename GFX0 to IGPU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl ${tmp_d}/patches/graphics_Rename-GFX0.txt ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Brightness fix (Haswell)"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl ${tmp_d}/patches/graphics_PNLF_haswell.txt ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $patch_log 2>&1

    echo "     ...    [hdm] Rename B0D3 to HDAU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl ${tmp_d}/patches/HDMI.txt ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $patch_log 2>&1

    echo "     ...    [hdm] Add Intel HD4600 HDMI"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl ${tmp_d}/patches/Haswell-HDMI.txt ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $patch_log 2>&1

    ########################
    # SSDT-1 (dGPU) Patches
    ########################

    echo "${green}${bold}[--SSDT--]${normal}${bold}: Patching SSDT-1 in Decompiled/${normal}"
    echo "\n    >>>>   SSDT-1 (dGPU) Patch Started   <<<<    \n" >> $patch_log 2>&1   #Logging Purpose Only

    echo "     ...    [syn] Remove _DSM methods"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/remove_DSM.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1

    echo "     ...    [syn] Remove WMMX method"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/WMMX_remove.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Rename GFX0 to IGPU"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/graphics_Rename-GFX0.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1

    echo "     ...    [mine] Compilation"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/Compilation.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1

    echo "     ...    [gfx] Disable Nvidia card (Won't work anyway & disabling this saves battery)"
    ./tools/patchmatic ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl ${tmp_d}/patches/graphics_Disable_Nvidia.txt ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $patch_log 2>&1
    compile_dsdt

fi
}

compile_dsdt()
{
    echo "${green}${bold}[(D/S)SDT]${normal}${bold}: Compiling DSDT/SSDT to Compiled/${normal}"
    echo "\n    >>>>   Compiling Started   <<<<    \n" >> $logFile 2>&1   #Logging Purpose Only
    echo "     ...    Compiling DSDT...."
    ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/DSDT.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/DSDT.dsl >> $compile_log 2>&1

    # Using pre-made SSDT by using ssdtPRgen.sh
    echo "     ...    Copying   SSDT... (pre-made using ssdtPRgen.sh)"
    cp -v SSDT/SSDT.aml ${tmp_d}/DSDT/Compiled/ >> $compile_log 2>&1

    if [ "$keep_all" == "1" ] ; then

        echo "     ...    Compiling SSDT-0..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-0.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $compile_log 2>&1

        echo "     ...    Compiling SSDT-1..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-1.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $compile_log 2>&1

        echo "     ...    Compiling SSDT-2..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-2.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-2.dsl >> $compile_log 2>&1

        echo "     ...    Compiling SSDT-3..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-3.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-3.dsl >> $compile_log 2>&1

        echo "     ...    Compiling SSDT-4..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-4.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-4.dsl >> $compile_log 2>&1
    else
        echo "     ...    Compiling SSDT-0..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-0.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-0.dsl >> $compile_log 2>&1

        echo "     ...    Compiling SSDT-1..."
        ./tools/iasl -vr -w1 -ve -p ${tmp_d}/DSDT/Compiled/SSDT-1.aml -I ${tmp_d}/DSDT/Decompiled ${tmp_d}/DSDT/Decompiled/SSDT-1.dsl >> $compile_log 2>&1
    fi

    echo "\n${green}${bold}[--Done--]${normal}${bold}: All done...${normal}\n"
    echo "${green}${bold}[--Done--]${normal}${blue}: ${bold}Very Imp${red} : ${bold}Do NOT forget to check logs inside ${blue}\"${tmp_d}/\"!${normal}\n"
    echo "${green}${bold}[--Done--]${normal}${bold}: Manually copy all from ${blue}\"${tmp_d}/DSDT/Compiled/\"${normal}${bold} to ${blue}\"/EFI/EFI/CLOVER/ACPI/patched/\"${bold}${normal}...${normal}\n"
    echo "${green}${bold}[--Done--]${normal}${bold}: Thanks for using this script! Any Feedbacks are welcome!${normal}\n"
}

# Checking internet connection
check_internet()
{
    if [ $(ping -q -c 1 google.com > /dev/null 2> /dev/null && echo online || echo offline) = "online" ] ; then
        echo "${green}${bold}[ PreRun ]${normal}${bold}: Internet connection available...switching to ${green}${bold}"Online"${normal}${bold} mode...${normal}"
        ONLINE="yes"
        copy_tables
        decompile_dsdt
        renaming_ssdt
        acquire_patches
        check_patches
    else
        echo "${green}${bold}[ PreRun ]${normal}${bold}: Internet connection NOT available...switching to ${red}${bold}"Offline"${normal}${bold} mode...${normal}"
        OFFLINE="yes"
        copy_tables
        decompile_dsdt
        renaming_ssdt
        echo "${green}${bold}[ PreRun ]${normal}${bold}: Copying Patches...${normal}"
        cp -v patches/repo/*.txt ${tmp_d}/patches/ >> /dev/null 2>&1
        check_patches
    fi
}

#Checking OS version
check_os()
{
        echo "${green}${bold}[ PreRun ]${normal}: ${blue}${bold}OS X $ProductVersion${normal}${bold} Detected! Continuing...${normal}"
        check_internet
}

pre_run()
{
echo "$keep_all"
    echo "\n${red}=============================================================="
    echo "${green}${bold}Lenevo Ideapad Y510p ${normal}${bold}DSDT/SSDT autopatch script by ${blue}intruder16:${normal}"
    echo "${red}==============================================================${normal}\n"
    echo "Brief info about about what this script will do:\n"
    echo "\t 1. First of all this script does not require any superuser permissions!"
    echo "\t    you do not need to run this with \"sudo\".\n"
    echo "\t 2. This script will try to check if a internet connection is available,"
    echo "\t    if it is then the script will run the \"online\" version that is it will download all"
    echo "\t    the patches required, if not then it will run the \"offline\" version (little faster)"
    echo "\t    and use the patches in \"patches/repo/\" folder.\n"
    echo "\t 3. Now it will copy all the DSDT and SSDT recursively from the folder you specified (must)"
    echo "\t    to the working directory which is \"tmp/DSDT/\" leaving the originals untouched.\n"
    echo "\t 4. The copied tables will be decompiled to a new folder \"tmp/DSDT/Decompiled/\" and the"
    echo "\t    originals will be copied to \"tmp/DSDT/Originals/\" and the SSDT's will be renamed"
    echo "\t    in order for better injection through clover.\n"
    echo "\t 5. Now the script will check if all the patches are available by running all the patches.txt"
    echo "\t    through a patch list specified in patch folder.\n"
    echo "\t 6. Finally the pacthing of DSDT and SSDT's will start. After that the tables are compiled"
    echo "\t    and you can see them in \"tmp/DSDT/Compiled/\" folder.\n"
    echo "\t 7. Most Important : The script will log everything it does in log files inside \"tmp/\""
    echo "\t    You are ${red}highly advised${normal} to check the logs afterwards to check if everything went OK.\n"
    echo ""
    while true
    do
        echo "${red}"
        read -p "Have you read what the script will do and would like to continue?  " answer
    case $answer in
    [yY]* ) CONTINUE=true
            clear
            if [ -d "tmp/" ] ; then # Check if tmp dir already exists
                n=$(ls tmp/ | grep tmp\* |  sed 's/^.\{4\}//' | tail -n1) ;
                if [[ $n =~ ^-?[0-9]+$ ]] ; then
                    m=$((n + 1)) ;
                    echo "${green}${bold}[  Info  ]${normal}: ${bold}Looks like you have used this script '${red}${bold}$m${normal}' times (\"${blue}${bold}tmp-'$n'${normal}${bold}\" dir exist!)${normal}" ;
                    echo "${bold}     ...    Creating one more tmp dir : ${blue}${bold}\"tmp/tmp-$m\"${normal}" ;
                    mkdir tmp/tmp-"$m" >> /dev/null 2>&1 ;
                    tmp_d="tmp/tmp-$m"
                else
                    n="1"
                    echo "${green}${bold}[  Info  ]${normal}: ${bold}Looks like you have already used this script once before (\"${blue}${bold}tmp${normal}${bold}\" dir exist!)${normal}" ;
                    echo "${bold}     ...    BUT, Nothing to worry about! Backing up all contents to ${blue}${bold}\"tmp/tmp-$n\"${normal}" ;
                    mkdir tmp/tmp-$n >> /dev/null 2>&1 ;
                    mv -v tmp/* tmp/tmp-$n >> /dev/null 2>&1 ;
                    m=$((n + 1)) ;
                    tmp_d="tmp/tmp-$m"
                fi
            else
                tmp_d="tmp"
            fi
            check_os
            break;;
    [nN]* ) echo ""
            echo "${red}Please read the script first, it only takes a few minutes."
            echo ""
            exit;;
        * ) echo "${normal}Dude, just enter Y or N, please.${normal}";;
    esac
    done
}

update()
{
    echo "\n${cyan}${bold}Lenevo Y510p IdeaPad${normal} - Yosemite $ProductVersion"
    echo "https://github.com/intruder16/Y510p-OS-X\n"
    echo "Script version \"${green}v$sVersion${normal}\"\n"
    echo "${green}${bold}[---GIT--]${normal}${bold}: Updating to latest Y510p-OS-X git master....${normal}"
    git pull >> /dev/null 2>&1
    echo "${green}${bold}[---GIT--]${normal}${bold}: Updated successfully....${normal}"
    echo
    exit
}

usage()
{
    echo "\n${cyan}${bold}Lenevo Y510p IdeaPad${normal} - Yosemite $ProductVersion"
    echo "https://github.com/intruder16/Y510p-OS-X\n"
    echo "Script version \"${green}v$sVersion${normal}\""
    echo "
        Valid Options:

            -t  ---  Path to the directory where your ACPI tables are stored
            -k  ---  Keep all SSDT's (by default keeps only 2 SSDT)
            -u  ---  Update
            -h  ---  Help screen (this)"

    echo "\n\t${blue}IMP: ${red}\"(-t)\"${normal} is a must! Files will be copied to the working dir leaving originals untouched."
    echo "\tTip : Use "'$HOME'" instead of "~" for home folder.\n"
    echo "Credits:\n"
    echo "${BLUE}Laptop-DSDT${normal}: https://github.com/RehabMan/Laptop-DSDT-Patch"
    echo "${BLUE}Pike R Aplha${normal}: https://github.com/Piker-Alpha/ssdtPRGen.sh"
    echo "${BLUE}Dell XPS 9530${normal}: https://github.com/robvanoostenrijk/XPS9530-OSX\n"

    exit
}

main()
{
if [ -z "$target_dir" ] ; then # Check if target dir is specified
    echo "\n${red}${bold}[ ERROR ]${normal} : Please specify a valid directory via ${bold}${red}(-t)${normal} option!" ;
    usage ;
    exit
else
    if [ ! -d "$target_dir" ] ; then echo "\n${red}${bold}[ ERROR ]${normal} : Directory does not exist! Please specify a valid directory!" ; usage ; exit ; fi
fi

    echo "\n${red}=============================================================="
    echo "${green}${bold}Lenevo Ideapad Y510p ${normal}${bold}DSDT/SSDT autopatch script by ${blue}intruder16:${normal}"
    echo "${red}==============================================================${normal}\n"
    echo "Brief info about about what this script will do:\n"
    echo "\t 1. First of all this script does not require any superuser permissions!"
    echo "\t    you do not need to run this with \"sudo\".\n"
    echo "\t 2. This script will try to check if a internet connection is available,"
    echo "\t    if it is then the script will run the \"online\" version that is it will download all"
    echo "\t    the patches required, if not then it will run the \"offline\" version (little faster)"
    echo "\t    and use the patches in \"patches/repo/\" folder.\n"
    echo "\t 3. Now it will copy all the DSDT and SSDT recursively from the folder you specified (must)"
    echo "\t    to the working directory which is \"tmp/DSDT/\" leaving the originals untouched.\n"
    echo "\t 4. The copied tables will be decompiled to a new folder \"tmp/DSDT/Decompiled/\" and the"
    echo "\t    originals will be copied to \"tmp/DSDT/Originals/\" and the SSDT's will be renamed"
    echo "\t    in order for better injection through clover.\n"
    echo "\t 5. Now the script will check if all the patches are available by running all the patches.txt"
    echo "\t    through a patch list specified in patch folder.\n"
    echo "\t 6. Finally the pacthing of DSDT and SSDT's will start. After that the tables are compiled"
    echo "\t    and you can see them in \"tmp/DSDT/Compiled/\" folder.\n"
    echo "\t 7. Most Important : The script will log everything it does in log files inside \"tmp/\""
    echo "\t    You are ${red}highly advised${normal} to check the logs afterwards to check if everything went OK.\n"
    echo ""
    while true
    do
        echo "${red}"
        read -p "Have you read what the script will do and would like to continue?  " answer
        case $answer in
        [yY]* ) CONTINUE=true
                clear
                if [ -d "tmp/" ] ; then # Check if tmp dir already exists
                    n=$(ls tmp/ | grep tmp\* |  sed 's/^.\{4\}//' | tail -n1) ;
                    if [[ $n =~ ^-?[0-9]+$ ]] ; then
                        m=$((n + 1)) ;
                        echo "${green}${bold}[  Info  ]${normal}: ${bold}Looks like you have used this script '${red}${bold}$m${normal}' times (\"${blue}${bold}tmp-'$n'${normal}${bold}\" dir exist!)${normal}" ;
                        echo "${bold}     ...    Creating one more tmp dir : ${blue}${bold}\"tmp/tmp-$m\"${normal}" ;
                        mkdir tmp/tmp-"$m" >> /dev/null 2>&1 ;
                        tmp_d="tmp/tmp-$m"
                    else
                        n="1"
                        echo "${green}${bold}[  Info  ]${normal}: ${bold}Looks like you have already used this script once before (\"${blue}${bold}tmp${normal}${bold}\" dir exist!)${normal}" ;
                        echo "${bold}     ...    BUT, Nothing to worry about! Backing up all contents to ${blue}${bold}\"tmp/tmp-$n\"${normal}" ;
                        mkdir tmp/tmp-$n >> /dev/null 2>&1 ;
                        mv -v tmp/* tmp/tmp-$n >> /dev/null 2>&1 ;
                        m=$((n + 1)) ;
                        tmp_d="tmp/tmp-$m"
                    fi
                else
                    tmp_d="tmp"
                fi
                check_os
                break;;
        [nN]* ) echo ""
                echo "${red}Please read the script first, it only takes a few minutes."
                echo ""
                exit;;
        * ) echo "${normal}Dude, just enter Y or N, please.${normal}";;
        esac
    done
}

while getopts "t:ukh" OPTIONS; do
case ${OPTIONS} in
t ) target_dir=$OPTARG ;;
u ) update ;;
k ) keep_all=1 ;;
h ) usage ;;
* ) usage ;;
esac
done

main

exit