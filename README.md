- Detects your OS X product version and build version
- Lists available web drivers from Nvidia
- Automatic download and driver installation
- Automatic IOPCITunnelCompatible mods + web driver mod
- Detects your Mac board-id and enables eGPU screen output
- Confirmed: Mid 2014 15” rMBP Iris Pro, Late 2014 Mac mini


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
