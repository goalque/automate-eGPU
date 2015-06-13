#!/bin/sh
#
# Script (automate-eGPU.sh)
# This script automates Nvidia eGPU setup on OS X.
#
# Version 0.9 - Copyright (c) 2015 by goalque (goalque@gmail.com)
#
# 1) Detects your OS X product version and build version
# 2) Lists available web drivers from Nvidia
# 3) Automatic download and driver installation
# 4) Detects your Mac board-id and enables eGPU screen output
# 5) Tested: Mid 2014 rMBP Iris Pro, Late 2014 Mac mini
#

product_version="$(sw_vers -productVersion)"

echo "\nYour OS X version:" $product_version
echo "Your build version:" $(sw_vers -buildVersion)
echo "Searching available drivers...\n"

os_id2=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4&ParentID=73" | perl -pe 's/[\x0D]//g' \
| sed -E "s/.*<Name>Mac OS X Yosemite "$product_version$"<\/Name><Value>([0-9]+)<\/Value><\/LookupValue>.*/\1/")

list=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/processFind.aspx?psid=73&pfid=696&osid="$os_id2$"&lid=1&whql=&lang=en-us&ctk=0" | grep 'New in Release' | sed -E 's/.*in Release ([0-9]+\.[0-9]+\.[a-z0-9]+)\:.* ([0-9]+\.[0-9]+\.[0-9]+) \(([A-Z0-9]+)\).*/\1 for \2 (\3)/')

echo "Found the following matching drivers:"
echo "-------------------------------------"

echo "$list"

new=$(echo "$list" | sed -n 1p | sed -E "s/^([0-9]+\.[0-9]+\.[0-9a-z]+).*/\1/")

echo "-------------------------------------"
echo "Newest driver:\n\n" \
"http://us.download.nvidia.com/Mac/Quadro_Certified/"$new"/WebDriver-"$new$".pkg"

echo "Do you want to download this driver to your desktop (y/n)? "
read answer
if echo "$answer" | grep -iq "^y" ;then
    curl -o ~/Desktop/WebDriver-$new.pkg "http://us.download.nvidia.com/Mac/Quadro_Certified/"$new"/WebDriver-"$new$".pkg"
    echo "Driver downloaded."
else
    echo "Ok."
    exit
fi
echo "Modifying driver..."
pkgutil --expand ~/Desktop/WebDriver-$new.pkg expanded.pkg
sed -i '' -E "s/if \(\!validateHardware\(\)\) return false;/\/\/if \(\!validateHardware\(\)\) return false;/g" ~/Desktop/expanded.pkg/Distribution
sed -i '' -E "s/if \(\!validateSoftware\(\)\) return false;/\/\/if \(\!validateSoftware\(\)\) return false;/g" ~/Desktop/expanded.pkg/Distribution

pkgutil --flatten ~/Desktop/expanded.pkg ~/Desktop/WebDriver-$new.pkg

rm -rf ~/Desktop/expanded.pkg

echo "Driver mod done. Do you want to install (y/n)? "
read answer
if echo "$answer" | grep -iq "^y" ;then
volume_name=$(diskutil info / | awk '/Volume Name/ {print substr ($0, index ($0,$3))}')
/usr/sbin/installer -target /Volumes/"$volume_name" -pkg ~/Desktop/WebDriver-$new.pkg
else
    echo "Ok."
    exit
fi

/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:1:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist

/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:2:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist

/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:3:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist

/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool true" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist

/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:BuiltInHDA:IOPCITunnelCompatible bool true" /System/Library/Extensions/AppleHDA.kext/Contents/Plugins/AppleHDAController.kext/Contents/Info.plist

echo "IOPCITunnelCompatible mods done."

sudo /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:"$(ioreg -c IOPlatformExpertDevice -d 2 | grep board-id | sed "s/.*<\"\(.*\)\">.*/\1/")" string none" /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist

echo "Nvidia eGPU screen output enabled."

nvram boot-args="kext-dev-mode=1 nvda_drv=1"
touch /Extensions
kextcache -system-caches

echo "All ready. Please restart the Mac."
