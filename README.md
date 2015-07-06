- Detects your OS X product version and build version
- Automatic download and driver installation
- Automatic IOPCITunnelCompatible mods + web driver mod
- Detects your Mac board-id and enables eGPU screen output
- Background services
- Confirmed: Mid 2014 15” rMBP Iris Pro, Late 2014 Mac mini

What's new in 0.9.3

- Downloaded web driver packages are placed at "/Library/Application Support/NVIDIA/"
- The script uses primarily the same web server as the NVIDIA Driver Manager for detecting the correct driver
- Rewritten scraping, "previous non-beta" is replaced with more reliable method
- Fixed privilege issues, but automatic [-a] mode is still experimental

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