#Automate-eGPU.sh#

This script automates Nvidia and AMD eGPU setup on OS X.

- Native AMD support
- Detects your OS X product version and build version
- Automatic Nvidia web driver download and installation
- Automatic IOPCITunnelCompatible mods + Nvidia web driver mod
- Detects Thunderbolt connection
- Detects your Mac board-id and enables eGPU screen output
- Background services
- Automatic backups with rsync and uninstalling with [-uninstall]
- Detects GPU name by scraping device id from http://pci-ids.ucw.cz
- OpenCL benchmarking (https://github.com/krrishnarraj/clpeak), [-clpeak]
- Possible to use Nvidia official driver for Kepler cards [-skipdriver]
- Install Nvidia driver pkg from any valid web address with [-url]

The script can be executed by two OS X Terminal commands:

                * chmod +x automate-eGPU.sh
                * sudo ./automate-eGPU.sh

The manual [-m] mode does only the minimum initialization in order to use the eGPU.

The advanced [-a] mode aims to configure everything automatically in the background, so that user can continue working after OS X updates immediately. Resolves the boot screen freezing issue with multi-slot enclosures & dGPU equipped Macs, and is beneficial with the nMP, allowing to use any TB port for booting without issues. It’s likely that you can now run more than one Nvidia Kepler eGPUs externally out of the box with any TB2 Mac, without manual delay. You can switch the mode at any time. Confirmed to work with subsequent OS X 10.11 El Capitan Developer builds (you have to disable System Integrity Protection). The script detects if you have turned it on/off.

##What’s new in 0.9.7##

* SetIOPCIMatch() function which sets and appends device IDs (both the AMD and Nvidia)
* Automatic NVIDIA Driver Manager uninstalling
* Minor bug fixes

##What’s new in 0.9.6##
* Support for 2015 Macs (-a mode is required for successful booting with a multi-slot enclosure)
* Prepared for Fiji architecture
* Detects dGPUs for determining the correct [-a] mode behaviour
* Fixed issue #3 https://github.com/goalque/automate-eGPU/issues/3
* Fixed issue #4 https://github.com/goalque/automate-eGPU/issues/4
* Checks for the existence of application support path and if the script is ran as root
* Support for OS X El Capitan 10.11 GM

![](http://i.imgur.com/pkKujzG.png)

When the [-a] mode is turned on, Nvidia eGPU connected to nMP Bus 0 (port 5 or 6) works, but Thunderbolt Bus 1 or 2 (ports 1-4) require one additional restart and shut down without eGPU.

##Example outputs##

```
*** automate-eGPU.sh v0.9.7 - (c) 2015 by Goalque ***
-------------------------------------------------------
Detected eGPU
 GM204 [GeForce GTX 980]
Current OS X
 10.10.5 14F27
Previous OS X
 [not found]
Latest installed Nvidia web driver
 Version: 346.02.03f01
 Source: 3rd Party
 Install Date: 9/26/15, 2:51 PM

You are running official Nvidia driver.
Checking IOPCITunnelCompatible keys...

Missing IOPCITunnelCompatible keys.
Mac board-id not found.
Searching for matching driver...

Driver [346.02.03f01] found from:
http://us.download.nvidia.com/Mac/Quadro_Certified/346.02.03f01/WebDriver-346.02.03f01.pkg
Do you want to download this driver (y/n)?
y
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 47.6M  100 47.6M    0     0  4680k      0  0:00:10  0:00:10 --:--:-- 4793k
Driver downloaded.
Removing validation checks...
Modified package ready. Do you want to install (y/n)?
y
installer: Package name is NVIDIA Web Driver 346.02.03f01
installer: Upgrading at base path /
installer: The upgrade was successful.
installer: The install requires restarting now.
Checking IOPCITunnelCompatible keys...

Missing IOPCITunnelCompatible keys.
IOPCITunnelCompatible mods done.
SetIOPCIMatch() set device ID 0x13C010DE in /System/Library/Extensions/NVDAStartup.kext/Contents/Info.plist
Board-id added.
All ready. Please restart the Mac.
```
```
*** automate-eGPU.sh v0.9.7 - (c) 2015 by Goalque ***
-------------------------------------------------------
Detected eGPU
 Pitcairn XT [Radeon HD 7870 GHz Edition]
Current OS X
 10.10.5 14F27
Previous OS X
 [not found]
Latest installed Nvidia web driver
 Version: 346.02.03f01
 Source: 3rd Party
 Install Date: 9/26/15, 2:51 PM

Checking IOPCITunnelCompatible keys...

IOPCITunnelCompatible mods are valid.
IOPCITunnelCompatible mods done.
All ready. Please restart the Mac.
```
**R9 390:**
```
Device: AMD Radeon HD Hawaii PRO Prototype Compute Engine
    Driver version  : 1.2 (Jul 29 2015 02:44:59) (Macintosh)
    Compute units   : 40
    Clock frequency : 1010 MHz

    Global memory bandwidth (GBPS)
      float   : 227.07
      float2  : 256.78
      float4  : 232.63
      float8  : 114.53
      float16 : 49.93

    Single-precision compute (GFLOPS)
      float   : 4533.45
      float2  : 4503.78
      float4  : 4516.94
      float8  : 4481.20
      float16 : 4430.48

    Double-precision compute (GFLOPS)
clCreateKernel (-46)
      Tests skipped

    Transfer bandwidth (GBPS)
      enqueueWriteBuffer         : 1.44
      enqueueReadBuffer          : 1.44
      enqueueMapBuffer(for read) : 25.47
        memcpy from mapped ptr   : 5.30
      enqueueUnmap(after write)  : 11652.11
        memcpy to mapped ptr     : 5.93

    Kernel launch latency : 6.37 us
```

Thanks to Netstor for testing NA211TB, especially with the Late 2013 Mac Pro.

Thanks to Tech|Inferno forum and Nando’s up-to-date eGPU Implementation Hub, where you can choose the right hardware for you needs:

http://forum.techinferno.com/diy-e-gpu-projects/6578-implementations-hub-tb-ec-mpcie.html#Thunderbolt

AKiTiO Thunder2 is recommended with Maxwell Nvidia cards or older AMDs. NA211TB is stable with AMD R9 series.

Please report issues via GitHub or in the Tech|Inferno thread:

http://forum.techinferno.com/mac-os-x-discussion/10289-script-automating-installation-egpu-os-x-inc-display-output.html
