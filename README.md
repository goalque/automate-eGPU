- Detects your OS X product version and build version
- Lists available web drivers from Nvidia
- Automatic download and driver installation
- Automatic IOPCITunnelCompatible mods + web driver mod
- Detects your Mac board-id and enables eGPU screen output
- Background services
- Confirmed: Mid 2014 15” rMBP Iris Pro, Late 2014 Mac mini

What's new in 0.9.2

Now there is a parameter [-a] which launches two background processes, the other “automate-egpu-daemon” takes care of the following:

1) If you have a multi-slot enclosure (such as NA211TB, III-D, SE II) and you are using a Maxwell card with a dGPU equipped MBP (750M), the freezing issue at booting stage is completely eliminated. You can press option key to have boot screen without freezing or boot straight into the OS X. I discovered this by comparing 2014/2011 Mac mini’s differences. Big thanks to Simurgh5@Tech|Inferno for testing my theory. 

2) It’s likely that you can now run more than one Nvidia Kepler eGPUs externally out of the box with any TB2 Mac, without manual delay.

3) If you accidentally disabled the web driver, “automate-egpu-daemon” forces developer mode and web driver on each boot.

The other process, “automate-egpu-agent” detects in real-time if NVDAStartup.kext is changed. If you edit it or reinstall the web driver via Nvidia’s own UI, you will get a pop-up window that says:
“Nvidia driver change detected. In order to use eGPU, your system must be reconfigured. Click OK to execute automate-eGPU”.

- fixed nMP screen output bug
- quick regexp change to support pre-release seeds (not tested)
- [-skipdriver] parameter, which does what is says - executes only kext mods
- [-m] parameter, switches back to manual mode

The old manual mode, running the script without parameters is possible. And that must be the first terminal command, required before running with [-a].

What's new in 0.9.1
- Smart system scan: detects...
  
                * previous OS X version and build
  
                * previous non-beta OS X version and build
                
                * latest installed web driver version and date
                
                * OS X update and if the system is running official driver
                
                * IOPCITunnelCompatible keys
                
                * NVDARequiredOS key
- supports OS X Beta versions
- regular expression support for OS X El Capitan (not tested yet)
- if no web driver found and there is a package on the desktop,
  the script can reinstall it and change NVDARequiredOS to match current build
- if no web driver found and no package on the desktop,
  the script can download the previous non-beta driver from Nvidia, reinstall, and modify NVDARequiredOS
- the script can be executed by two OS X Terminal commands:

                * chmod +x automate-eGPU.sh
                * sudo ./automate-eGPU.sh
