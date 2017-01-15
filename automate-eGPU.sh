#!/bin/sh
#
######################################################################################
# automate-eGPU.sh 1.0.0 - Copyright (c) 2016, 2017
# ------------------------------------------------------------------------------------
# Authors:   Goalque [goalque@gmail.com] & FricoRico [ricardo@q42.nl]
# Homepage:  https://github.com/goalque/automate-eGPU/
# License:   https://github.com/goalque/automate-eGPU/blob/master/SCRIPT-LICENSE.txt
# ===================================================================================
# USAGE TERMS of automate-eGPU.sh
# ====================================================================================
# 1. You may use this script for personal use.
# 2. You may continue development of this script at it's GitHub homepage.
# 3. You may not redistribute this script from outside of it's GitHub homepage.
# 4. You may not use this script, or portions thereof, for any commercial purposes.
# 5. You may not modify Apple's copyrighted binary files from within this script
#    as mandated on pg 4, sections "L. Open Source" & "M. No Reverse Engineering"
#    of Apple's SLA at http://images.apple.com/legal/sla/docs/macOS1012.pdf 
########################################################################################
#
# Usage:
#          1) chmod +x automate-eGPU.sh
#          2) sudo ./automate-eGPU.sh
#          3) sudo ./automate-eGPU.sh -a		

ver="1.0.0"
SED=$(if [ -x /usr/bin/sed ]; then echo /usr/bin/sed; else which sed; fi)
logname="$(logname)"
first_argument="$1"
second_argument="$2"
product_version="$(sw_vers -productVersion)"
build_version="$(sw_vers -buildVersion)"
web_driver=$(pkgutil --pkgs | grep "com.nvidia.web-driver")
system_updated_message="Backup folder not found for OS X build [#]. Your system must be reconfigured. Click OK to execute automate-eGPU."
running_official=0
nvda_startup_web_found=0
iopci_valid=0
board_id_exists=0
skipdriver=0
download_url=""
download_version=""
app_support_path_base="/Library/Application Support/Automate-eGPU/"
app_support_path_clpeak="/Library/Application Support/Automate-eGPU/clpeak/"
app_support_path_nvidia="/Library/Application Support/Automate-eGPU/NVIDIA/"
app_support_path_amd="/Library/Application Support/Automate-eGPU/AMD/"
app_support_path_backup="/Library/Application Support/Automate-eGPU/backup/"
uninstaller_path="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app"
test_path=""
install_path=""
reinstall=0
TMPDIR="/tmp/"
major_version=""
minor_version=""
maintenance_version=""
startup_kext=""
web_driver_url=""
boot_args=""
amd=0
amd_x4000_codenames=(Bonaire Hawaii Pitcairn Tahiti Tonga Verde)
amd_x4100_codenames=(Baffin)
amd_x3000_codenames=(Barts Caicos Cayman Cedar Cypress Juniper Lombok Redwood Turks)
amd_controllers=(5000 6000 7000 8000 9000 9500)
config_board_ids=(42FD25EABCABB274 65CE76090165799A B809C3757DA9BB8D DB15BD556843C820 F60DEB81FF30ACF6 FA842E06C61E91C5)
board_id=$(ioreg -c IOPlatformExpertDevice -d 2 | grep board-id | $SED "s/.*<\"\(.*\)\">.*/\1/")
skipagdc=0

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
			<string>/usr/local/bin/automate-eGPU.sh</string>
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
			<string>/usr/local/bin/automate-eGPU.sh</string>
			<string>-a3</string>
	</array>
</dict>
</plist>
EOF
`
echo "$plist" > /Library/LaunchAgents/automate-eGPU-agent.plist	
}

function SetNVRAM()
{
nvram_data=`cat <<EOF
U2FsdGVkX19cOaLLbRX54zk1Jwi9WKu6R4AHUqRuRKYPbPunvDg1VfVw3L4XTH/A
JNtIE8SlURhEBEmml13e9pwpvsLw0n3scP6RFrYZYwnbFKXWVmDk/ZAFGaB3HzDK
UNQr+NVzgtVdVjooQyWrjaPZV22n9WdRIqIEL1fEArN7VAblWOMPomzhpblgjCPq
VTMrektw0b05ACLSJ5dsD+geQQXfaf2py9mJTWBEH0iwcf3zz6p1WukP00IJe7co
kvXby3NOHDLQ9N0Tqeg42kD5j3pNLg3XlOducbmVyfILqrbST2ToslHocICaRcnX
Pv7ZmVk082CwEredA3MgnMpC2C6fu4l3m1l1l0Tv1JPAanN6lUP6BATNDAeeag6/
i5j75ywQww7jPGa+Ba3m/QLjdhL4yIKjzn6xCQobT4pFUN0pXyjqaqZZUEWDUkgT
FuZzUbYoB5IBqrsRWIb2VdlKuv7bMt8pEjFlrSzRp57bbiYVc7R6MYw56jN4Cnto
WclPInXIaYifY6FPX3wJvO0h8fU4D0sTMD8X0EK2yL7MkM/BcaMBsLT3+9GKiceo
b/Z4xw7wDfsTz5YgfKPggVK+CY1bdyAl4BdbW4CpZmvg/szCHAcBsMe+05q9LkUx
EOF
`
echo "$nvram_data" > "$TMPDIR"nvram
}

function NVDARequiredOSCheck()
{
	is_match=0
	nvda_required_os_key_exists=0
	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" "/System/Library/Extensions/"$startup_kext"/Contents/Info.plist" 2>/dev/null && echo 1) ]] && nvda_required_os_key_exists=1		
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" "/System/Library/Extensions/"$startup_kext"/Contents/Info.plist" 2>/dev/null) == "$build_version" ]] && is_match=1
}

function IOPCITunnelCompatibleCheck()
{
	echo "Checking IOPCITunnelCompatible keys...\n"
	valid_count=0
	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:1:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:2:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))	
	[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:3:IOPCITunnelCompatible" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))
	
	if [[ $amd == 0 ]]
	then
		[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible" /System/Library/Extensions/"$startup_kext"/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))		
	fi
	
	if [[ $amd == 1 ]]
	then
		for controller in "${amd_controllers[@]}"
		do
			if [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 9 && "$controller" != "8000" && "$controller" != "9000" && "$controller" != "9500" ]] \
			|| [[ $(($major_version)) -eq 10 && $(($minor_version)) -lt 12 && "$controller" != "9500" ]] || [[ $(($major_version)) -eq 10 && $(($minor_version)) -gt 11 ]]
			then
   				[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:Controller:IOPCITunnelCompatible" /System/Library/Extensions/AMD"$controller"Controller.kext/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))
			fi
		done
		
		[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:ATI\ Support:IOPCITunnelCompatible" /System/Library/Extensions/AMDSupport.kext/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))	
		
		for codename in "${amd_x4000_codenames[@]}"
		do
   			[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCITunnelCompatible" /System/Library/Extensions/AMDRadeonX4000.kext/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))
		done
		
		for codename in "${amd_x4100_codenames[@]}"
		do
   			[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCITunnelCompatible" /System/Library/Extensions/AMDRadeonX4100.kext/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))
		done

		for codename in "${amd_x3000_codenames[@]}"
		do
   			[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCITunnelCompatible" /System/Library/Extensions/AMDRadeonX3000.kext/Contents/Info.plist 2>/dev/null) == "true" ]] && valid_count=$(($valid_count+1))
		done
		
		if [[ $valid_count == 7 ]]
		then
			iopci_valid=1
		else
			iopci_valid=0
		fi
	else
		if [[ $valid_count == 4 ]]
		then
			iopci_valid=1
		else
			iopci_valid=0
		fi
	fi
}

function InitScriptLocationAndMakeExecutable()
{
	if [[ ! $(test -d /usr/local/bin/ && echo 1) ]]
	then
		mkdir -p /usr/local/bin/
	fi
	
	current_path=$(perl -MCwd=realpath -e "print realpath '$0'")
	
	if [[ $(test -f /usr/local/bin/automate-eGPU.sh && echo 1) ]]
	then
		rm /usr/local/bin/automate-eGPU.sh
	fi
	
	cp "$current_path" /usr/local/bin/automate-eGPU.sh
	chmod +x /usr/local/bin/automate-eGPU.sh
}

function GeneralChecks()
{
	if [[ $amd == 0 ]]
	then
		if [[ "$web_driver" == "" ]]
		then
			echo "No Nvidia web driver detected."
		else 	
			if [[ $running_official == 1 ]]
			then
				echo "You are running official Nvidia driver."
			fi
		fi
	fi
	
	IOPCITunnelCompatibleCheck
	
	if [[ $amd == 0 ]]
	then
		[[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:"$board_id /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist 2>/dev/null) == "none" ]] && board_id_exists=1
	fi
}

function BackupKexts()
{
	rsync -a /System/Library/Extensions/IONDRVSupport.kext \
	/System/Library/Extensions/NVDAStartup.kext \
	/System/Library/Extensions/AMD*Controller.kext \
	/System/Library/Extensions/AppleGraphicsControl.kext \
	/System/Library/Extensions/AMDSupport.kext \
	/System/Library/Extensions/AMDRadeonX*.kext \
	 "$app_support_path_backup"$build_version"/"
}

function RebuildCaches()
{
	echo "Rebuilding caches..."
	if [[ $(test -f /System/Library/PrelinkedKernels/prelinkedkernel && echo 1) ]]
	then
		rm /System/Library/PrelinkedKernels/prelinkedkernel 2>/dev/null
	fi
	if [[ $(test -f /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache && echo 1) ]]
	then
		rm /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache 2>/dev/null
	fi
	touch /System/Library/Extensions
	kextcache -q -update-volume /
	touch /System/Library/Extensions
	kextcache -system-caches
}

function Uninstall()
{	
	DeduceStartup
	
	if [[ $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		rsync -a --delete "$app_support_path_backup"$build_version"/IONDRVSupport.kext/" /System/Library/Extensions/IONDRVSupport.kext/
		rsync -a --delete "$app_support_path_backup"$build_version"/NVDAStartup.kext/" /System/Library/Extensions/NVDAStartup.kext/

		for controller in "${amd_controllers[@]}"
		do
			if [[ $(test -f "$app_support_path_backup"$build_version"/AMD"$controller"Controller.kext/" && echo 1) ]]
			then
				rsync -a --delete "$app_support_path_backup"$build_version"/AMD"$controller"Controller.kext/" /System/Library/Extensions/AMD"$controller"Controller.kext/
			fi
		done
		
		rsync -a --delete "$app_support_path_backup"$build_version"/AppleGraphicsControl.kext/" /System/Library/Extensions/AppleGraphicsControl.kext/
		rsync -a --delete "$app_support_path_backup"$build_version"/AMDSupport.kext/" /System/Library/Extensions/AMDSupport.kext/
		rsync -a --delete "$app_support_path_backup"$build_version"/AMDRadeonX3000.kext/" /System/Library/Extensions/AMDRadeonX3000.kext/
		rsync -a --delete "$app_support_path_backup"$build_version"/AMDRadeonX4000.kext/" /System/Library/Extensions/AMDRadeonX4000.kext/
		
		if [[ $(test -d "$app_support_path_backup"$build_version"/AMDRadeonX4100.kext/" && echo 1) ]]
		then
			rsync -a --delete "$app_support_path_backup"$build_version"/AMDRadeonX4100.kext/" /System/Library/Extensions/AMDRadeonX4100.kext/
		fi
	fi
	
	rm -rf "/Library/Application Support/Automate-eGPU"
	
	if [[ $(test -f /usr/local/bin/automate-eGPU.sh && echo 1) ]]
	then
		rm /usr/local/bin/automate-eGPU.sh
	fi
	
	UnloadBackgroundServices
	
	nvram -d boot-args
	nvram -d tbt-options
	
	RebuildCaches
	
	echo "Automate-eGPU uninstall ready."
	
	if [[ $(test -d "$uninstaller_path" && echo 1) ]]
	then
		open "$uninstaller_path"
	fi
	
	exit
}

function SetIOPCIMatch()
{	
	iopci_match=$(/usr/libexec/PlistBuddy -c "Print :"$match_entry "$match_plist" | awk '{print tolower($0)}')
	match_id="0x"$(printf $egpu_device_id"$egpu_vendor_id" | awk '{print tolower($0)}')
	if [[ "$iopci_match" =~ \&0x ]]
	then
		/usr/libexec/PlistBuddy -c "Set :"$match_entry" "$match_id "$match_plist" 2>/dev/null
		echo "SetIOPCIMatch() set device ID "$match_id" in "$match_plist
	elif [[ ! "$iopci_match" =~ "$match_id" ]]
	then
		match_id2=${iopci_match}" "${match_id}
		match_entry="Set :"${match_entry}" "${match_id2}
		/usr/libexec/PlistBuddy -c "$match_entry" "$match_plist" 2>/dev/null
		echo "SetIOPCIMatch() appended device ID "$match_id" in "$match_plist
	fi
}

function SetIOPCITunnelCompatible()
{
	/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:1:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null
	/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:2:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null
	/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:3:IOPCITunnelCompatible bool true" /System/Library/Extensions/IONDRVSupport.kext/Info.plist 2>/dev/null
	
	if [[ $amd == 0 ]]
	then
		/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool true" /System/Library/Extensions/"$startup_kext"/Contents/Info.plist 2>/dev/null
	fi
	
	accelerator_found=0
	controller_found=0
	
	if [[ $amd == 1 ]]
	then
		for controller in "${amd_controllers[@]}"
		do
			if [[ "$controller" == "5000" ]] && [[ "$egpu_names" =~ Cypress|Redwood|Juniper ]]
			then
				controller_found=1
				break
			elif [[ "$controller" == "6000" ]] && [[ "$egpu_names" =~ Caicos|Turks|Barts|Cayman ]]
			then
				controller_found=1
				break
			elif [[ "$controller" == "7000" ]] && [[ "$egpu_names" =~ Verde|Pitcairn|Tahiti ]]
			then
				controller_found=1
				break
			elif [[ "$controller" == "8000" ]] && [[ "$egpu_names" =~ Bonaire|Hawaii ]]
			then
				controller_found=1
				break
			elif [[ "$controller" == "9000" ]] && [[ "$egpu_names" =~ Tonga|Fiji ]]
			then
				controller_found=1
				break
			elif [[ "$controller" == "9500" ]] && [[ "$egpu_names" =~ Baffin|Ellesmere ]]
			then
				controller_found=1
			fi		
		done
		
		if [[ $controller_found == 1 ]]
		then
			match_plist="/System/Library/Extensions/AMD"$controller"Controller.kext/Contents/Info.plist"
			/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:Controller:IOPCITunnelCompatible bool true" "$match_plist" 2>/dev/null
			match_entry="IOKitPersonalities:Controller:IOPCIMatch"
			SetIOPCIMatch
		else
			echo "Controller not found."
			exit
		fi
		
		/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:ATI\ Support:IOPCITunnelCompatible bool true" /System/Library/Extensions/AMDSupport.kext/Contents/Info.plist 2>/dev/null
	
		for codename in "${amd_x4100_codenames[@]}"
		do
			if [[ "$egpu_names" =~ "$codename" ]] || [[ "$egpu_names" =~ "Fiji" && "$codename" == "Baffin" ]] || [[ "$egpu_names" =~ "Ellesmere" && "$codename" == "Baffin" ]]
			then
				match_plist="/System/Library/Extensions/AMDRadeonX4100.kext/Contents/Info.plist"
				/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCITunnelCompatible bool true" "$match_plist" 2>/dev/null
	
				match_entry="IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCIMatch"
				SetIOPCIMatch
				accelerator_found=1
				break
			fi
		done
		
		for codename in "${amd_x4000_codenames[@]}"
		do
			if [[ "$egpu_names" =~ "$codename" ]]
			then
				match_plist="/System/Library/Extensions/AMDRadeonX4000.kext/Contents/Info.plist"
				/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCITunnelCompatible bool true" "$match_plist" 2>/dev/null
	
				match_entry="IOKitPersonalities:AMD"$codename"GraphicsAccelerator:IOPCIMatch"
				SetIOPCIMatch
				accelerator_found=1
				break
			fi
		done
		
		
		if [[ $accelerator_found == 0 ]]
		then
			echo "Accelerator not found."
			exit
		fi
	fi
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
	previous_installed_web_driver_version=$(system_profiler SPInstallHistoryDataType | $SED -e '/NVIDIA Web Driver/,/Install Date/!d' | $SED -E '/Version/!d' | tail -1 | $SED -E 's/.*Version: (.*)$/\1/')
	
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
	
	if [[ "$download_version" != "" ]] && [[ "$previous_installed_web_driver_version" != "" ]] && [[ "$download_version" == "$previous_installed_web_driver_version" ]]
	then	
		if [[ $iopci_valid == 1 ]] && [[ $board_id_exists == 1 ]] && [[ $running_official == 0 ]]
		then
			echo "Your system is eGPU enabled and Nvidia web driver is up to date."
			exit
		else
			test_path=$app_support_path_nvidia"WebDriver-"$previous_installed_web_driver_version".pkg"	
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
	elif [[ "$download_version" == "" ]] || [[ "$download_url" == "" ]]
	then
		echo "No web driver yet available for build ["$build_version"]."
		test_path=$app_support_path_nvidia"WebDriver-"$previous_installed_web_driver_version".pkg"
		exit
		
	elif [[ $running_official == 1 ]] && [[ "$download_version" != "" ]] && [[ "$previous_installed_web_driver_version" != "" ]] && [[ "$download_version" == "$previous_installed_web_driver_version" ]]
	then
		test_path=$app_support_path_nvidia"WebDriver-"$previous_installed_web_driver_version".pkg"
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

function DoYouWantToDownloadThisDriver()
{
	echo "Do you want to download this driver (y/n)?"
	read answer
	if echo "$answer" | grep -iq "^y" ;then
		curl -k -o $TMPDIR"WebDriver-"$download_version".pkg" $download_url
		echo "Driver downloaded."
	else
		echo "Ok."
		exit
	fi
}

function DeduceBootArgs()
{
	boot_args=""
	if [[ $amd == 1 ]]
	then
		if [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 10 ]] || [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 9 ]]
		then
			boot_args="kext-dev-mode=1"
		fi
	else
		if [[ $(($major_version)) -eq 10 && $(($minor_version)) -gt 10 ]]
		then
			if [[ $running_official == 0 ]]
			then
				boot_args="nvda_drv=1"
			fi
		else
			if [[ $running_official == 1 ]]
			then
				boot_args="kext-dev-mode=1"
			else
				boot_args="kext-dev-mode=1 nvda_drv=1"
			fi
		fi
	fi
}

function MakeNVRAM()
{
	nvram=$(openssl aes-256-cbc -d -in "$TMPDIR"nvram -a -pass pass:$(echo "$ver" | rev)); openssl enc -base64 -d \
	<<< $($SED -n '10p' <<< "$nvram" | $SED -E 's/.*<data>(.*)<\/data>.*/\1/'); \
	openssl enc -base64 -d <<< $(sed -n '12p' <<< "$nvram" | sed -E 's/.*<data>(.*)<\/data>.*/\1/'); echo "$nvram" | $SED '9,12d' \
	| $SED '6 s/<data><\/data>/<string>'"$boot_args"'<\/string>/' > "$TMPDIR"nvram; nvram -xf "$TMPDIR"nvram
}

function MakeSupportPaths()
{ 
	if [[ ! $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		mkdir -p "$app_support_path_backup"$build_version
		BackupKexts	
	fi

	if [[ ! $(test -d "$app_support_path_nvidia" && echo 1) ]]
	then
		mkdir -p "$app_support_path_nvidia"
	fi
	
	if [[ ! $(test -d "$app_support_path_amd" && echo 1) ]]
	then
		mkdir -p "$app_support_path_amd"
	fi
	
	if [[ ! $(test -d "$app_support_path_clpeak" && echo 1) ]]
	then
		mkdir -p "$app_support_path_clpeak"
	fi
}

function DetectGPU()
{
	dgpu_device_id0="$(ioreg -n GFX0@0 | $SED -E '/{/,/\| }$/!d' | grep \"device-id\" | $SED 's/.*\<\(.*\)\>.*/\1/' | $SED -E 's/^(.{2})(.{2}).*$/\2\1/')"
	dgpu_device_id1="$(ioreg -n GFX1@0 | $SED -E '/{/,/\| }$/!d' | grep \"device-id\" | $SED 's/.*\<\(.*\)\>.*/\1/' | $SED -E 's/^(.{2})(.{2}).*$/\2\1/')"
	dgpu_device_id2="$(ioreg -n GFX2@0 | $SED -E '/{/,/\| }$/!d' | grep \"device-id\" | $SED 's/.*\<\(.*\)\>.*/\1/' | $SED -E 's/^(.{2})(.{2}).*$/\2\1/')"
	egpu_vendor_id="$(ioreg -n display@0 | $SED -E '/{/,/\| }$/!d' | grep \"vendor-id\" | $SED 's/.*\<\(.*\)\>.*/\1/' | $SED -E 's/^(.{2})(.{2}).*$/\2\1/')"
	egpu_device_id="$(ioreg -n display@0 | $SED -E '/{/,/\| }$/!d' | grep \"device-id\" | $SED 's/.*\<\(.*\)\>.*/\1/' | $SED -E 's/^(.{2})(.{2}).*$/\2\1/')"
	egpu_names=$(curl -s "http://pci-ids.ucw.cz/read/PC/"$egpu_vendor_id$"/"$egpu_device_id | grep itemname |  $SED -E "s/.*Name\: (.*)$/\1/")
	egpu_name=$(echo "$egpu_names" | tail -1)
}

function UnloadBackgroundServices()
{
	if [[ ! "$(su "$logname" -c 'launchctl list | grep automate-egpu-agent')" == "" ]]
	then
		su "$logname" -c 'launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist'
	fi
	
	if [[ $(test -f /Library/LaunchAgents/automate-eGPU-agent.plist && echo 1) ]]
	then
		rm /Library/LaunchAgents/automate-eGPU-agent.plist
	fi
	
	if [[ ! "$(su root -c 'launchctl list | grep automate-egpu-daemon')" == "" ]]
	then
		su root -c 'launchctl unload /Library/LaunchDaemons/automate-eGPU-daemon.plist'
	fi
	
	if [[ $(test -f /Library/LaunchDaemons/automate-eGPU-daemon.plist && echo 1) ]]
	then
		rm /Library/LaunchDaemons/automate-eGPU-daemon.plist
	fi
	
	echo "Background services unloaded."
}

function ModifyPackage()
{
	echo "Removing validation checks..."
	pkgutil --expand $TMPDIR"WebDriver-"$download_version".pkg" $TMPDIR"expanded.pkg"
	$SED -i '' -E "s/if \(\!validateHardware\(\)\) return false;/\/\/if \(\!validateHardware\(\)\) return false;/g" $TMPDIR"expanded.pkg/Distribution"
	$SED -i '' -E "s/if \(\!validateSoftware\(\)\) return false;/\/\/if \(\!validateSoftware\(\)\) return false;/g" $TMPDIR"expanded.pkg/Distribution"

	install_path=$app_support_path_nvidia"WebDriver-"$download_version".pkg"

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
}

function DeduceStartup()
{
	running_official=0
	
	major_version="$(echo "$product_version" | $SED -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\1/g')"
	minor_version="$(echo "$product_version" | $SED -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\2/g')"
	maintenance_version="$(echo "$product_version" | $SED -E 's/([0-9]+)\.([0-9]+)\.{0,1}([0-9]*).*/\3/g')"
	
	if [[ $((major_version)) -eq 10 && $(($minor_version)) -gt 10 ]] && [[ ! $(nvram csr-active-config | awk '/csr-active-config/ {print substr ($0, index ($0,$2))}') == "w%00%00%00" ]]
	then
		echo "Boot into recovery partition and type: csrutil disable"
		exit
	fi

	
	if [[ $(($major_version)) -eq 10 && $(($minor_version)) -lt 9 ]] || \
	   [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 9 && $(($maintenance_version)) -lt 5 ]]
	then
		echo "Script doesn't support versions of OS X earlier than 10.9.5"
		exit
	fi
	
	if [[ $amd == 0 && $(($major_version)) -eq 10 && $(($minor_version)) -eq 9 && $(($maintenance_version)) -eq 5 ]] && [[ ! "$egpu_name" =~ "GK" ]]
	then
		echo "Only Kepler architecture cards are supported on OS X 10.9.5."
		exit
	fi
	
	startup_kext="NVDAStartup.kext"
	
	if [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 10 ]] || [[ $(($major_version)) -eq 10 && $(($minor_version)) -eq 9 ]]
	then
		nvdatype=$(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:NVDAStartup:NVDAType" /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist)
		if [[ "$nvdatype" == "Official" ]]
		then
			running_official=1
		fi
	elif [[ $(($major_version)) -eq 10 && $(($minor_version)) -gt 10 ]]
	then
		if [[ "$first_argument" == "-url" || "$first_argument" == "" ||  "$first_argument" == "-skip-agdc" ]]
		then
			startup_kext="NVDAStartupWeb.kext"
		fi
		
		if [[ $(test -d /System/Library/Extensions/NVDAStartupWeb.kext && echo 1) ]]
		then
			nvda_startup_web_found=1
		else
			running_official=1
			if [[ "$first_argument" == "-skip-web-driver" ]]
			then
				startup_kext="NVDAStartup.kext"
			fi
		fi
	fi
}

function Main()
{	
	echo "*****************************************"
	echo "\033[1mDetected eGPU\033[0m\n" $egpu_name
	echo "\033[1mCurrent OS X\033[0m\n" $product_version $build_version
	echo "\033[1mPrevious OS X\033[0m\n" $previous_product_and_build_version
	echo "\033[1mLatest installed Nvidia web driver\033[0m\n" $previous_web_driver_info
	
	volume_name=$(diskutil info / | awk '/Volume Name/ {print substr ($0, index ($0,$3))}')
	
	GeneralChecks
	
	if [[ $skipdriver == 0 && $amd == 0 ]] || [[ "$web_driver_url" != "" ]]
	then
		if [[ "$web_driver_url" == "" ]]
		then
			echo "Searching for matching driver...\n"
			GetDownloadURL
		fi
		
		if [[ $reinstall == 0 ]]
		then
			if [[ ! "$web_driver_url" == "" ]]
			then
				curl -o $TMPDIR"WebDriver-"$download_version".pkg" "$web_driver_url"
			fi
			
			if [[ "$web_driver_url" == "" && "$download_url" != "" ]]
			then
				echo "Driver ["$download_version"] found from:\n"$download_url
				DoYouWantToDownloadThisDriver
			fi
			
			if [[ "$download_version" != "" ]]
			then
				ModifyPackage
			else
				echo "Web driver not found. Nvidia may have changed their web driver search service."
				exit
			fi
		fi
		
		if [[ $reinstall == 0 ]]
		then
			install_path=$app_support_path_nvidia"WebDriver-"$download_version".pkg"
		else
			install_path=$app_support_path_nvidia"WebDriver-"$previous_installed_web_driver_version".pkg"
		fi
	
		/usr/sbin/installer -target /Volumes/"$volume_name" -pkg "$install_path"
		
		IOPCITunnelCompatibleCheck
	fi
	
	if [[ $amd == 1 || $iopci_valid == 0 ]]
	then
		SetIOPCITunnelCompatible
		echo "IOPCITunnelCompatible mods done."
	fi
	
	if [[ $amd == 0 && $board_id_exists == 0 ]]
	then
		if [[ $skipagdc == 0 ]]
		then
			AddBoardId
		fi
	fi
	
	if [[ $amd == 0 ]]
	then
		for config_board_id in "${config_board_ids[@]}"
		do
			if [[ $(/usr/libexec/PlistBuddy -c "Print :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:Mac-"$config_board_id /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist 2>/dev/null) =~ "Config" ]]
			then
				/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:AppleGraphicsDevicePolicy:ConfigMap:Mac-"$config_board_id$" none" /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist
			fi
		done
	fi
	
	if [[ $amd == 0 ]]
	then
		NVDARequiredOSCheck
	
		if [[ $is_match == 0 && $nvda_required_os_key_exists == 1 ]]
		then
			if [[ $nvda_startup_web_found == 1 ]]
			then
				/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:NVDAStartup:NVDARequiredOS "$build_version /System/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
				echo "NVDARequiredOS does not match. Changed to "$build_version
			elif [[ $startup_kext == "NVDAStartup.kext" && $running_official == 0 ]]
			then
				/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:NVDAStartup:NVDARequiredOS "$build_version /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist
				echo "NVDARequiredOS does not match. Changed to "$build_version
			fi
		elif [[ $is_match == 0 && $nvda_required_os_key_exists == 0 ]]
		then
			if [[ $nvda_startup_web_found == 1 ]]
			then
				/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:NVDAStartup:NVDARequiredOS string "$build_version /System/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
				echo "NVDARequiredOS does not match. Changed to "$build_version
			elif [[ $startup_kext == "NVDAStartup.kext" && $running_official == 0 ]]
			then
				/usr/libexec/PlistBuddy -c "Add :IOKitPersonalities:NVDAStartup:NVDARequiredOS string "$build_version /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist
				echo "NVDARequiredOS does not match. Changed to "$build_version
			fi
		fi
	fi
	
	RebuildCaches
	
	echo "All ready. Please restart the Mac."
}

if [[ "$first_argument" == "" || "$first_argument" == "-skip-web-driver" || "$first_argument" == "-url"  || "$first_argument" == "-skip-agdc" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
 	if [[ ! $(system_profiler SPThunderboltDataType | grep 'Device connected') == "" ]]
 	then
 		DetectGPU
 		if [[ "$egpu_device_id" == "" && "$egpu_vendor_id" == "" ]]
 		then
 			sleep 4
 			DetectGPU
 			if [[ "$egpu_device_id" == "" && "$egpu_vendor_id" == "" ]]
 			then
 				echo "Thunderbolt device is connected, but no external GPUs detected."
 				exit
 			fi
 		fi
 	else
 		echo "Hot-plug the Thunderbolt cable and run the script again."
 		exit
 	fi
 	
 	if [[ "$second_argument" == "-skip-agdc" ]]
	then
		skipagdc=1
	fi
	
	if [[ "$first_argument" == "-url" ]]
	then
		if [[ "$first_argument" == "-url" && "$second_argument" != "" ]]
		then
			web_driver_url="$second_argument"
		else
			echo "URL is empty."
			exit
		fi
		
		download_version=$(echo "$web_driver_url" | $SED -E "s/.*WebDriver\-([0-9]+\.[0-9]+\.[0-9a-z]+).*/\1/")
		
		if [[ "$download_version" == "" ]]
		then
			echo "Package name is not valid. Please check the URL address."
			exit
		fi
		
 		if [[ ! $(curl --output /dev/null --silent --head --fail "$web_driver_url" && echo 1) ]]
		then
			echo "URL doesn't exist."
			exit
		fi
		
		if [[ "$second_argument" == "-skip-agdc" ]]
		then
			skipagdc=1
		fi
	fi

	if [[ $(echo ${#egpu_device_id}) > 4 ]]
	then
		echo "Please install eGPUs one by one."
		exit
	fi

	if [[ $egpu_vendor_id == "1002" ]]
	then
		amd=1
	fi

	MakeSupportPaths
	
	if [[ "$first_argument" == "-skip-web-driver" ]]
	then
		skipdriver=1
		
		if [[ "$second_argument" == "-skip-agdc" ]]
		then
			skipagdc=1
		fi
	else
		su "$(logname)" -c 'launchctl unload /Library/LaunchAgents/automate-eGPU-agent.plist' 2>/dev/null
	fi
	
	if [[ "$first_argument" == "-skip-agdc" ]]
	then
		skipagdc=1
	fi
	
	previous_product_and_build_version="$(perl -ne 'print if s/.*com\.apple\.pkg\.update\.os\.([0-9]+\.[0-9]+\.[0-9]+)\.((?!'"$build_version"')[^\..]*)\.{0,1}.*<\/string>$/\1 \2/' \
										/Library/Receipts/InstallHistory.plist \
										| tail -1)"
					
	previous_web_driver_info="$(system_profiler SPInstallHistoryDataType | $SED -e '/NVIDIA Web Driver/,/Install Date/!d' \
										| $SED -E '/Version/,/Install Date/!d' | tail -3 \
										| perl -pe 's/([ ]+)([A-Z].*)/\2\\n/g')"	
	
	if [[ "$maintenance_version" != "" && "$(($maintenance_version-1))" > 0 ]]
	then
		previous_version_to_look_for=$major_version"."minor_version"."$(($maintenance_version-1))
	else
		previous_version_to_look_for=$(echo "$previous_product_and_build_version" | $SED -E 's/^([0-9]+\.[0-9]+\.{0,1}[0-9]*).*$/\1/g')
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
	
	SetNVRAM								
	DeduceStartup
	DeduceBootArgs
	MakeNVRAM
	nvram -d tbt-options
	Main
elif [[ "$first_argument" == "-clpeak" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	if [[ ! $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		echo "Application support path not found. Please install automate-eGPU first."
		exit
	fi
	
	MakeSupportPaths
	
	if [[ ! $(test -d /Library/Developer/CommandLineTools && echo 1) ]]
	then
		echo "Installing command line tools\n"
		xcode-select --install
		read -p "Please wait until Command Line Tools installation is complete and then press \"Enter\"..."
	fi
	
	if [[ ! $(test -d "$TMPDIR"clpeak-master && echo 1) ]]
	then
		cd $TMPDIR
		echo "Downloading clpeak\n"
		curl -L -o clpeak-master.zip http://github.com/krrishnarraj/clpeak/archive/master.zip
		unzip -q clpeak-master.zip
		cd -
	fi
	
	if [[ ! $(test -f /System/Library/Frameworks/OpenCL.framework/Headers/cl.hpp && echo 1) ]]
	then
		echo "Downloading cl.hpp\n"
		curl -o /System/Library/Frameworks/OpenCL.framework/Headers/cl.hpp https://www.khronos.org/registry/cl/api/2.1/cl.hpp
	fi
	
	if [[ ! $(test -d "$TMPDIR"cmake-3.3.0-Darwin-x86_64 && echo 1) ]]
	then
		echo "Downloading cmake-3.3.0\n"
		cd $TMPDIR
		curl -o cmake-3.3.0-Darwin-x86_64.tar.gz https://cmake.org/files/v3.3/cmake-3.3.0-Darwin-x86_64.tar.gz
		tar -xzf cmake-3.3.0-Darwin-x86_64.tar.gz
		cd -
	fi
	
	if [[ ! $(test -f "$app_support_path_clpeak"$"/clpeak" && echo 1) ]]
	then
		"$TMPDIR"cmake-3.3.0-Darwin-x86_64/CMake.app/Contents/bin/cmake -D CMAKE_CXX_COMPILER=/usr/bin/clang++ -B"$app_support_path_clpeak" -H"$TMPDIR"clpeak-master
		make -C "$app_support_path_clpeak"
	fi
	"$app_support_path_clpeak"$"clpeak"
	
elif [[ "$first_argument" == "-uninstall" ]]
then
	DetectGPU

	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	Uninstall

elif [[ "$first_argument" == "-a" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	if [[ ! $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		echo "Application support path not found. Please install automate-eGPU first."
		exit
	fi
	
	InitScriptLocationAndMakeExecutable
	DetectGPU
	
	if [[ $(echo ${#egpu_device_id}) > 4 ]] || [[ "$dgpu_device_id0" != "" ]] || [[ "$dgpu_device_id1" != "" ]] || [[ "$dgpu_device_id2" != "" ]] || \
	   [[ "$board_id" == "Mac-E43C1C25D4880AD6" ]] || [[ "$board_id" == "Mac-06F11FD93F0323C5" ]] || [[ "$board_id" == "Mac-937CB26E2E02BB01" ]] || \
	   [[ "$egpu_names" =~ "Fiji" ]] || [[ "$egpu_names" =~ "Ellesmere" ]]
	then
		GenerateDaemonPlist
		su root -c 'launchctl load -F /Library/LaunchDaemons/automate-eGPU-daemon.plist'
		echo "automate-eGPU-daemon launched."
	fi
	
	GenerateAgentPlist
	su "$(logname)" -c 'launchctl load -F /Library/LaunchAgents/automate-eGPU-agent.plist'
	
	echo "Background services enabled."
	
elif [[ "$first_argument" == "-m" ]]
then
	[ "$(id -u)" != "0" ] && echo "You must run this script with sudo." && exit
	
	if [[ ! $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		echo "Application support path not found. Please install automate-eGPU first."
		exit
	fi
	
	nvram -d tbt-options
	DeduceStartup
	DeduceBootArgs
	UnloadBackgroundServices
	
elif [[ "$first_argument" == "-a2" ]]
then
	SetNVRAM
	DeduceStartup
	DeduceBootArgs
	MakeNVRAM
	
elif [[ "$first_argument" == "-a3" ]]
then
	if [[ ! $(test -d "$app_support_path_backup"$build_version && echo 1) ]]
	then
		system_updated_message=$(echo $system_updated_message | $SED -E 's/(.*)(\#)(.*)/\1'$build_version'\3/')
		/usr/bin/osascript -e 'tell app "System Events" to activate'
		message=$(/usr/bin/osascript -e 'tell app "System Events" to display dialog '\""$system_updated_message"\")
		res=$message
		if [[ $res =~ ^.*OK$ ]]
		then
			/usr/bin/osascript -e 'tell app "Terminal" to do script "sudo /usr/local/bin/automate-eGPU.sh"'
		fi
	fi
fi
