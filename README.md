- Detects your OS X product version and build version
- Automatic Nvidia web driver download and installation
- Automatic IOPCITunnelCompatible mods + Nvidia web driver mod
- Detects Thunderbolt connection
- Detects GPU name
- Detects your Mac board-id and enables eGPU screen output
- Background services
- Automatic backups
- Uninstalling

What's new in 0.9.4

***Version 0.9.4 has some bugs including -a option, please wait for the next version.***
- Native AMD support, masks for any card if codename is found
- Possible to use Nvidia official driver for Kepler cards [-skipdriver]
- Detects Thunderbolt connection
- Detects GPU name by scraping device id from http://pci-ids.ucw.cz
- Hot-plugging required
- Automatic backups with rsync
- Uninstalling with [-uninstall] parameter
- OpenCL benchmarking (https://github.com/krrishnarraj/clpeak)
- In theory this should work on OS X El Capitan 10.11 if SIP disabled (official web driver can’t be downloaded automatically yet).

-----------------------------------------------------------
- the script can be executed by two OS X Terminal commands:

                * chmod +x automate-eGPU.sh
                * sudo ./automate-eGPU.sh
                
- Optional commands:

				* sudo ./automate-eGPU.sh -a (experimental)
				
The parameter [-a] launches two background processes, the other “automate-egpu-daemon” takes care of the following:

1) If you have a multi-slot enclosure (such as NA211TB, III-D, SE II) and you are using a Maxwell card with a dGPU equipped MBP (750M), the freezing issue at booting stage is completely eliminated. You can press option key to have boot screen without freezing or boot straight into the OS X. I discovered this by comparing 2014/2011 Mac mini’s differences. Big thanks to Simurgh5@Tech|Inferno for testing my theory. 

2) It’s likely that you can now run more than one Nvidia Kepler eGPUs externally out of the box with any TB2 Mac, without manual delay.

3) If you accidentally disabled the web driver, “automate-egpu-daemon” forces developer mode and web driver on each boot.

The other process, “automate-egpu-agent” detects if NVDAStartup.kext is changed.

				* [-m] parameter, switches back to manual mode
				* [-skipdriver] parameter, executes only kext mods
-----------------------------------------------------------
Thanks to Netstor for testing NA211TB, especially with the Late 2013 Mac Pro.

Thanks to Tech|Inferno forum and Nando’s up-to-date eGPU Implementation Hub, where you can choose the right hardware for you needs:

http://forum.techinferno.com/diy-e-gpu-projects/6578-implementations-hub-tb-ec-mpcie.html#Thunderbolt

AKiTiO Thunder2 is recommended with Maxwell Nvidia cards.

Please report issues via GitHub or in the Tech|Inferno thread:

http://forum.techinferno.com/mac-os-x-discussion/10289-script-automating-installation-egpu-os-x-inc-display-output.html
