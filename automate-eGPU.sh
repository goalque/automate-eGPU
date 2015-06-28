#!/bin/sh
#
# Script (automate-eGPU.sh)
# This script automates Nvidia eGPU setup on OS X.
#
# Version 0.9.2 - Copyright (c) 2015 by goalque (goalque@gmail.com)
# Licensed under the terms of the MIT license
#
# - Detects your OS X product version and build version
# - Lists available web drivers from Nvidia
# - Automatic download and driver installation
# - Automatic IOPCITunnelCompatible mods + web driver mod
# - Detects your Mac board-id and enables eGPU screen output
# - Background services
#
#	Usage: 1) chmod +x automate-eGPU.sh
#	       2) sudo ./automate-eGPU.sh
#		   3) sudo ./automate-eGPU.sh -a
#

first_argument="$1"
product_version="$(sw_vers -productVersion)"
build_version="$(sw_vers -buildVersion)"
nvdatype=$(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDAType" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist)
web_driver=$(pkgutil --pkgs | grep "com.nvidia.web-driver")
system_updated_message="OS X update has disabled the web driver. In order to use eGPU, your system must be reconfigured. Click OK to execute automate-eGPU."
system_updated_message2="Nvidia driver change detected. In order to use eGPU, your system must be reconfigured. Click OK to execute automate-eGPU."	
web_driver_exists_but_running_official=0
iopci_valid=0
board_id_exists=0
skipdriver=0
	
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
	<false/>
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
			echo "OS X update has disabled the web driver."
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

function Main()
{
	echo "\n\033[1mCurrent OS X\033[0m\n" $product_version $build_version
	echo "\033[1mPrevious OS X\033[0m\n" $previous_product_and_build_version
	echo "\033[1mPrevious non-beta OS X\033[0m\n" $previous_non_beta_product_and_build_version
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
		if [[ $(test -f ~/Desktop/WebDriver-*.pkg && echo 1) ]]
		then
			echo "This script can reinstall the package on your desktop.\nOk(y/n)? "
			read answer
			if echo "$answer" | grep -iq "^y" ;then
				/usr/sbin/installer -target /Volumes/"$volume_name" -pkg ~/Desktop/WebDriver-*.pkg
				IOPCITunnelCompatibleCheck
			else
				echo "Ok."
				exit
			fi
		else
			echo "Searching for available drivers...\n"

			os_id=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4&ParentID=73" \
					| perl -pe 's/[\x0D]//g' \
					| sed -E "s/.*<Name>Mac OS X [A-Za-z ]+ "$product_version$"<\/Name><Value>([0-9]+)<\/Value><\/LookupValue>.*/\1/")

			if [[ ! $os_id =~ ^[-+]?[0-9]+$ ]]
			then
				echo "No web driver found for OS X "$product_version"."
  
				if [[ $(test -f ~/Desktop/WebDriver-*.pkg && echo 1) ]]
				then
					echo "This script can reinstall the package on your desktop.\nOk (y/n)? "
					read answer
					if echo "$answer" | grep -iq "^y" ;then
						/usr/sbin/installer -target /Volumes/"$volume_name" -pkg ~/Desktop/WebDriver-*.pkg
						IOPCITunnelCompatibleCheck
					else
						echo "Ok."
						exit
					fi
				else
					if [[ ! "$previous_non_beta_product_and_build_version" == "[not found]" ]]
					then
						echo "There is no package on the desktop.\nWould you like search the latest available package for ["$previous_non_beta_product_and_build_version"] (y/n)?"
						read answer
						if echo "$answer" | grep -iq "^y"
						then
						p_product_version=$(echo "$previous_non_beta_product_and_build_version" | cut -d' ' -f1 | perl -ne 'print if /\S/')
			
						os_id=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4&ParentID=73" \
							| perl -pe 's/[\x0D]//g' \
							| sed -E "s/.*<Name>Mac OS X [A-Za-z ]+ "$p_product_version"<\/Name><Value>([0-9]+)<\/Value><\/LookupValue>.*/\1/")
			
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
				fi
			else
				echo "Operating system id found."
			fi

			if [[ $os_id =~ ^[-+]?[0-9]+$ ]]
			then
				list=$(curl -s -H "X-Requested-With: XMLHttpRequest" "http://www.nvidia.com/Download/processFind.aspx?psid=73&pfid=696&osid="$os_id$"&lid=1&whql=&lang=en-us&ctk=0" \
					| grep 'New in Release' \
					| sed -E 's/.*in Release ([0-9]+\.[0-9]+\.[a-z0-9]+)\:.* ([0-9]+\.[0-9]+\.[0-9]+) \(([A-Z0-9]+)\).*/\1 for \2 (\3)/')

				echo "Found the following matching drivers:"
				echo "-------------------------------------"

				echo "$list"

				new=$(echo "$list" | sed -n 1p | sed -E "s/^([0-9]+\.[0-9]+\.[0-9a-z]+).*/\1/")

				echo "-------------------------------------"
				echo "Newest driver:\n\n" \
				"http://us.download.nvidia.com/Mac/Quadro_Certified/"$new"/WebDriver-"$new$".pkg"

				echo "Do you want to download this driver to your desktop (y/n)?"
				read answer
				if echo "$answer" | grep -iq "^y" ;then
					curl -o ~/Desktop/WebDriver-$new.pkg "http://us.download.nvidia.com/Mac/Quadro_Certified/"$new"/WebDriver-"$new$".pkg"
					echo "Driver downloaded."
				else
					echo "Ok."
					exit
				fi

				echo "Removing validation checks..."
				pkgutil --expand ~/Desktop/WebDriver-$new.pkg ~/Desktop/expanded.pkg
				sed -i '' -E "s/if \(\!validateHardware\(\)\) return false;/\/\/if \(\!validateHardware\(\)\) return false;/g" ~/Desktop/expanded.pkg/Distribution
				sed -i '' -E "s/if \(\!validateSoftware\(\)\) return false;/\/\/if \(\!validateSoftware\(\)\) return false;/g" ~/Desktop/expanded.pkg/Distribution

				pkgutil --flatten ~/Desktop/expanded.pkg ~/Desktop/WebDriver-$new.pkg

				rm -rf ~/Desktop/expanded.pkg

				echo "Modified package ready. Do you want to install (y/n)?"
				read answer
				if echo "$answer" | grep -iq "^y" ;then
					/usr/sbin/installer -target /Volumes/"$volume_name" -pkg ~/Desktop/WebDriver-$new.pkg
					IOPCITunnelCompatibleCheck
				else
					echo "Ok."
					exit
				fi
			fi
		fi
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
	
	if [[ "$first_argument" == "-skipdriver" ]]
	then
		skipdriver=1
		previous_product_and_build_version="$(sed -E '/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+)\..*/!d' \
										/Library/Receipts/InstallHistory.plist \
										| sed -E 's/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+)\..*/\1 \2/' \
										| tail -2 | sed 2d $2)"
	else
		previous_product_and_build_version="$(sed -E '/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+)\..*/!d' \
										/Library/Receipts/InstallHistory.plist \
										| sed -E 's/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+)\..*/\1 \2/' \
										| tail -2 | sed 2d $1)"
	
		launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist 2> /dev/null
	fi
					
	previous_web_driver_info="$(system_profiler SPInstallHistoryDataType | sed -e '/NVIDIA Web Driver/,/Install Date/!d' \
										| sed -E '/Version/,/Install Date/!d' | tail -3 \
										| perl -pe 's/([ ]+)([A-Z].*)/\2\\n/g')"
									
	previous_non_beta_product_and_build_version="$(sed -E '/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+[^ba])\..*/!d' \
										/Library/Receipts/InstallHistory.plist | \
										sed -E 's/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]{2}[A-Z][a-z0-9]+)\..*/\1 \2/' | tail -1  \
										| perl -pe 's/([ ]+)([A-Z].*)/\2\\n/g')"
																	

	if [[ "$previous_product_and_build_version" == "" ]]
	then
	  previous_product_and_build_version="[not found]"
	fi
									
	if [[ "$previous_web_driver_info" == "" ]]
	then
	  previous_web_driver_info="[not found]"
	fi

	if [[ "$previous_non_beta_product_and_build_version" == "" ]]
	then
	  previous_non_beta_product_and_build_version="[not found]"
	fi

	board_id=$(ioreg -c IOPlatformExpertDevice -d 2 | grep board-id | sed "s/.*<\"\(.*\)\">.*/\1/")

	Main
elif [[ "$first_argument" == "-a" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	InitScriptLocationAndMakeExecutable

	GenerateDaemonPlist
	GenerateAgentPlist
	
	launchctl load -F /Library/LaunchAgents/automate-eGPU-agent.plist
	launchctl load -F /Library/LaunchDaemons/automate-eGPU-daemon.plist

	echo "Background services enabled."
elif [[ "$first_argument" == "-m" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist 2> /dev/null
	launchctl unload /Library/LaunchDaemons/automate-eGPU-daemon.plist 2> /dev/null
	
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
		else
			/usr/bin/osascript -e 'tell app "System Events" to activate'
			message=$(/usr/bin/osascript -e 'tell app "System Events" to display dialog '\""$system_updated_message2"\")
			res=$message
			if [[ $res =~ ^.*OK$ ]]
			then
				/usr/bin/osascript -e 'tell app "Terminal" to do script "sudo /usr/bin/automate-eGPU.sh"'
			fi
		fi
	fi

fi

