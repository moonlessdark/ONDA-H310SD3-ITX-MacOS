
#!bin/bash

################################################################
####################### Helper Function ########################
################################################################

function _helpDefaultWrite()
{
    VAL=$1
    local VAL1=$2

    if [ ! -z "$VAL" ] || [ ! -z "$VAL1" ]; then
    defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "$VAL" "$VAL1"
    fi
}

function _helpDefaultRead()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
    defaults read "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "$VAL"
    fi
}

function _helpDefaultDelete()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
    defaults delete "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "$VAL"
    fi
}

function _playchime()
{
    afplay -v "$speakervolume" ../sounds/done.mp3 &
}

function _playchimedeath()
{
    afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
}

function _checkpass() {

    user=$( _helpDefaultRead "Rootuser" )
    passw=$( security find-generic-password -a "Kext Updater" -w | sed "s/\"/\\\\\"/g")

    osascript -e 'do shell script "dscl /Local/Default -u '$user'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1

    if [ $? != 0 ]; then
      _helpDefaultWrite "Passwordok" "No"
    else
      _helpDefaultWrite "Passwordok" "Yes"
    fi
}

function _getsecret() {
    secret=$(security find-generic-password -a "Kext Updater" -w)
    if [[ $secret = "44" ]]; then
    _helpDefaultWrite "Passwordok" "No"
    else
    passw="$secret"
    fi
}

allkextsupper="ACPIBatteryManager AirportBrcmFixup AppleALC AppleBacklightFixup AsusSMC ATH9KFixup AtherosE2200Ethernet AtherosWiFiInjector AzulPatcher4600 BrcmPatchRam BT4LEContiunityFixup Clover CodecCommander CoreDisplayFixup CPUFriend EnableLidWake FakePCIID FakeSMC GenericUSBXHCI HibernationFixup IntelGraphicsFixup IntelGraphicsDVMTFixup IntelMausiEthernet Lilu LiluFriend NightShiftUnlocker NoTouchID NoVPAJpeg NullCpuPowerManagement NullEthernet NvidiaGraphicsFixup RealtekRTL8111 RTCMemoryFixup Shiki SystemProfilerMemoryFixup USBInjectAll VirtualSMC VoodooHDA VoodooI2C VoodooPS2 VoodooTSCSync WhateverGreen"
allkextslower=$( echo "$allkextsupper" | tr '[:upper:]' '[:lower:]' )

#========================= Excluded Kexts =========================#

function _excludedkexts()
{
    kextstatsori=$( kextstat | grep -v com.apple )
    bdmesg=$( ../bin/./BDMESG |grep "Clover revision" |sed -e "s/.*revision:\ /Clover\ (/g" -e "s/\ on.*/)/g" )
    #kuversion=$( _helpDefaultRead "KUVersion" )
    kextstatsori=$( echo -e "$kextstatsori" "\n$bdmesg" )
    kextstatsori=$( echo -e "$kextstatsori" |sed "s/d0)/)/g" )
    #kextstatsori=$( echo -e "$kextstats" "\nKextupdater ($kuversion)" )

    kext="ACPIBatteryManager"
    check=$( echo "$content" | grep ex-$kext | sed "s/.*=\ //g" )
    if [[ $check = "true" ]]; then
        kextstats=$( echo "$kextstatsori" | grep -v $kext )
        else
        kextstats=$( echo "$kextstatsori" )
    fi

    array=($allkextsupper)
    for i in "${array[@]}"; do
        check=$( echo "$content" | grep -w ex-$i | sed "s/.*=\ //g" )
        if [[ $check = "true" ]]; then
            kextstats=$( echo "$kextstats" | grep -v $i )
            else
            kextstats=$( echo "$kextstats" )
        fi
    done
}

################################################################
####################### Helper Function End ####################
################################################################

ScriptHome=$(echo $HOME)
ScriptTmpPath=$( _helpDefaultRead "Temppath" )
ScriptReportPath=$( _helpDefaultRead "Reportpath" )
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"

checkchime=$( _helpDefaultRead "Chime" )

#========================= Kext Array =========================#
## Script Name,kextstat Name, echo Name, Ersatz Name
#

kextArray=(
"acpibatterymanager","org.rehabman.driver.AppleSmartBatteryManager","ACPI BatteryManager",""
"airportbrcmfixup","BrcmWLFixup","BrcmWLFixup","AirportBrcmFixup"
"airportbrcmfixup","AirportBrcmFixup","AirportBrcmFixup",""
"applealc","AppleALC","AppleALC",""
"applebacklightfixup","AppleBacklightFixup","AppleBacklightFixup","WhateverGreen","Alarm"
"asussmc","AsusSMC","AsusSMC",""
"ath9kfixup","ATH9KFixup","ATH9KFixup",""
"atherose2200ethernet","AtherosE2200","AtherosE2200Ethernet",""
"azulpatcher4600","AzulPatcher4600","AzulPatcher4600",""
"brcmpatchram","BrcmFirmwareStore","BrcmPatchRam",""
"bt4lecontiunityfixup","BT4LEContiunityFixup","BT4LEContiunityFixup",""
"clover","Clover","Clover Bootloader",""
"codeccommander","CodecCommander","CodecCommander",""
"coredisplayfixup","CoreDisplayFixup","CoreDisplayFixup","WhateverGreen","Alarm"
"cpufriend","CPUFriend","CPUFriend",""
"enablelidwake","EnableLidWake","EnableLidWake",""
"fakepciid","FakePCIID","FakePCIID",""
"fakesmc","FakeSMC","FakeSMC",""
"genericusbxhci","GenericUSBXHCI","GenericUSBXHCI",""
"hibernationfixup","HibernationFixup","HibernationFixup",""
"intelgraphicsdvmtfixup","IntelGraphicsDVMTFixup","IntelGraphicsDVMTFixup","WhateverGreen","Alarm"
"intelgraphicsfixup","IntelGraphicsFixup","IntelGraphicsFixup","WhateverGreen","Alarm"
"intelmausiethernet","AppleIntelE1000","AppleIntelE1000","IntelMausiEthernet"
"intelmausiethernet","IntelMausi","IntelMausiEthernet",""
"lilu","Lilu ","Lilu",""
"lilufriend","LiluFriend","LiluFriend",""
"nightshiftunlocker","NightShiftUnlocker","NightShiftUnlocker",""
"notouchid","NoTouchID","NoTouchID",""
"novpajpeg","NoVPAJpeg","NoVPAJpeg",""
"nullcpupowermanagement","NullCpuPower","NullCpuPowerManagement",""
"nullethernet","NullEthernet","NullEthernet",""
"nvidiagraphicsfixup","LibValFix","NVWebDriverLibValFix","WhateverGreen","Alarm"
"nvidiagraphicsfixup","NvidiaGraphicsFixup","NvidiaGraphicsFixup","WhateverGreen","Alarm"
"realtekrtl8111","RealtekRTL8111","RealtekRTL8111",""
"rtcmemoryfixup","RTCMemoryFixup","RTCMemoryFixup",""
"shiki","Shiki","Shiki","WhateverGreen","Alarm"
"systemprofilermemoryfixup","SystemProfilerMemoryFixup","SystemProfilerMemoryFixup",""
"usbinjectall","USBInjectAll","USBInjectAll",""
"virtualsmc","VirtualSMC","VirtualSMC",""
"voodoohda","VoodooHDA","VoodooHDA",""
"voodooi2c","VoodooI2C (","VoodooI2C",""
"whatevergreen","WhateverGreen","WhateverGreen",""
"voodoops2","PS2Controller","VoodooPS2",""
"voodootscsync","VoodooTSCSync","VoodooTSCSync",""
)

#========================= Language Detection =========================#
function _languageselect()
{
    if [[ $lan2 = de* ]]; then
    export LC_ALL=de_DE
    language="de"
    elif [[ $lan2 = tr* ]]; then
    export LC_ALL=tr_TR
    language="tr"
    elif [[ $lan2 = ru* ]]; then
    export LC_ALL=ru_RU
    language="ru"
    elif [[ $lan2 = uk* ]]; then
    export LC_ALL=uk_UK
    language="uk"
    elif [[ $lan2 = es* ]]; then
    export LC_ALL=es_ES
    language="es"
    elif [[ $lan2 = pt* ]]; then
    export LC_ALL=pt_PT
    language="pt-PT"
    elif [[ $lan2 = nl* ]]; then
    export LC_ALL=nl_NL
    language="nl"
    elif [[ $lan2 = fr* ]]; then
    export LC_ALL=fr_FR
    language="fr"
    elif [[ $lan2 = it* ]]; then
    export LC_ALL=it_IT
    language="it"
    elif [[ $lan2 = fi* ]]; then
    export LC_ALL=fi_FI
    language="fi"
    elif [[ $lan2 = pl* ]]; then
    export LC_ALL=pl_PL
    language="pl"
    elif [[ $lan2 = sv* ]]; then
    export LC_ALL=sv_SV
    language="sv"
    elif [[ $lan2 = cs* ]]; then
    export LC_ALL=cs_CS
    language="cs"
    else
    export LC_ALL=en_EN
    language="en"
    fi
    if [ ! -d "$ScriptTmpPath" ]; then
        mkdir "$ScriptTmpPath"
    fi
    if [ ! -f ${ScriptTmpPath}/locale.tmp ]; then
        cat ../$language.lproj/MainMenu.strings | sed "s/\=\ \"/\=\"/g" | grep -A 10000000 BASH | tail -n +2 > ${ScriptTmpPath}/locale.tmp
    fi
    source ${ScriptTmpPath}/locale.tmp
}

###################################################################
########################### Set Root User #########################
###################################################################

function _setrootuser()
{

    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    user=$( id -un )
    userfull=$( id -F "$user" )
    OK="0"

    admin=$( _helpDefaultRead "Admin" ) >/dev/null 2>&1
if [[ $admin = "" ]]; then

    groups "$user" | grep -q -w admin
    if [ $? = 0 ]; then
      _helpDefaultWrite "Admin" "Yes"
      _helpDefaultWrite "Rootuser" "$user"
      _helpDefaultWrite "RootuserFull" "$userfull"
#exit 0
    else
      _helpDefaultWrite "Admin" "No"
      admin="No"
    fi

    _languageselect

    if [[ $admin = "No" ]]; then

    echo -e "read -r -d '' applescriptCode <<'EOF'" > "$ScriptTmpPath"/result
    echo -e "set dialogText to text returned of (display dialog \"$textadmin\" default answer \"$answeradmin\" with icon file \":..:pics:admin.png\")" >> "$ScriptTmpPath"/result
    echo -e "return dialogText" >> "$ScriptTmpPath"/result
    echo -e "EOF" >> "$ScriptTmpPath"/result
    echo -e "dialogText=\$(osascript -e \"\$applescriptCode\");" >> "$ScriptTmpPath"/result
    source "$ScriptTmpPath"/result
    userfull=$( id -F $dialogText )
    user=$( id -un $dialogText )

        if [ "$?" != "0" ]; then
          echo -e "$warnnouser\n"
          _helpDefaultWrite "Rootuser" "$user"
          _helpDefaultWrite "RootuserFull" "$userfull"
            if [[ $checkchime = "1" ]]; then
              afplay -v "$speakervolume" ../sounds/error.aif &
            fi
          echo -e "$noadmin\n"
        else
            if id "$user" >/dev/null 2>&1; then
              _helpDefaultWrite "Rootuser" "$user"
              _helpDefaultWrite "RootuserFull" "$userfull"
              groups "$user" | grep -q -w admin
                if [ $? = 0 ]; then
                  _helpDefaultWrite "Admin" "Yes"
                else
                if [[ $checkchime = "1" ]]; then
                  afplay -v "$speakervolume" ../sounds/error.aif &
                fi
                echo -e "$noadmin\n"
                fi
                if [[ $checkchime = "1" ]]; then
                  afplay -v "$speakervolume" ../sounds/passok.aif &
                fi
            else
              echo -e "$usernoexist\n"
                until [[ $OK = "1" ]]; do
                  source "$ScriptTmpPath"/result
                    if [ "$?" != "0" ]; then
                      OK="1"
                      _helpDefaultWrite "Rootuser" "$user"
                      _helpDefaultWrite "RootuserFull" "$userfull"
                      groups "$user" | grep -q -w admin
                        if [ $? = 0 ]; then
                          _helpDefaultWrite "Admin" "Yes"
                        fi
                        if [[ $checkchime = "1" ]]; then
                          afplay -v "$speakervolume" ../sounds/passok.aif &
                        fi
                    else
                        if id "$dialogText" >/dev/null 2>&1; then
                          OK="1"
                          _helpDefaultWrite "Rootuser" "$user"
                          _helpDefaultWrite "RootuserFull" "$userfull"
                          groups "$user" | grep -q -w admin
                            if [ $? = 0 ]; then
                              _helpDefaultWrite "Admin" "Yes"
                                if [[ $checkchime = "1" ]]; then
                                  afplay -v "$speakervolume" ../sounds/passok.aif &
                                fi
                            else
                              echo -e "$noadmin\n"
                            fi
                        else
                          echo -e "$usernoexist\n"
                            if [[ $checkchime = "1" ]]; then
                              afplay -v "$speakervolume" ../sounds/error.aif &
                            fi
                        fi
                    fi
                done
              fi
        fi
    fi
fi
}

function _resetrootuser()
{

    ../bin/./PlistBuddy -c "Delete Rootuser" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    ../bin/./PlistBuddy -c "Delete Admin" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    ../bin/./PlistBuddy -c "Delete Passwordok" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    _setrootuser

}
###################################################################
######################### Seek all EFIs ###########################
###################################################################

function scanallefis()
{

    for a in {1..8}; do
    ../bin/./PlistBuddy -c "Delete EFI$a-Name" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    done

    ../bin/./PlistBuddy -c "Delete EFIx" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1

    if [ -f "$ScriptTmpPath"/drives ]; then
      rm "$ScriptTmpPath"/drives
    fi

    efis=$( diskutil list | grep "EFI" | sed "s/.*disk/disk/g" | cut -c 1-7 )

    while read -r line; do
    node=$( echo $line | cut -c 1-5 )
    efiname=$( diskutil info $node |grep "Media Name:" | sed "s/.*://g" |xargs )
    echo -e "$line"";""$efiname" >> "$ScriptTmpPath"/drives
    done <<< "$efis"

    num="0"
    while read -r line; do
    num=$(( $num + 1 ))
    node=$( cat "$ScriptTmpPath"/drives | head -$num | tail -1 | cut -d";" -f1-1 )
    name=$( cat "$ScriptTmpPath"/drives | head -$num | tail -1 | cut -d";" -f2-2 )
    _helpDefaultWrite "EFI$num-Name" "$node - $name"
    done < "$ScriptTmpPath"/drives

}

function mountefiall()
{

    initial

    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    node=$( _helpDefaultRead "EFIx" )
    if [[ $keychain = "1" ]]; then
    _getsecret
    osascript -e 'do shell script "diskutil mount '$node'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
    osascript -e 'do shell script "diskutil mount '$node'" with administrator privileges' >/dev/null 2>&1
    fi

    if [ $? != 0 ]; then
        if [[ $checkchime = "1" ]]; then
          afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
        fi
        echo "$error"
    else
        _helpDefaultWrite "Mounted" "No"

#efiroot=$( diskutil info "$node" |grep "Partition UUID" | sed "s/.*://g" |xargs )
#_helpDefaultWrite "EFI Root" "$efiroot"
#devicenode=$( diskutil info "$efiroot" | grep "Device Node:" | sed "s/.*://g" | xargs )
#devicenodemain=$( echo -e "$node" | sed "s/s[0-9]//g" )
#drivemodel=$( diskutil info $devicenodemain |grep "Media Name:" | sed "s/.*://g" |xargs )
#diskscan=$( diskutil info $efiscan )
#mountpoint=$( diskutil info "$node" | grep "Mount Point:" | sed "s/.*://g" | xargs )
#protocol=$( diskutil info "$efiroot" | grep "Protocol:" | sed "s/.*://g" | xargs )
#devicelocation=$( diskutil info "$efiroot" | grep "Device Location:" | sed "s/.*://g" | xargs )
#_helpDefaultWrite "Mount Point" "$mountpoint"
#_helpDefaultWrite "Drive Model" "$drivemodel"
#_helpDefaultWrite "Device Node" "$devicenode"
#_helpDefaultWrite "Device Protocol" "$protocol"

        if [[ $mountpoint != "" ]];then
            efipath=$( find "$mountpoint" -name "config.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
            if [[ $efipath = "" ]]; then
                efipath=$( find "$mountpoint" -name "Default.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
            fi
            if [[ $efipath = "" ]]; then
                efipath="🚫"
            fi        
        fi

    _helpDefaultWrite "EFI Path" "$efipath"

        if [[ $checkchime = "1" ]]; then
          afplay -v "$speakervolume" ../sounds/done.mp3 &
        fi
        echo "$webdrloaded"
    fi

}

function unmountefi()
{

    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    node=$( _helpDefaultRead "EFIx" )
    if [[ $keychain = "1" ]]; then
    _getsecret
    osascript -e 'do shell script "diskutil unmount '$node'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
    osascript -e 'do shell script "diskutil unmount '$node'" with administrator privileges' >/dev/null 2>&1
    fi

    _helpDefaultWrite "Mounted" "No"

    if [[ $checkchime = "1" ]]; then
      afplay -v "$speakervolume" ../sounds/done.mp3 &
    fi

    echo "$webdrloaded"

}

function unmountefiall()
{

    user=$( _helpDefaultRead "Root User" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    user=$( _helpDefaultRead "Rootuser" )

    _languageselect

    for a in {1..8}; do
        for key in "EFI$a-Name"; do
        val=$(_helpDefaultRead "EFI$a-Name" 2>/dev/null || printf '0')
            if [[ $val != "0" ]];then
              disk=$( echo "$val" | sed "s/\ -.*//g" )

                  if [[ $keychain = "1" ]]; then
                    _getsecret
                    osascript -e 'do shell script "diskutil unmount '$disk'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
                  else
                    osascript -e 'do shell script "diskutil unmount '$disk'" with administrator privileges' >/dev/null 2>&1
                  fi
            fi
        done
    done

    _helpDefaultWrite "Mounted" "No"

    if [[ $checkchime = "1" ]]; then
      afplay -v "$speakervolume" ../sounds/done.mp3 &
    fi

    echo "$webdrloaded"

}

################################################################
####################### Initial Function #######################
################################################################

function initial()
{

    ../bin/./PlistBuddy -c "Print RootuserFull" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    if [[ $? = "1" ]]; then
    ../bin/./PlistBuddy -c "Delete Admin" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    ../bin/./PlistBuddy -c "Delete Rootuser" "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" >/dev/null 2>&1
    fi

    efiscan=$( ../bin/./BDMESG |grep -e "SelfDevicePath" -e "Found Storage" | sed -e s/".*GPT,//g" -e "s/.*MBR,//g" -e "s/,.*//g" | xargs )
    diskscan=$( diskutil info $efiscan )
    checkchime=$( _helpDefaultRead "Chime" )

    efiroot=$( echo -e "$efiscan" )
    efiname=$( echo -e "$diskscan" | grep "Volume Name:" | sed "s/.*://g" | xargs )
    clovermode=$( ../bin/./BDMESG | grep -i "starting clover" | sed "s/.*EFI/UEFI/g" | tr -d '\r')
    ozmosischeck=$( ../bin/./BDMESG |grep "Ozmosis")
    devicenode=$( echo -e "$diskscan" | grep "Device Node:" | sed "s/.*://g" | xargs )
    devicenodemain=$( echo -e "$devicenode" | sed "s/s[0-9]//g" )
    drivemodel=$( diskutil info $devicenodemain |grep "Media Name:" | sed "s/.*://g" |xargs )
    devicelocation=$( echo -e "$diskscan" | grep "Device Location:" | sed "s/.*://g" | xargs )
    removablemedia=$( echo -e "$diskscan" | grep "Removable Media:" | sed "s/.*://g" | xargs )
    mounted=$( echo -e "$diskscan" | grep "Mounted:" | sed "s/.*://g" | xargs )
    mountpoint=$( echo -e "$diskscan" | grep "Mount Point:" | sed "s/.*://g" | xargs )
    solidstate=$( echo -e "$diskscan" | grep "Solid State:" | sed "s/.*://g" | xargs )
    protocol=$( echo -e "$diskscan" | grep "Protocol:" | sed "s/.*://g" | xargs )
    kuroot=$( pwd | sed "s/\/Kext.*//g" )

    if [[ $mountpoint != "" ]];then
        efipath=$( find "$mountpoint" -name "config.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
        if [[ $efipath = "" ]]; then
            efipath=$( find "$mountpoint" -name "Default.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
        fi
    fi

    if [[ -d /Library/Extensions/AppleAHCIPortHotplug.kext ]]; then
    defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "SATAHotplug" -bool YES
    else
    defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "SATAHotplug" -bool NO
    fi

    if [[ "$ozmosischeck" != "" ]]; then
        bootloader="Ozmosis"
    else
        if [[ "$clovermode" = "UEFI" ]]; then
            bootloader="Clover - UEFI"
        else
            bootloader="Clover - Legacy"
        fi
    fi

    _helpDefaultWrite "EFI Path" "$efipath" &
    _helpDefaultWrite "EFI Root" "$efiroot" &
    _helpDefaultWrite "EFI Name" "$efiname" &
    _helpDefaultWrite "KU Root" "$kuroot" &
    _helpDefaultWrite "Device Node" "$devicenode" &
    _helpDefaultWrite "Device Location" "$devicelocation" &
    _helpDefaultWrite "Removable Media" "$removablemedia" &
    _helpDefaultWrite "Solid State" "$solidstate" &
    _helpDefaultWrite "Removable Media" "$removablemedia" &
    _helpDefaultWrite "Mounted" "$mounted" &
    _helpDefaultWrite "Mount Point" "$mountpoint" &
    _helpDefaultWrite "Drive Model" "$drivemodel" &
    _helpDefaultWrite "Device Protocol" "$protocol" &
    _helpDefaultWrite "Bootloader" "$bootloader" &    

    _setrootuser

    rootuser=$( _helpDefaultRead "Rootuser" )
}

#################################################################
####################### Mount Bootefi  ##########################
#################################################################

function mountefi()
{

    initial

    efiroot=$( _helpDefaultRead "EFI Root" )
    mounted=$( _helpDefaultRead "Mounted" )
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    admin=$( _helpDefaultRead "Admin" )

    if [[ $mounted = "Yes" ]]; then
        if [[ $keychain = "1" ]]; then
          _getsecret
          osascript -e 'do shell script "diskutil unmount '$efiroot'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
        else
          osascript -e 'do shell script "diskutil unmount '$efiroot'" with administrator privileges' >/dev/null 2>&1
        fi
        if [ $? = 0 ]; then
          _helpDefaultWrite "Mounted" "No"
        fi
    else
        if [[ $keychain = "1" ]]; then
          _getsecret
          osascript -e 'do shell script "diskutil mount '$efiroot'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
        else
          osascript -e 'do shell script "diskutil mount '$efiroot'" with administrator privileges' >/dev/null 2>&1
        fi
        status="$?"
        if [ $status = "0" ]; then
            _helpDefaultWrite "Mounted" "Yes"
        fi
        if [ $status != "0" ]; then
          node=$( ../bin/./BDMESG |grep -e "SelfDevicePath" -e "Found Storage" |sed -e 's/.*GPT,//' -e 's/,0x.*//' )
            if [[ $keychain = "1" ]]; then
              _getsecret
              osascript -e 'do shell script "diskutil mount '$node'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
            else
              osascript -e 'do shell script "diskutil mount '$node'" with administrator privileges' >/dev/null 2>&1
            fi
            if [ $? = 0 ]; then
              _helpDefaultWrite "Mounted" "Yes"
            fi
        fi
        efiscan=$( ../bin/./BDMESG |grep -e "SelfDevicePath" -e "Found Storage" | sed -e s/".*GPT,//g" -e "s/.*MBR,//g" -e "s/,.*//g" | xargs )
        diskscan=$( diskutil info $efiscan )
        mountpoint=$( echo -e "$diskscan" | grep "Mount Point:" | sed "s/.*://g" | xargs )
        _helpDefaultWrite "Mount Point" "$mountpoint"

        if [[ $mountpoint != "" ]];then
            efipath=$( find "$mountpoint" -name "config.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
            if [[ $efipath = "" ]]; then
                efipath=$( find "$mountpoint" -name "Default.plist" |sed -e "s/\.//g" -e "s/con.*//g" |grep -v "Trashes" )
            fi
        fi

        _helpDefaultWrite "EFI Path" "$efipath"
    fi
    exit 0
}

###################################################################
####################### Mainscript Function #######################
###################################################################

function mainscript()
{
#========================= Script Pathes =========================#
    ScriptDownloadPath=$( _helpDefaultRead "Downloadpath" )

#========================== Set Variables =========================#
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    url=$( echo -e "$content" | grep "Updater URL" | sed "s/.*\=\ //g" | xargs )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    username=$( echo -e "$content" | grep "User Name" | sed "s/.*\=\ //g" | xargs )
    realname=$( echo -e "$content" | grep "Full Name" | sed "s/.*\=\ //g" | xargs )
    efiroot=$( echo -e "$content" | grep "EFI Root" | sed "s/.*\=\ //g" | xargs )
    kexte=$( echo -e "$content" | grep "Choice" | sed "s/.*\=\ //g" | xargs )
    webdr2=$( echo -e "$content" | grep "Webdriver Build" | sed "s/.*\ \-//g" | xargs )
    singlekext=$( echo -e "$content" | grep "Load Single Kext" | sed "s/.*\=\ //g" | xargs )
    nightly=$( echo -e "$content" | grep "Clover Nightly" | sed "s/.*\=\ //g" | xargs )
    osuser=$( echo $realname )
    hour=$( date "+%H" )
    notifications=$( echo -e "$content" | grep "Notifications" | sed "s/.*\=\ //g" | xargs )
    notificationsseconds=$( echo -e "$content" | grep "NotificationSeconds" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    os=$( _helpDefaultRead "OSVersion" )
    overview=$( curl -sS -A "curl/osx - $os - $lan2" https://$url/overview.html )

    speakervolume=$( _helpDefaultRead "Speakervolume" | sed "s/\..*//g" )
    speakervolume=$( echo 0."$speakervolume" )

#========================= Check APFS =========================#
function _apfscheck()
{
    apfscheck=$( ../bin/./BDMESG |grep "APFS driver" ) # Checks if apfs.efi is loaded

    if [ -d /Volumes/ESP ]; then
        efipath="ESP"
    else
        efipath="EFI"
    fi

    if [[ $apfscheck != "" ]]; then
        if [ ! -d /Volumes/$efipath ]; then
            efi="off"
            diskutil mount $efiroot >/dev/null 2>&1
            apfstrash=$( find /Volumes/$efipath/.Trashes -name "apfs.efi" )
            if [ -f $apfstrash ]; then # Deletes apfs.efi from Trashcan if its there
                rm $apfstrash >/dev/null 2>&1
            fi
        fi
        if [ -d /Volumes/$efipath ]; then
            apfstrash=$( find /Volumes/$efipath/.Trashes -name "apfs.efi" )
            if [ -f $apfstrash ]; then # Deletes apfs.efi from Trashcan if its there
                rm $apfstrash >/dev/null 2>&1
            fi
                apfspath=$( find /Volumes/$efipath -name "apfs.efi" |head -n 1 )
            if [[ $apfspath = *apfs.efi* ]]; then # Check if apfs.efi is in place
                apfs=$( cat "$apfspath" |xxd | grep -A 2 APFS | head -n 2 | tail -n 1 | sed -e "s/.*\ \ //g" -e "s/\.\.\..*//g" -e "s/\///g" )
            fi
        fi
        if [[ $efi = "off" ]]; then #If the EFI wasn´t mounted before executing the Kext Updater it will be unmounted "politely"
            if [[ $efipath = "EFI" ]]; then
                diskutil umount $efiroot >/dev/null 2>&1
            fi
        fi
    fi
}

#========================= Check for nVidia Webdriver =========================#
checkweb=$( echo -e "$kextstats" |grep web.GeForceWeb )
if [[ $checkweb != "" ]]; then
    locweb=$( cat /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist |grep NVDAStartupWeb\ | sed -e "s/.*Web\ //g" -e "s/<\/.*//g" |cut -c 10-99 )
    kextstats=$( echo -e "$kextstats" "\nNVDAStartupWeb ($locweb)" )
fi

#========================= Add Non-Kext Values =========================#
bdmesg=$( ../bin/./BDMESG |grep "Clover revision" |sed -e "s/.*revision:\ /Clover\ (/g" -e "s/\ on.*/)/g" )
kextstats=$( echo -e "$kextstats" "\n$bdmesg" )
kextstats=$( echo -e "$kextstats" |sed "s/d0)/)/g" )
kextstats=$( echo -e "$kextstats" "\nAPFS ($apfs)" )

#========================= Get loaded Kexts =========================#
_excludedkexts

#========================= Ozmosis Warning =========================#
function _ozmosis()
{
    ../bin/./BDMESG | grep "Ozmosis" > /dev/null
    if [[ $? = "0" ]]; then
        echo $ozmosis
        echo " "
    fi
}

#========================= Output Headline =========================#
function _printHeader()
{
    if [ $hour -lt 12 ]; then
        echo $greet1
    elif [ $hour -lt 18 ]; then
        echo $greet2
    else
        echo $greet3
    fi
        echo " "
}

#========================= KextUpdate =========================#
function _kextUpdate()
{
    for kextList in "${kextArray[@]}"
        do
            IFS=","
            data=($kextList)
            name=${data[0]}
            lecho=$( echo -e "$kextstats" |grep ${data[1]} | sed -e "s/.*(//g" -e "s/).*//g" )
            local=$( echo $lecho | sed -e "s/\.//g" )
            if ! [[ $local = "" ]]; then
                echo "$checkver ${data[2]} ..."
                if ! [[ -z ${data[3]} ]] ; then # veralteter Kext
                    _obsoleteKext
                fi
                if ! [[ -z ${data[4]} ]] ; then # Needs Lilu Kext
                    echo ""
                    echo "$alarm"
                    echo ""
                fi
                remote=$( echo -e "$overview" |grep -w $name |sed -e "s/.*-//g" -e "s/+.*//g" )
                recho=$( echo -e "$overview" |grep -w $name |sed "s/.*+//g" )
                if [ -f ${ScriptDownloadPath}/${name}/.version.htm ]; then
                    dupe=$( cat ${ScriptDownloadPath}/${name}/.version.htm )
                    if [[ $dupe = $remote ]]; then
                        _dupeKext
                    fi
                else
                    returnVALUE=$(expr $local '<' $remote)
                    if [[ $returnVALUE == "1" ]]; then
                        mkdir -p ${ScriptDownloadPath} ${ScriptDownloadPath}/${name}
                        _toUpdate
                        curl -sS -o ${ScriptTmpPath}/${name}.zip https://$url/${name}/${name}.zip
                        curl -sS -o ${ScriptDownloadPath}/$name/.version.htm https://$url/${name}/version.htm
                        unzip -o -q ${ScriptTmpPath}/${name}.zip -d ${ScriptDownloadPath}/${name}
                        rm ${ScriptTmpPath}/${name}.zip 2> /dev/null
                        find ${ScriptDownloadPath}/. -name "Debug" -exec rm -r "{}" \; >/dev/null 2>&1
                        find ${ScriptDownloadPath}/. -name "LICENSE" -exec rm -r "{}" \; >/dev/null 2>&1
                        find ${ScriptDownloadPath}/. -name "READM*" -exec rm -r "{}" \; >/dev/null 2>&1
                        mv ${ScriptDownloadPath}/$name/Release/* ${ScriptDownloadPath}/$name/ >/dev/null 2>&1; rm -r ${ScriptDownloadPath}/$name/Release >/dev/null 2>&1
                        echo "${data[2]}" >> ${ScriptTmpPath}/kextloaded
                    else
                        _noUpdate
                    fi
                fi
            fi
        done
        _helpDefaultWrite "Clover Nightly" ""
}

#============================== KextLoad ==============================#
function _kextLoader()
{
    for kextLoadList in "${kextLoadArray[@]}"
        do
            IFS=","
            data=($kextLoadList)
            name=${data[0]}
            if [[ $nightly = "9" ]]; then
                name="clovernightly"
            fi
            mkdir -p ${ScriptDownloadPath} ${ScriptDownloadPath}/${name}
            _toUpdateLoad
            curl -sS -o ${ScriptTmpPath}/${name}.zip https://$url/${name}/${name}.zip
            curl -sS -o ${ScriptDownloadPath}/$name/.version.htm https://$url/${name}/version.htm
            unzip -o -q ${ScriptTmpPath}/${name}.zip -d ${ScriptDownloadPath}/${name}
            rm ${ScriptTmpPath}/${name}.zip 2> /dev/null
    done
}

#========================= KextReport =========================#
function _kextReport()
{
    kextstats=$( kextstat | grep -v com.apple )
    date > "$ScriptReportPath"/kextreport.txt
    echo "" >> "$ScriptReportPath"/kextreport.txt
    sw_vers |tail -n2 >> "$ScriptReportPath"/kextreport.txt
    echo "" >> "$ScriptReportPath"/kextreport.txt
    echo "$kextloaded" >> "$ScriptReportPath"/kextreport.txt
    echo "────────────────" >> "$ScriptReportPath"/kextreport.txt
    for kextList in "${kextArray[@]}"
        do
            IFS=","
            data=($kextList)
            name=${data[0]}
            lecho=$( echo -e "$kextstats" |grep ${data[1]} | sed -e "s/.*(//g" -e "s/).*//g" )
            local=$( echo $lecho | sed -e "s/\.//g" )
            if ! [[ $local = "" ]]; then
                echo "${data[2]}" "($lecho)" >> "$ScriptReportPath"/kextreport.txt
            fi
    done
    echo "────────────────" >> "$ScriptReportPath"/kextreport.txt
    echo "" >> "$ScriptReportPath"/kextreport.txt
    kextstat | grep AppleHDA\ \( > /dev/null
    if [ $? = 0 ]; then
        echo "$hdaloaded" >> "$ScriptReportPath"/kextreport.txt
    else
        echo "$hdanotloaded" >> "$ScriptReportPath"/kextreport.txt
    fi
    echo "" >> "$ScriptReportPath"/kextreport.txt
    echo "$reportpath": >> "$ScriptReportPath"/kextreport.txt
    echo "$ScriptReportPath"/kextreport.txt >> "$ScriptReportPath"/kextreport.txt

    cat "$ScriptReportPath"/kextreport.txt
}

#========================= Helpfunction Update =========================
function _toUpdate()
{
    _PRINT_MSG "☝🏼 $upd1\n
    $upd2 $lecho
    $upd3 $recho\n\n
    $loading\n────────────────\n"
}

function _toUpdateLoad()
{
    namec=$( echo $name | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}' )
    _PRINT_MSG "$namec $dloading\n────────────────"
}

#========================= Helpfunction no Duplicates =========================#
function _dupeKext()
{
    _PRINT_MSG "$dupekext\n────────────────"
}

#========================= Helpfunction no Kext =========================#
function _noUpdate()
{
    _PRINT_MSG "👍🏼 $upd4 ($lecho)\n────────────────"
}

#========================= Helpfunction obsolete Kext =========================#
function _obsoleteKext()
{
    _PRINT_MSG "$obsolete1 ${data[2]} $obsolete2 ${data[3]} $obsolete3"
}
#========================= Helpfunction Message =========================#
function _PRINT_MSG()
{
    local message=$1
    printf "${message}\n"
}

#============================== Webdriver ==============================#
function _nvwebdriver()
{
    mkdir -p "$ScriptDownloadPath/nVidia Webdriver"
    echo Build $webdr2 $webdrload
    curl -sS -o "$ScriptDownloadPath/nVidia Webdriver/$webdr2.pkg" https://$url/nvwebdriver/$webdr2.pkg
    echo " "
    if [[ $checkchime = "1" ]]; then
        _playchime
    fi
    echo $webdrloaded
    exit 0
}

#============================== Cleanup Files ==============================#
function _cleanup()
{
    if [ -d $ScriptDownloadPath ]; then
    find $ScriptDownloadPath/ -name *.dSYM -exec rm -r {} \; >/dev/null 2>&1
    find $ScriptDownloadPath/ -name __MACOSX -exec rm -r {} \; >/dev/null 2>&1
    fi
    if [ -f ${ScriptTmpPath}/kextloaded ]; then
        rm ${ScriptTmpPath}/kextloaded
    fi
}

#============================== Kext Updater Last Run ==============================#
function _lastcheck()
{
    lastcheckfunc=$( _helpDefaultRead "Last Check" )
    if [[ $lastcheckfunc != "Never" ]]; then
        echo $lastcheck
        echo $lastcheckfunc
        echo " "
    fi
}

#============================== Main Function ==============================#
function _main()
{
    if [[ $1 == kextUpdate ]]; then
        _printHeader
        _lastcheck
    fi
    if [[ $1 == kextUpdate ]]; then
        _kextUpdate
        if [[ $notifications = "true" ]]; then
            if [ -f ${ScriptTmpPath}/kextloaded ]; then
                amount=$( cat "$ScriptTmpPath/kextloaded" | wc -l | xargs )
                ScriptDownloadPath=$( _helpDefaultRead "Downloadpath" )
                getdate=`date`
                echo -e "\n================================================================================" >> "$ScriptDownloadPath"/logging.txt
                echo -e "========================= ""$getdate"" =========================" >> "$ScriptDownloadPath"/kulog.txt
                echo -e "================================================================================\n" >> "$ScriptDownloadPath"/logging.txt
                cat ~/Documents/.kulog >> "$ScriptDownloadPath"/logging.txt
                rm ~/Documents/.kulog
            else
                amount="0"
            fi
            ../bin/./alerter -message "$notify1 $amount" -title "Kext Updater" -timeout $notificationsseconds & > /dev/null
        fi
    elif [[ $1 == kextLoader ]]; then
        _kextLoader
        if [[ $notifications = "true" ]]; then
            ../bin/./alerter -message "$notify2" -title "Kext Updater" -timeout $notificationsseconds & > /dev/null
        fi
    elif [[ $1 == htmlreport ]]; then
        htmlreport
        if [[ $notifications = "true" ]]; then
            ../bin/./alerter -message "$notify3" -title "Kext Updater" -timeout $notificationsseconds & > /dev/null
        fi
    fi
    _ozmosis

    echo ""
    echo "$webdrloaded"
    cp /Users/luigi/Documents/.kulog /Users/luigi/.
    _cleanup
    if [[ $checkchime = "1" ]]; then
        _playchime
    fi
}

#============================== Choice ==============================#
if [ $kexte = "1" ]; then
    _main "kextUpdate"
    exit 0
fi

if [ $kexte = "2" ]; then
    kextLoadArray=("fakesmc" "usbinjectall" "voodoops2")
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "3" ]; then
    kextLoadArray=("applealc" "lilu" "codeccommander")
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "4" ]; then
    kextLoadArray=("whatevergreen" "lilu")
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "5" ]; then
    kextLoadArray=("atherose2200ethernet" "intelmausiethernet" "realtekrtl8111")
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "m" ]; then
    if [ ! -f "$ScriptTmpPath"/massdownload ]; then
        if [[ $checkchime = "1" ]]; then
        _playchimedeath
        fi
        echo "$nokextselected"
        exit 0
    fi
    source /tmp/kextupdater/array
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "8" ]; then
    kextLoadArray=("clover")
    recho="Kexte"
    _main "kextLoader"
    exit 0
fi

if [ $kexte = "r" ]; then
    _main "htmlreport"
    exit 0
fi

if [ $kexte = "b" ]; then
    if [[ $webdr2 = "Webdriver Build =" ]]; then
            if [[ $checkchime = "1" ]]; then
                _playchimedeath
            fi
        echo "$nowebselected"
    else
        _nvwebdriver
    fi
    exit 0
fi

if [ $kexte = "d" ]; then
    if [[ $singlekext = "" ]]; then
        echo "$nokextselected"
            if [[ $checkchime = "1" ]]; then
                _playchimedeath
            fi
    else
        kextchoice=$( _helpDefaultRead "Load Single Kext" )
        kextLoadArray=("$kextchoice")
        recho="Kexte"
        _main "kextLoader"
    fi
    exit 0
fi

#=========================== START ===========================#
_main "kextUpdate"
exit 0
#=============================================================#
}

###################################################################
######################## Rebuild Kext-Cache #######################
###################################################################

function rebuildcache()
{
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    if [[ $keychain = "1" ]]; then
      _getsecret
      echo -e "$rebuildcache\n"
      osascript -e 'do shell script "chmod -R 755 /System/Library/Extensions/*; sudo chown -R root:wheel /System/Library/Extensions/*; sudo touch /System/Library/Extensions; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo kextcache -u / -v 6" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
    echo -e "$rebuildcache\n"
      osascript -e 'do shell script "chmod -R 755 /System/Library/Extensions/*; sudo chown -R root:wheel /System/Library/Extensions/*; sudo touch /System/Library/Extensions; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo kextcache -u / -v 6" with administrator privileges' >/dev/null 2>&1
    fi
    if [ $? = 0 ]; then
            if [[ $checkchime = "1" ]]; then
                _playchime
            fi
        echo "$webdrloaded"
        else
            if [[ $checkchime = "1" ]]; then
                _playchimedeath
            fi
        echo -e "$error"
    fi
}

###################################################################
############################# Exit App ############################
###################################################################

function exitapp()
{
    ScriptDownloadPath=$( _helpDefaultRead "Downloadpath" )
    if [ -d $ScriptDownloadPath ]; then
    find "$ScriptDownloadPath" -name ".version.htm" -exec rm {} \;
    fi

    ScriptTempPath=$( _helpDefaultRead "Temppath" )
    if [ -d $ScriptTempPath ]; then
    rm -r "$ScriptTempPath"
    fi

    pkill "Kext Updater"
}

###################################################################
################ Reset Preferences and restart App ################
###################################################################

function resetprefs()
{
    pid=$(_helpDefaultRead "Pid")
    kuroot=$(_helpDefaultRead "KU Root")
    echo "rm ~/Library/Preferences/com.slsoft.kextupdater.plist" > /tmp/kurestarter
    echo "kill -term $pid" >> /tmp/kurestarter
    echo "osascript -e 'tell application \"Kext Updater\" to quit'" >> /tmp/kurestarter
    echo "sleep 1" >> /tmp/kurestarter
    echo "open \"$kuroot\"/Kext\\ Updater.app" >> /tmp/kurestarter
    echo "rm /tmp/kurestarter" >> /tmp/kurestarter
    bash /tmp/kurestarter
}

###################################################################
####################### Kext Mass Download ########################
###################################################################

function massdownload()
{
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    if [ -f "$ScriptTmpPath"/massdownload ]; then
        rm "$ScriptTmpPath"/massdownload
    fi

    array=($allkextslower)
    for i in "${array[@]}"; do
        check=$( echo -e "$content" | grep -w "$i" | sed "s/.*\=\ //g" | xargs )
        if [[ $check = "true" ]]; then
            echo "$i" >> "$ScriptTmpPath"/massdownload
        fi
        if [[ $check != "" ]]; then
            _helpDefaultDelete "$i"
        fi
    done

    cat "$ScriptTmpPath"/massdownload | sed -e 's/^/"/' -e 's/$/"\ /' | tr -d '\n' > "$ScriptTmpPath"/massdownload2
    kexts=$( cat "$ScriptTmpPath"/massdownload2 )
    echo "kextLoadArray=($kexts)" | sed "s/\ )/)/g" > "$ScriptTmpPath"/array

    if [ -f "$ScriptTmpPath"/massdownload ]; then
        echo "$massdlready"
        else
        echo "$nokextselected"
            if [[ $checkchime = "1" ]]; then
                _playchimedeath
            fi
    fi
    exit 0
}

###################################################################
##################### Reset excluded Kexts ########################
###################################################################
function excludereset()
{
    array=($allkextsupper)
    for i in "${array[@]}"; do
      _helpDefaultDelete "ex-$i" 2> /dev/null
    done
    exit 0
}

###################################################################
##################### Reset selected Kexts ########################
###################################################################
function deselectall()
{
    array=($allkextslower)
    for i in "${array[@]}"; do
      _helpDefaultDelete "$i" 2> /dev/null
    done
    exit 0
}

###################################################################
####################### Select all Kexts #########################
###################################################################
function selectall()
{
    array=($allkextslower)
    for i in "${array[@]}"; do
      defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "$i" -bool YES
    done
    exit 0
}

###################################################################
##################### Reset selected Kexts ########################
###################################################################
function selectedreset()
{
    array=($allkextlower)
    for i in "${array[@]}"; do
      _helpDefaultDelete "$i" 2> /dev/null
    done
    exit 0
}

###################################################################
##################### Kext Updater Daemon #########################
###################################################################
function kudaemon()
{
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    url=$( echo -e "$content" | grep "Updater URL" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    _excludedkexts

    echo "$kextstats" | tr '[:upper:]' '[:lower:]' > "$ScriptTmpPath"/daemon_kextstat

    curl -sS -A "KU Daemon" -o "$ScriptTmpPath"/daemon_overview https://$url/overview.html

    while IFS='' read -r line || [[ -n "$line" ]]; do
        kext=$( echo "$line" |sed "s/-.*//g" )
        kstat=$( grep -w "$kext" "$ScriptTmpPath"/daemon_kextstat | sed -e "s/.*(//g" -e "s/).*//g" -e "s/\.//g" -e "s/d0//g" )
        kover=$( grep -w "$kext" "$ScriptTmpPath"/daemon_overview | sed -e "s/.*-//g" -e "s/+.*//g" )

        if [[ $kstat != "" ]]; then
            if [[ "$kover" -gt "$kstat" ]]; then
                touch "$ScriptTmpPath"/daemon_notify
            fi
        fi
    done < "$ScriptTmpPath"/daemon_overview

    if [ -f "$ScriptTmpPath"/daemon_notify ]; then
        kuroot=$( _helpDefaultRead "KU Root" )
        ANSWER="$(../bin/./alerter -message "$daemonnotify" -title "Kext Updater Daemon" -actions "$openkextupdater" -closeLabel "$daemonnotifyclose" -appIcon https://update.kextupdater.de/kextupdater/appicon.png)"
        case $ANSWER in
        "$openkextupdater") open "$kuroot"/Kext\ Updater.app ;;
        esac
        rm "$ScriptTmpPath"/daemon_*
    fi
    exit 0
}

###################################################################
################ Kext Updater Daemon LoginItem ####################
###################################################################
function loginitem_on()
{

    kuroot=$( _helpDefaultRead "KU Root" | sed -e "s/$/\/Kext\ Updater.app\/Contents\/Resources\/bin\/KUDaemon.app/" )
    osascript -e 'tell application "System Events" to delete login item "KUDaemon"' > /dev/null
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"'"$kuroot"'", hidden:false}' > /dev/null
}

function loginitem_off()
{
    osascript -e 'tell application "System Events" to delete login item "KUDaemon"' > /dev/null
}

###################################################################
################ Copy Atheros40 Kext to /S/L/E ####################
###################################################################
function ar92xx()
{
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    kuroot=$( _helpDefaultRead "KU Root" )

    _languageselect

    if [[ $keychain = "1" ]]; then
    _getsecret
    echo "$atherosinstall"
    osascript -e 'do shell script "cp -r '"'$kuroot'"'/Kext\\ Updater.app/Contents/Resources/kexts/AirPortAtheros40.kext /Library/Extensions/.; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
    echo "$atherosinstall"
    osascript -e 'do shell script "cp -r '"'$kuroot'"'/Kext\\ Updater.app/Contents/Resources/kexts/AirPortAtheros40.kext /Library/Extensions/.; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" with administrator privileges' >/dev/null 2>&1
    fi
    if [ $? = 0 ]; then
            if [[ $checkchime = "1" ]]; then
                afplay -v "$speakervolume" ../sounds/done.mp3 &
            fi
        echo -e "\n$webdrloaded"
        else
            if [[ $checkchime = "1" ]]; then
                afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
            fi
        echo -e "\n$error"
    fi
}

###################################################################
######################## AHCIPort Hotplug #########################
###################################################################
function satahotpluginstall()
{
user=$( _helpDefaultRead "Rootuser" )
keychain=$( _helpDefaultRead "Keychain" )
content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
kuroot=$( _helpDefaultRead "KU Root" )

_languageselect

if [[ $keychain = "1" ]]; then
_getsecret
echo "$ahciportinstall"
osascript -e 'do shell script "cp -r '"'$kuroot'"'/Kext\\ Updater.app/Contents/Resources/kexts/AppleAHCIPortHotplug.kext /Library/Extensions/.; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
else
echo "$ahciportinstall"
osascript -e 'do shell script "cp -r '"'$kuroot'"'/Kext\\ Updater.app/Contents/Resources/kexts/AppleAHCIPortHotplug.kext /Library/Extensions/.; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" with administrator privileges' >/dev/null 2>&1
fi
if [ $? = 0 ]; then
if [[ $checkchime = "1" ]]; then
afplay -v "$speakervolume" ../sounds/done.mp3 &
fi
echo -e "\n$webdrloaded"
else
if [[ $checkchime = "1" ]]; then
afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
fi
echo -e "\n$error"
fi
}

function satahotpluguninstall()
{
user=$( _helpDefaultRead "Rootuser" )
keychain=$( _helpDefaultRead "Keychain" )
content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
kuroot=$( _helpDefaultRead "KU Root" )

_languageselect

if [[ $keychain = "1" ]]; then
_getsecret
echo "$ahciportuninstall"
osascript -e 'do shell script "rm -r /Library/Extensions/AppleAHCIPortHotplug.kext; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
else
echo "$ahciportuninstall"
osascript -e 'do shell script "rm -r /Library/Extensions/AppleAHCIPortHotplug.kext; sudo chmod -R 755 /Library/Extensions/*; sudo chown -R root:wheel /Library/Extensions/*; sudo touch /Library/Extensions; sudo kextcache -i /; sudo touch /Library/Extensions; sudo kextcache -u / -v 6" with administrator privileges' >/dev/null 2>&1
fi
if [ $? = 0 ]; then
if [[ $checkchime = "1" ]]; then
afplay -v "$speakervolume" ../sounds/done.mp3 &
fi
echo -e "\n$webdrloaded"
else
if [[ $checkchime = "1" ]]; then
afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
fi
echo -e "\n$error"
fi
}

###################################################################
########################## Fix Sleepimage  ########################
###################################################################

function fixsleepimage()
{
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    pwcheck=$( pmset -g |grep proximitywake )

    _languageselect

    if [[ $keychain = "1" ]]; then
      _getsecret
      echo "$fixsleepimage"
        if [[ $pwcheck != "" ]]; then
          osascript -e 'do shell script "pmset -a hibernatemode 0; pmset -a proximitywake 0; cd /private/var/vm/; sudo rm sleepimage; sudo touch sleepimage; sudo chflags uchg /private/var/vm/sleepimage" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
        else
          osascript -e 'do shell script "pmset -a hibernatemode 0; cd /private/var/vm/; sudo rm sleepimage; sudo touch sleepimage; sudo chflags uchg /private/var/vm/sleepimage" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
        fi
    else
      echo "$fixsleepimage"
        if [[ $pwcheck != "" ]]; then
          osascript -e 'do shell script "pmset -a hibernatemode 0; pmset -a proximitywake 0; cd /private/var/vm/; sudo rm sleepimage; sudo touch sleepimage; sudo chflags uchg /private/var/vm/sleepimage" with administrator privileges' >/dev/null 2>&1
        else
          osascript -e 'do shell script "pmset -a hibernatemode 0; cd /private/var/vm/; sudo rm sleepimage; sudo touch sleepimage; sudo chflags uchg /private/var/vm/sleepimage" with administrator privileges' >/dev/null 2>&1
        fi
    fi

    if [ $? = 0 ]; then
            if [[ $checkchime = "1" ]]; then
                afplay -v "$speakervolume" ../sounds/done.mp3 &
            fi
        echo -e "\n$webdrloaded"
        else
            if [[ $checkchime = "1" ]]; then
                afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
            fi
        echo -e "\n$error"
    fi
}

###################################################################
############### Check if Sleepfix already applied #################
###################################################################

function checksleepfix()
{
    chmodcheck=$( stat -f %A /var/vm/sleepimage )
    chowncheck=$( ls -l /var/vm/sleepimage |cut -c 15-25 )
    size=$( stat -f%z /var/vm/sleepimage )
    hmcheck=$( pmset -g |grep hibernatemode | sed "s/.*e//g" | xargs )
    pwcheck=$( pmset -g |grep proximitywake )

    if [[ $chmodcheck = "644" ]]; then
        chmodcheck="0"
        else
        chmodcheck="1"
    fi

    if [ $size = 0 ]; then
        size="0"
        else
        size="1"
    fi

    if [[ $chowncheck = "root  wheel" ]]; then
        chowncheck="0"
        else
        chowncheck="1"
    fi

    if [[ $pwcheck != "" ]]; then
    pwcheck=$( pmset -g |grep proximitywake | sed "s/.*e//g" | xargs )
        if [[ $pwcheck = "0" ]]; then
            pwcheck="0"
        else
            pwcheck="1"
        fi
    else
    pwcheck="0"
    fi

    result=$( echo $chmodcheck+$size+$hmcheck+$chowncheck+$pwcheck | bc ) #If value is 0 the fix was already applied

    if [ $result = 0 ]; then
        defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "Sleepfix" -bool YES
    else
        defaults write "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" "Sleepfix" -bool NO
    fi
}

###################################################################
############### Show all loaded 3rd Party Kexts ###################
###################################################################

function thirdparty()
{
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    ../bin/./BDMESG | grep -w kext | sed -e "s/.*EFI/EFI/g" -e "s/(.*//g" -e "s/\\\/\//g" > "$ScriptTmpPath/kextpaths"
    system_profiler -detailLevel mini SPExtensionsDataType -xml | grep -w kext | sed -e "s/.*<string>//g" -e "s/<.*//g" >> "$ScriptTmpPath/kextpaths"
    kextstat=$( kextstat |grep -v apple |sed "s/\ (.*//g" | rev | cut -d '.' -f1 | rev | tail -n +2 )

    _languageselect

    echo -e "$thirdparty\n"

    while IFS='' read -r line || [[ -n "$line" ]]; do
    check=$( grep "$line" "$ScriptTmpPath/kextpaths" )
        if [[ $check = "" ]];then
          echo "$line"
          else
          echo "$check"
        fi
    done <<< "$kextstat"

    if [[ $checkchime = "1" ]]; then
      afplay -v "$speakervolume" ../sounds/done.mp3 &
    fi

    echo -e "\n$webdrloaded"
}

###################################################################
####################### Create Systemreport #######################
###################################################################

function sysreport()
{

    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    echo -e "$sysreport\n"

    system_profiler -detailLevel mini SPHardwareDataType SPAudioDataType SPNetworkDataType SPExtensionsDataType SPDisplaysDataType SPPCIDataType SPSoftwareDataType SPUSBDataType SPBluetoothDataType SPCameraDataType SPCardReaderDataType SPEthernetDataType SPFireWireDataType SPHardwareRAIDDataType SPNVMeDataType SPParallelSCSIDataType SPPowerDataType SPSASDataType SPSerialATADataType SPThunderboltDataType SPAirPortDataType -xml > "$ScriptTmpPath/SystemProfiler.spx"

    if [ -f /System/Library/LaunchDaemons/Niresh* ]; then
        ../bin/./PlistBuddy -c "Set 0:_items:0:SMC_version_system Distro!" "$ScriptTmpPath/SystemProfiler.spx"
        zip -jq "$ScriptHome/Desktop/Systemreport.zip" "$ScriptTmpPath/SystemProfiler.spx"
        else
        zip -jq "$ScriptHome/Desktop/Systemreport.zip" "$ScriptTmpPath/SystemProfiler.spx"
    fi

    if [[ $checkchime = "1" ]]; then
      afplay -v "$speakervolume" ../sounds/done.mp3 &
    fi

    echo -e "$reportpath\n""$ScriptHome/Desktop/Systemreport.zip"

    echo -e "\n$webdrloaded"
}

###################################################################
#################### Create HTML Systemreport #####################
###################################################################

function htmlreport()
{
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )
    kuroot2=$( _helpDefaultRead "KU Root" )
    bootloader2=$( _helpDefaultRead "Bootloader" )

    _languageselect

    if [[ $keychain = "1" ]]; then
    _getsecret
    fi

    echo -e "$collectingdata"

    ### EFI Check and mount ###
    checkefi=$( _helpDefaultRead "Mounted" )
    if [[ $checkefi = "No" ]]; then
      devnode=$( _helpDefaultRead "Device Node" )
      if [[ $keychain = "1" ]]; then
        osascript -e 'do shell script "diskutil mount '$devnode'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
      else
        osascript -e 'do shell script "diskutil mount '$devnode'" with administrator privileges' >/dev/null 2>&1
      fi
        if [[ $? = "0" ]]; then
          tempmnt="Yes"
        fi
    fi
    volumename=$( _helpDefaultRead "EFI Name" )

    ../bin/./BDMESG | grep "CLOVER" > /dev/null
    if [[ $? = "0" ]]; then
      efikind="CLOVER"
      bootloader="$bdmesg"
    else
      efikind="Oz"
      bootloader="Ozmosis"
    fi

    #### Check which Bootloader is used ####
    if [[ $efikind = "CLOVER" ]]; then
      mkdir "$ScriptTmpPath"/Report "$ScriptTmpPath"/Report/CLOVER >/dev/null 2>&1
      cp -r /Volumes/"$volumename"/EFI/CLOVER/ACPI /Volumes/"$volumename"/EFI/CLOVER/drivers* /Volumes/"$volumename"/EFI/CLOVER/kexts /Volumes/"$volumename"/EFI/CLOVER/config.plist "$ScriptTmpPath"/Report/CLOVER/.

      ../bin/./PlistBuddy -c "set SMBIOS:SerialNumber 000000000000" "$ScriptTmpPath"/Report/CLOVER/config.plist
      ../bin/./PlistBuddy -c "set SMBIOS:BoardSerialNumber 0000000000000" "$ScriptTmpPath"/Report/CLOVER/config.plist
      ../bin/./PlistBuddy -c "set SMBIOS:SmUUID 00000000-0000-0000-0000" "$ScriptTmpPath"/Report/CLOVER/config.plist
      ../bin/./PlistBuddy -c "set RtVariables:MLB 0000000000000" "$ScriptTmpPath"/Report/CLOVER/config.plist
      ../bin/./PlistBuddy -c "set SystemParameters:CustomUUID 00000000-0000-0000-0000-000000000000" "$ScriptTmpPath"/Report/CLOVER/config.plist
    fi

    if [[ $efikind = "Oz" ]]; then
      mkdir "$ScriptTmpPath"/Report "$ScriptTmpPath"/Report/Ozmosis >/dev/null 2>&1
      cp -r /Volumes/"$volumename"/EFI/Oz/Acpi /Volumes/"$volumename"/EFI/Oz/Darwin /Volumes/"$volumename"/EFI/Oz/Theme.bin /Volumes/"$volumename"/EFI/Oz/Defaults.plist "$ScriptTmpPath"/Report/Ozmosis/.

      ozserial=$( grep -A1 'SystemSerial' /Volumes/"$volumename"/EFI/Oz/Defaults.plist|grep -v "SystemSerial" | xargs | sed -e "s/<string>//g" -e "s/<\/string>//g" )

      ozbaseboardserial=$( grep -A1 'BaseBoardSerial' /Volumes/"$volumename"/EFI/Oz/Defaults.plist|grep -v "BaseBoardSerial" | xargs | sed -e "s/<string>//g" -e "s/<\/string>//g" )

      sed -ib "s/$ozserial/000000000000/g" "$ScriptTmpPath"/Report/Ozmosis/Defaults.plist
      sed -ib "s/$ozbaseboardserial/00000000000000000/g" "$ScriptTmpPath"/Report/Ozmosis/Defaults.plist
      rm "$ScriptTmpPath"/Report/Ozmosis/Defaults.plistb
    fi

    ### Fetching General Data ###
    date=$( date )
    swbuild=$( sw_vers |tail -n1 | sed "s/.*://g" | xargs )
    swversion=$( sw_vers |tail -n2 | head -n 1 | sed "s/.*://g" | xargs )
    hwspecs=$( system_profiler SPHardwareDataType SPDisplaysDataType )

    #sipcheck1=$( csrutil status | grep "Kext Signing" | sed "s/.*\://g" | xargs )
    #sipcheck2=$( csrutil status | grep "System Integrity Protection status" | sed -e "s/.*\://g" -e "s/\ (*//g" -e "s/\.//g" | xargs )
    #if [[ $sipcheck1 = "disabled" ]]; then
    #sipcheck="disabled"
    #elif [[ $sipcheck2 = "disabled" ]]; then
    #sipcheck="disabled"
    #fi

    kextstats=$( kextstat | grep -v com.apple | sort )
    ../bin/./BDMESG | grep -w kext | sed -e "s/.*EFI/EFI/g" -e "s/(.*//g" -e "s/\\\/\//g" | sort > "$ScriptTmpPath/kextpaths"
    system_profiler -detailLevel mini SPExtensionsDataType -xml | grep  kext | sed -e "s/.*<string>//g" -e "s/<.*//g" | grep -v Contents | sort >> "$ScriptTmpPath/kextpaths"
    kextstat |grep -v apple |sed "s/\ (.*//g" | rev | cut -d '.' -f1 | rev | tail -n +2 | sort > "$ScriptTmpPath"/kextstat

    ### Table "General" ###
    modelname=$( echo -e "$hwspecs" | grep "Model Name:" | sed "s/.*://g" | xargs )
    modelid=$( echo -e "$hwspecs" | grep "Model Identifier:" | sed "s/.*://g" | xargs )
    cpuname=$( sysctl -a | grep cpu.brand_ | sed "s/.*://g" | xargs )
    cores=$( echo -e "$hwspecs" | grep "Total Number of Cores:" | sed "s/.*://g" | xargs )
    memory=$( echo -e "$hwspecs" | grep "Memory:" | sed "s/.*://g" | xargs )
    gfx=$( echo -e "$hwspecs" | grep "Chipset Model:" | sed -e "s/.*:\ //g" -e "s/\//xtempx/g"  -e "1 s/.*/&<br>/g" |xargs )

    kextstat | grep AppleHDA\ \( > /dev/null
    if [ $? = 0 ]; then
        applehda="is loaded"
        else
        applehda="is not loaded"
    fi

    ### Table "Hackintosh Kexts" ###
    if [ -f "$ScriptTmpPath"/kextreport ]; then
        rm "$ScriptTmpPath"/kextreport
    fi
    for kextList in "${kextArray[@]}"
    do
    IFS=","
    data=($kextList)
    name=${data[0]}
    lecho=$( echo -e "$kextstats" |grep ${data[1]} | sed -e "s/.*(//g" -e "s/).*//g" )
    local=$( echo $lecho | sed -e "s/\.//g" )
        if ! [[ $local = "" ]]; then
          echo -e "<tr><th\>""${data[2]}""<\/th>""<th\>""$lecho""<\/th>""<\/tr>" >> "$ScriptTmpPath"/kextreport
        fi
    done

    ### Table "All loaded Non-Apple Kexts" ###
    if [ -f "$ScriptTmpPath"/kextreport2 ]; then
    rm "$ScriptTmpPath"/kextreport2
    fi
    while IFS='' read -r line; do
    check=$( grep "$line" "$ScriptTmpPath/kextpaths" )
        if [[ $check = "" ]];then
          kextpath=$( echo '<img src="https://update.kextupdater.de/kextupdater/images/unsure.png" height="17"></img>' )
          kextname=$( echo -e "$line"  | head -n 1 | sed -e "s@.*/@@" -e "s/.kext//g" )
          echo -e "<tr><th\>""$kextname""<\/th>""<th\>""$kextpath""<\/th>""<\/tr>" >> "$ScriptTmpPath"/kextreport2
        else
          kextpath=$( echo -e "$check" | head -n 1 | sed "s/\/[^\/]*$//" )
          kextname=$( echo -e "$check" | head -n 1 | sed -e "s@.*/@@" -e "s/.kext//g" )
          echo -e "<tr><th\>""$kextname""<\/th>""<th\>""$kextpath""<\/th>""<\/tr>" >> "$ScriptTmpPath"/kextreport2
        fi
    done < "$ScriptTmpPath"/kextstat

    ### Table "PCI Devices" ###
    lastcheck=$( _helpDefaultRead "PCIDB" )
    today=$( date +%s )
    calc1=$((today/86400))
    calc2=$((calc1-lastcheck))
    if [ $calc2 -gt 30 ]; then
      echo -e "\n$updatepcidb\n"
      curl -sS https://update.kextupdater.de/lspci/pciids.zip -o "$ScriptTmpPath"/pciids.zip
      unzip -jo "$ScriptTmpPath"/pciids.zip -d ../bin/lspci/ >/dev/null 2>&1
      _helpDefaultWrite "PCIDB" "$calc1"
     fi

    if [[ $keychain = "1" ]]; then
      osascript -e 'do shell script "cp -r ../kexts/lspcidrv.kext /tmp/; sudo chown -R root:wheel /tmp/lspcidrv.kext; sudo kextload /tmp/lspcidrv.kext" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
      osascript -e 'do shell script "cp -r ../kexts/lspcidrv.kext /tmp/; sudo chown -R root:wheel /tmp/lspcidrv.kext; sudo kextload /tmp/lspcidrv.kext" with administrator privileges' >/dev/null 2>&1
    fi

    ../bin/lspci/./lspci -mnn -i ../bin/lspci/pci.ids | sed -E 's/\[([A-Za-z ]+)\]/(\1)/g' | grep -v ignored |sed -e "s/\[GeForce/(GeForce/g" -e "s/\[AMD/(AMD/g" -e "s/\[Radeon/(Radeon/g" > "$ScriptTmpPath"/pci
    while IFS='' read -r line; do
    vendor=`echo -e "$line" | cut -d "[" -f3 | cut -d "]" -f1 | tr '[:lower:]' '[:upper:]'`
    device=`echo -e "$line" | cut -d "[" -f4 | cut -d "]" -f1 | tr '[:lower:]' '[:upper:]'`
    subven=`echo -e "$line" | cut -d "[" -f5 | cut -d "]" -f1 | tr '[:lower:]' '[:upper:]'`
    subdev=`echo -e "$line" | cut -d "[" -f6 | cut -d "]" -f1 | tr '[:lower:]' '[:upper:]'`
    vendorname=`echo -e "$line" | cut -d "\"" -f4 | cut -d "\"" -f1 | sed "s/\[.*//g" | xargs`
    devicename=`echo -e "$line" | cut -d "\"" -f6 | cut -d "\"" -f1 | sed "s/\[.*//g" | xargs`
        if [[ $subven = "" ]]; then
          subven="0000"
        fi
        if [[ $subdev = "" ]]; then
          subdev="0000"
        fi
    echo -e "<tr><td>""$vendor""</td>""<td>""$device""</td>""<td>""$subven""</td>""<td>""$subdev""</td>""<td>""$vendorname""</td>""<td>""$devicename""</td></tr>" | sed -e "s/:/\\\:/g" -e 's#/#\\/#g' | tr '\n' ' ' >> "$ScriptTmpPath"/pci2
    done < "$ScriptTmpPath"/pci

    powervars=`pmset -g | tail -n +3`
    while IFS='' read -r line; do
    powername=`echo -e "$line" | cut -c 1-22 | xargs`
    powervalue=`echo -e "$line" | cut -c 23-999 | xargs`
    echo -e "<tr><th>""$powername""</th>""<th>""$powervalue""</th>""</tr>" | sed -e 's#/#\\/#g'>> "$ScriptTmpPath"/powerm
    done <<< "$powervars"

    echo "$createreport"

    ### Merging HTML Report ###
    lspci=$( cat "$ScriptTmpPath/pci2" | tr '\n' ' ' | sed "s/]/)/g")
    power=$( cat "$ScriptTmpPath/powerm" | tr '\n' ' ' )
    hackkexts=$( cat "$ScriptTmpPath"/kextreport | tr '\n' ' ' )
    nonapplekexts=$( cat "$ScriptTmpPath"/kextreport2 | tr '\n' ' ' | tr '\/' '§' )
        if [ -f /System/Library/LaunchDaemons/Niresh* ]; then
          dis="dt"
          else
          dis=""
        fi

    sed -e "s/!DATE!/$date/g" -e "s/!SWVERSION!/$swversion/g" -e "s/!SWBUILD!/$swbuild/g"  -e "s/!MODELNAME!/$modelname/g" -e "s/!MODELID!/$modelid/g" -e "s/!CPUNAME!/$cpuname/g" -e "s/!CORES!/$cores/g" -e "s/!MEMORY!/$memory/g" -e "s/!GFX!/$gfx/g" -e "s/!APPLEHDA!/$applehda/g" -e "s/!BOOTLOADER!/$bootloader2/g" -e "s/!HACKKEXTS!/$hackkexts/g" -e "s/!NONAPPLEKEXTS!/$nonapplekexts/g" -e "s/!DIS!/$dis/g" -e "s/!LSPCI!/$lspci/g" -e "s/!POWER!/$power/g" ../html/report.html > "$ScriptTmpPath"/report2.html

    cat "$ScriptTmpPath"/report2.html | sed -e "s/xtempx/\//g" | tr '§' '\/' > "$ScriptTmpPath"/Report/Report.html

    path=$( echo "$PWD" )

    cd "$ScriptTmpPath"/Report

    zip -rq "$ScriptReportPath/Systemreport.zip" *

    echo -e "$reportdone\n"

    cd "$path"

    open "$ScriptTmpPath"/Report/Report.html

    rm "$ScriptTmpPath"/pci2 "$ScriptTmpPath"/powerm "$ScriptTmpPath"/kextreport "$ScriptTmpPath"/kextreport2 "$ScriptTmpPath"/kextpaths "$ScriptTmpPath"/kextstat "$ScriptTmpPath"/pci "$ScriptTmpPath"/report2.html >/dev/null 2>&1

    if [[ $keychain = "1" ]]; then   
      osascript -e 'do shell script "kextunload /tmp/lspcidrv.kext; sudo rm -rf /tmp/lspcidrv.kext" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
       osascript -e 'do shell script "kextunload /tmp/lspcidrv.kext; sudo rm -rf /tmp/lspcidrv.kext" with administrator privileges' >/dev/null 2>&1
    fi

    if [[ $tempmnt = "Yes" ]];then

    if [[ $keychain = "1" ]]; then
      osascript -e 'do shell script "diskutil unmount '$devnode'" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
      tempmnt=""
    else
      osascript -e 'do shell script "diskutil unmount '$devnode'" with administrator privileges' >/dev/null 2>&1
      tempmnt=""
    fi
    fi
}

###################################################################
####################### lspci Uninstaller #########################
###################################################################

function lspciuninstall()
{
    user=$( _helpDefaultRead "Rootuser" )
    keychain=$( _helpDefaultRead "Keychain" )
    content=$( ../bin/./PlistBuddy -c Print "${ScriptHome}/Library/Preferences/com.slsoft.kextupdater.plist" )
    lan2=$( echo -e "$content" | grep "Language" | sed "s/.*\=\ //g" | xargs )

    _languageselect

    if [ -f /usr/local/bin/lspci ]; then
      if [[ $keychain = "1" ]]; then
      _getsecret
      echo "$uninstalllspci"
      osascript -e 'do shell script "kextunload /Library/Extensions/lspcidrv.kext; sudo rm -rf /usr/local/bin/lspci /usr/local/bin/setpci /usr/local/bin/update-pciids /usr/local/share/pci.ids.gz /Library/Extensions/lspcidrv.kext; sudo chmod -Rf 755 /Library/Extensions; sudo chown -Rf 0:0 /Library/Extensions; sudo touch -f /Library/Extensions; sudo kextcache -system-prelinked-kernel" user name "'"$user"'" password "'"$passw"'" with administrator privileges' >/dev/null 2>&1
    else
      echo "$uninstalllspci"
      osascript -e 'do shell script "kextunload /Library/Extensions/lspcidrv.kext; sudo rm -rf /usr/local/bin/lspci /usr/local/bin/setpci /usr/local/bin/update-pciids /usr/local/share/pci.ids.gz /Library/Extensions/lspcidrv.kext; sudo chmod -Rf 755 /Library/Extensions; sudo chown -Rf 0:0 /Library/Extensions; sudo touch -f /Library/Extensions; sudo kextcache -system-prelinked-kernel" with administrator privileges' >/dev/null 2>&1
    fi
        if [ $? != 0 ]; then
            if [[ $checkchime = "1" ]]; then
              afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
            fi
          echo "$error"
        else
            if [[ $checkchime = "1" ]]; then
              afplay -v "$speakervolume" ../sounds/done.mp3 &
            fi
          echo "$webdrloaded"
        fi
    else
      echo "$nolspciinstalled"
            if [[ $checkchime = "1" ]]; then
              afplay -v "$speakervolume" ../sounds/quadradeath.mp3 &
            fi
    fi

}

$1


