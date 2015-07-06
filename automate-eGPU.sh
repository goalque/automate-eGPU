#!/bin/sh
#
# Script (automate-eGPU.sh)
# This script automates Nvidia eGPU setup on OS X.
#
# Version 0.9.3 - Copyright (c) 2015 by goalque (goalque@gmail.com)
#
# Licensed under the terms of the MIT license
#
# - Detects your OS X product version and build version
# - Automatic Nvidia web driver download and installation
# - Automatic IOPCITunnelCompatible mods + web driver mod
# - Detects your Mac board-id and enables eGPU screen output
# - Background services
#
#	Usage: 1) chmod +x automate-eGPU.sh
#          2) sudo ./automate-eGPU.sh
#          3) sudo ./automate-eGPU.sh -a
#

logname="$(logname)"
first_argument="$1"
product_version="$(sw_vers -productVersion)"
build_version="$(sw_vers -buildVersion)"
nvdatype=$(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDAType" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist)
web_driver=$(pkgutil --pkgs | grep "com.nvidia.web-driver")
system_updated_message="You are running official driver due to OS X update or web driver uninstall. In order to use eGPU, your system must be reconfigured. Click OK to execute automate-eGPU."
web_driver_exists_but_running_official=0
iopci_valid=0
board_id_exists=0
skipdriver=0
download_url=""
download_version=""
nvidia_app_support_path="/Library/Application Support/NVIDIA/"
test_path=""
install_path=""
reinstall=0
TMPDIR="/tmp/"
	
function GenerateDaemonPlist()
{

plist=`cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>automate-egpu-daemon</string>
	<key>KeepAlive</key>
	<false/>
	<key>RunAtLoad</key>
	<true/>
	<key>ProgramArguments</key>
	<array>
			<string>/usr/bin/automate-eGPU.sh</string>
			<string>-a2</string>
	</array>
</dict>
</plist>
EOF
`
echo "$plist" > /Library/LaunchDaemons/automate-eGPU-daemon.plist	
}

function GenerateAgentPlist()
{

plist=`cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>automate-egpu-agent</string>
	<key>KeepAlive</key>
	<false/>
	<key>RunAtLoad</key>
	<true/>
	<key>LaunchOnlyOnce</key>
	<true/>
	<key>ProgramArguments</key>
	<array>
			<string>/usr/bin/automate-eGPU.sh</string>
			<string>-a3</string>
	</array>
	<key>WatchPaths</key>
	<array>
		<string>/System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist</string>
	</array>
</dict>
</plist>
EOF
`
echo "$plist" > /Library/LaunchAgents/automate-eGPU-agent.plist	
}

function NVDARequiredOSCheck()
{
	is_match=0
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist) == "$build_version" ]] && is_match=1
}

function IOPCITunnelCompatibleCheck()
{
	echo "Checking IOPCITunnelCompatible keys...\n"
	isvalid1=0
	isvalid2=0
	isvalid3=0
	isvalid4=0
	isvalid5=0
	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:1:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist) == "true" ]] && isvalid1=1		
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:2:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist) == "true" ]] && isvalid2=1		
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:3:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist) == "true" ]] && isvalid3=1
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist) == "true" ]] && isvalid4=1		
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:BuiltInHDA:IOPCITunnelCompatible" /System/Library/Extensions/AppleHDA.kext/Contents/Plugins/AppleHDAController.kext/Contents/Info.plist) == "true" ]] && isvalid5=1

	if [[ $isvalid1 == 1 && $isvalid2 == 1 && $isvalid3 == 1 && $isvalid4 == 1 && $isvalid5 == 1 ]]
	then
		echo "IOPCITunnelCompatible mods are valid."
		iopci_valid=1
	else
		echo "Missing IOPCITunnelCompatible keys."
		iopci_valid=0
	fi
}

function InitScriptLocationAndMakeExecutable()
{
	current_path=$(perl -MCwd=realpath -e "print realpath '$0'")
	if [[ $(test -f /usr/bin/automate-eGPU.sh && echo 1) ]]
	then
		rm /usr/bin/automate-eGPU.sh
	fi
	cp "$current_path" /usr/bin/automate-eGPU.sh
	chmod +x /usr/bin/automate-eGPU.sh
}

function GeneralChecks()
{
	if [[ "$web_driver" == "" ]]
	then
		echo "No web driver detected."
	else 	
		if [[ "$nvdatype" == "Official" ]]
		then
			echo "You are running official driver due to OS X update or web driver uninstall."
			web_driver_exists_but_running_official=1
		fi
	fi

	IOPCITunnelCompatibleCheck
	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:"$board_id /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist) == "none" ]] && board_id_exists=1
	
}

function SetIOPCITunnelCompatible()
{
	[[ $isvalid1 == 0 ]] && /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:1:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist
	[[ $isvalid2 == 0 ]] && /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:2:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist
	[[ $isvalid3 == 0 ]] && /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:3:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist
	[[ $isvalid4 == 0 ]] && /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool true" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist
	[[ $isvalid5 == 0 ]] && /usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:BuiltInHDA:IOPCITunnelCompatible bool true" /System/Library/Extensions/AppleHDA.kext/Contents/Plugins/AppleHDAController.kext/Contents/Info.plist	
}

function AddBoardId()
{
	/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:"$board_id" string none" /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist
	echo "Board-id added."
}

function GetDownloadURL()
{
	index=0
	download_url=""
	download_version=""
	previous_installed_web_driver_version=$(system_profiler SPInstallHistoryDataType | sed -e '/NVIDIA Web Driver/,/Install Date/!d' | sed -E '/Version/!d' | tail -1 | sed -E 's/.*Version: (.*)$/\1/')
	
	curl -s "https://gfe.nvidia.com/mac-update" > $TMPDIR"mac-update.plist"

	if [[ $(test -f $TMPDIR"mac-update.plist" && echo 1) ]]
	then
		while [[ $(/usr/libexec/PlistBuddy -c "Print :updates:"$index":OS" $TMPDIR"mac-update.plist" 2>/dev/null && echo 1) ]];
		do
			if [[ $(/usr/libexec/PlistBuddy -c "Print :updates:"$index":OS" $TMPDIR"mac-update.plist") == "$build_version" ]]
			then
				download_url=$(/usr/libexec/PlistBuddy -c "Print :updates:"$index":downloadURL" $TMPDIR"mac-update.plist")
				download_version=$(/usr/libexec/PlistBuddy -c "Print :updates:"$index":version" $TMPDIR"mac-update.plist")
				break
			else
				index=$(($index+1))
			fi
		done
	fi
	if [[ $web_driver_exists_but_running_official == 0 ]] && [[ "$download_version" != "" ]] && [[ "$previous_installed_web_driver_version" != "" ]] && [[ "$download_version" == "$previous_installed_web_driver_version" ]]
	then
		if [[ $iopci_valid == 1 ]] && [[ $board_id_exists == 1 ]]
		then
			echo "Nvidia web driver is up to date."
			exit
		else
			echo "The latest package for ["$build_version"] is already downloaded.\nDo you want to reinstall? (y/n)"
			read answer
			if echo "$answer" | grep -iq "^y"
			then
				reinstall=1
				break
			else
				echo "Ok."
				exit
			fi
		fi
	elif [[ $web_driver_exists_but_running_official == 0 ]] && [[ "$download_version" == "" ]] && [[ "$download_url" == "" ]]
	then
		echo "No web driver yet available for build ["$build_version"]."
		test_path=$nvidia_app_support_path"WebDriver-"$previous_installed_web_driver_version".pkg"

		if [[ $(test -f "$test_path" && echo 1) ]]
		then
			echo "This script can reinstall the package ["$previous_installed_web_driver_version"] (y/n)?"
			read answer
			if echo "$answer" | grep -iq "^y"
			then
				reinstall=1
				break
			else
				echo "Ok."
				exit
			fi
		fi
	elif [[ $web_driver_exists_but_running_official == 1 ]] && [[ "$download_version" != "" ]] && [[ "$download_version" == "$previous_installed_web_driver_version" ]]
	then
		test_path=$nvidia_app_support_path"WebDriver-"$previous_installed_web_driver_version".pkg"
		if [[ $(test -f "$test_path" && echo 1) ]]
		then
			echo "The latest package for ["$build_version"] is already downloaded.\nDo you want to reinstall? (y/n)"
			read answer
			if echo "$answer" | grep -iq "^y"
			then
				reinstall=1
				break
			else
				echo "Ok."
				exit
			fi
		fi
	fi
}

function DoYouWantToDownLoadThisDriver()
{
	echo "Do you want to download this driver (y/n)?"
	read answer
	if echo "$answer" | grep -iq "^y" ;then
		curl -o $TMPDIR"WebDriver-"$download_version".pkg" "http://us.download.nvidia.com/Mac/Quadro_Certified/"$download_version"/WebDriver-"$download_version".pkg"
		echo "Driver downloaded."
	else
		echo "Ok."
		exit
	fi
}

function GetDriverList()
{
	driver_list_available=0
	list0=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/processFind.aspx?psid=73&pfid=696&osid="$os_id"&lid=1&whql=&lang=en-us&ctk=0")
	list="$(echo "$list0 "| grep 'New in Release')"
					
	value1="$(echo "$list "| sed -E 's/.*in Release ([0-9]+\.[0-9]+\.[a-z0-9]+)\:.* [0-9]+\.[0-9]+\.[0-9]+ \([A-Z0-9]+\).*/\1/')"
	value2="$(echo "$list "| sed -E 's/.*in Release [0-9]+\.[0-9]+\.[a-z0-9]+\:.* ([0-9]+\.[0-9]+\.[0-9]+) \([A-Z0-9]+\).*/\1/')"
	value3="$(echo "$list "| sed -E 's/.*in Release ([0-9]+\.[0-9]+\.[a-z0-9]+)\:.* [0-9]+\.[0-9]+\.[0-9]+ \(([A-Z0-9]+)\).*/\1/')"
	
	value4="$(echo "$list0 "| perl -ne 'print if s/.*([0-9]{3}\.[0-9]{2}\.[a-z0-9]{5}).*/\1/')"
	
	if [[ $value1 =~ (^[0-9]+\.[0-9]+\.[a-z0-9]+)+ ]] && [[ $value2 =~ (^[0-9]+\.[0-9]+\.[a-z0-9]+)+ ]] && [[ $value3 =~ (^[0-9]+\.[0-9]+\.[a-z0-9]+)+ ]]
	then
		driver_list_available=1
		list=$(echo "$list" | sed -E 's/.*in Release ([0-9]+\.[0-9]+\.[a-z0-9]+)\:.* ([0-9]+\.[0-9]+\.[0-9]+) \(([A-Z0-9]+)\).*/\1 for \2 (\3)/')
		download_version=$(echo "$list" | sed -n 1p | sed -E "s/^([0-9]+\.[0-9]+\.[0-9a-z]+).*/\1/")
	elif [[ $value4 =~ ^[0-9]+\.[0-9]+\.[a-z0-9]+ ]]
	then
		list=$(echo $value4 "for" $product_version "("$build_version")")
		download_version=$value4
	else
		echo "Driver not found. Nvidia may have changed their web driver search service."
		exit
	fi
	
	echo "Found the following matching drivers:"
	echo "-------------------------------------"

	echo "$list"
	
	echo "-------------------------------------"
	echo "Newest driver:\n\n" \
	"http://us.download.nvidia.com/Mac/Quadro_Certified/"$download_version"/WebDriver-"$download_version".pkg"
	DoYouWantToDownLoadThisDriver
}

function ScrapeOperatingSystemId()
{
	os_id=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4&ParentID=73" \
				| perl -pe 's/[\x0D]//g' \
				| sed -E "s/.*<Name>Mac OS X [A-Za-z ]+ "$product_version$"<\/Name><Value>([0-9]+)<\/Value><\/LookupValue>.*/\1/")

	if [[ ! $os_id =~ ^[-+]?[0-9]+$ ]]
	then
		echo "No web driver found for OS X "$product_version"."

		if [[ ! "$previous_version_to_look_for" == "[not found]" ]]
		then
			echo "Would you like search the latest available package for ["$previous_version_to_look_for"] (y/n)?"
			read answer
			if echo "$answer" | grep -iq "^y"
			then
		
			os_id=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4&ParentID=73" \
				| perl -pe 's/[\x0D]//g' \
				| sed -E "s/.*<Name>Mac OS X [A-Za-z ]+ "$previous_version_to_look_for"<\/Name><Value>([0-9]+)<\/Value><\/LookupValue>.*/\1/")

			if [[ ! $os_id =~ ^[-+]?[0-9]+$ ]]
			then
				echo "Operating system id not found. Nvidia may have changed their web driver search service."
				exit
			else
				echo "Operating system id found."
				break
			fi
			else
				echo "Ok."
				exit
			fi
		fi
	else
		echo "Operating system id found."
	fi
}

function Main()
{	
	echo "\n\033[1mCurrent OS X\033[0m\n" $product_version $build_version
	echo "\033[1mPrevious OS X\033[0m\n" $previous_product_and_build_version
	echo "\033[1mLatest installed web driver\033[0m\n" $previous_web_driver_info

	current_driver=$(/usr/libexec/PlistBuddy -c "Print :CFBundleGetInfoString" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist)
	required_os=$(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist)

	volume_name=$(diskutil info / | awk '/Volume Name/ {print substr ($0, index ($0,$3))}')
	
	GeneralChecks
			
	if [[ $board_id_exists == 0 ]]
	then
		echo "Mac board-id not found."
	else
		echo "Mac board-id found."
	fi
	
	if [[ $skipdriver == 0 ]]
	then
		echo "Searching for matching driver...\n"
		
		GetDownloadURL
		
		if [[ $reinstall == 0 ]]
		then
			if [[ "$download_url" == "" ]] || [[ "$download_version" == "" ]]
			then
				ScrapeOperatingSystemId
				if [[ $os_id =~ ^[-+]?[0-9]+$ ]]
				then
					GetDriverList
				fi
			else
				echo "Driver ["$download_version"] found from:\n"$download_url
				DoYouWantToDownLoadThisDriver
			fi
		
			if [[ "$download_version" != "" ]]
			then
				echo "Removing validation checks..."
				pkgutil --expand $TMPDIR"WebDriver-"$download_version".pkg" $TMPDIR"expanded.pkg"
				sed -i '' -E "s/if \(\!validateHardware\(\)\) return false;/\/\/if \(\!validateHardware\(\)\) return false;/g" $TMPDIR"expanded.pkg/Distribution"
				sed -i '' -E "s/if \(\!validateSoftware\(\)\) return false;/\/\/if \(\!validateSoftware\(\)\) return false;/g" $TMPDIR"expanded.pkg/Distribution"
			
				install_path=$nvidia_app_support_path"WebDriver-"$download_version".pkg"
			
				pkgutil --flatten $TMPDIR"expanded.pkg" "$install_path"

				rm -rf $TMPDIR"expanded.pkg"

				echo "Modified package ready. Do you want to install (y/n)?"
				read answer
				if echo "$answer" | grep -iq "^y" ;then
					break
				else
					echo "Ok."
					exit
				fi
			else
				echo "Web driver not found. Nvidia may have changed their web driver search service."
				exit
			fi
		fi
		
		if [[ $reinstall == 0 ]]
		then
			install_path=$nvidia_app_support_path"WebDriver-"$download_version".pkg"
		else
			install_path=$nvidia_app_support_path"WebDriver-"$previous_installed_web_driver_version".pkg"
		fi
	
		/usr/sbin/installer -target /Volumes/"$volume_name" -pkg "$install_path"
		
		IOPCITunnelCompatibleCheck
	fi
	
	if [[ $iopci_valid == 0 ]]
	then
		SetIOPCITunnelCompatible
		echo "IOPCITunnelCompatible mods done."
	fi
	
	if [[ $board_id_exists == 0 ]]
	then
		AddBoardId
	fi
	
	if [[ "$board_id" == "Mac-F60DEB81FF30ACF6" ]]
	then
		/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:Mac-F60DEB81FF30ACF6 none" /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist
	fi
	
	if [[ "$board_id" == "Mac-FA842E06C61E91C5" ]]
	then
		/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:Mac-FA842E06C61E91C5 none" /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist
	fi
	
	NVDARequiredOSCheck
	
	if [[ $is_match == 0 ]]
	then
		/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:NVDAStartup:NVDARequiredOS "$build_version /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist
		echo "NVDARequiredOS does not match. Changed to "$build_version
	fi
	
	nvram boot-args="kext-dev-mode=1 nvda_drv=1"
	
	touch /System/Library/Extensions
	kextcache -system-caches	
	echo "All ready. Please restart the Mac."
}

if [[ "$first_argument" == "" || "$first_argument" == "-skipdriver" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	if [[ ! $(test -d "$nvidia_app_support_path" && echo 1) ]]
	then
		mkdir "$nvidia_app_support_path"
	fi
	
	if [[ "$first_argument" == "-skipdriver" ]]
	then
		skipdriver=1
		previous_product_and_build_version="$(sed -E '/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([^\..]*)\.{0,1}.*<\/string>$/!d' \
										/Library/Receipts/InstallHistory.plist \
										| sed -E 's/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([^\..]*)\.{0,1}.*<\/string>$/\1 \2/' \
										| tail -2 | sed 2d $2)"
	else
		previous_product_and_build_version="$(sed -E '/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([^\..]*)\.{0,1}.*<\/string>$/!d' \
										/Library/Receipts/InstallHistory.plist \
										| sed -E 's/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([^\..]*)\.{0,1}.*<\/string>$/\1 \2/' \
										| tail -2 | sed 2d $1)"
	
		su "$(logname)" -c 'launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist' 2>/dev/null
	fi
					
	previous_web_driver_info="$(system_profiler SPInstallHistoryDataType | sed -e '/NVIDIA Web Driver/,/Install Date/!d' \
										| sed -E '/Version/,/Install Date/!d' | tail -3 \
										| perl -pe 's/([ ]+)([A-Z].*)/\2\\n/g')"	
										
	previous_major_version="$(echo "$product_version" | sed -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\1/g')"
	previous_minor_version="$(echo "$product_version" | sed -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\2/g')"
	previous_maintenance_version="$(echo "$product_version" | sed -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\3/g')"
	
	
	if [[ "$previous_maintenance_version" != "" && "$(($previous_maintenance_version-1))" > 0 ]]
	then
		previous_version_to_look_for=$previous_major_version"."$previous_minor_version"."$(($previous_maintenance_version-1))
	else
		previous_version_to_look_for=$previous_product_and_build_version
	fi
	
	if [[ "$previous_version_to_look_for" == "" ]]
	then
	  previous_version_to_look_for="[not found]"
	fi
																	
	if [[ "$previous_product_and_build_version" == "" ]]
	then
	  previous_product_and_build_version="[not found]"
	fi
									
	if [[ "$previous_web_driver_info" == "" ]]
	then
	  previous_web_driver_info="[not found]"
	fi

	board_id=$(ioreg -c IOPlatformExpertDevice -d 2 | grep board-id | sed "s/.*<\"\(.*\)\">.*/\1/")

	Main
elif [[ "$first_argument" == "-a" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	InitScriptLocationAndMakeExecutable

	GenerateDaemonPlist
	GenerateAgentPlist
	
	su "$(logname)" -c 'launchctl load -F /Library/LaunchAgents/automate-eGPU-agent.plist'
	su root -c 'launchctl load -F /Library/LaunchDaemons/automate-eGPU-daemon.plist'

	echo "Background services enabled."
elif [[ "$first_argument" == "-m" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit

	if [[ ! "$(su "$logname" -c 'launchctl list | grep automate-egpu-agent')" == "" ]]
	then
		su "$logname" -c 'launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist'
		if [[ $(test -f /Library/LaunchAgents/automate-eGPU-agent.plist && echo 1) ]]
		then
			rm /Library/LaunchAgents/automate-eGPU-agent.plist
		fi
	else
		echo "automate-eGPU-agent already unloaded."
	fi
	
	if [[ ! "$(su root -c 'launchctl list | grep automate-egpu-daemon')" == "" ]]
	then
		su root -c 'launchctl unload /Library/LaunchDaemons/automate-eGPU-daemon.plist'
		if [[ $(test -f /Library/LaunchDaemons/automate-eGPU-daemon.plist && echo 1) ]]
		then
			rm /Library/LaunchDaemons/automate-eGPU-daemon.plist
		fi
	else
		echo "automate-eGPU-daemon already unloaded."
	fi
	
	echo "Background services unloaded."
	
elif [[ "$first_argument" == "-a2" ]]
then
	nvram tbt-options=\<00\>
	nvram boot-args="kext-dev-mode=1 nvda_drv=1"
	
elif [[ "$first_argument" == "-a3" ]]
then
	if [[ ! "$web_driver" == "" ]]
	then	
		if [[ "$nvdatype" == "Official" ]]
		then
			/usr/bin/osascript -e 'tell app "System Events" to activate'
			message=$(/usr/bin/osascript -e 'tell app "System Events" to display dialog '\""$system_updated_message"\")
			res=$message
			if [[ $res =~ ^.*OK$ ]]
			then
				/usr/bin/osascript -e 'tell app "Terminal" to do script "sudo /usr/bin/automate-eGPU.sh"'
			fi
		fi
	fi
fi