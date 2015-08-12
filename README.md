
#Automate-eGPU.sh#

This script automates Nvidia and AMD eGPU setup on OS X.

- Native AMD support, masks for any card if codename is found
- Detects your OS X product version and build version
- Automatic Nvidia web driver download and installation
- Automatic IOPCITunnelCompatible mods + Nvidia web driver mod
- Detects Thunderbolt connection and GPU name
- Detects your Mac board-id and enables eGPU screen output
- Background services
- Automatic backups with rsync and uninstalling with [-uninstall]
- Detects GPU name by scraping device id from http://pci-ids.ucw.cz
- OpenCL benchmarking (https://github.com/krrishnarraj/clpeak)
- Possible to use Nvidia official driver for Kepler cards [-skipdriver]

The script can be executed by two OS X Terminal commands:

                * chmod +x automate-eGPU.sh
                * sudo ./automate-eGPU.sh

The manual [-m] mode does only the minimum initialization in order to use the eGPU.

The advanced [-a] mode aims to configure everything automatically in the background, so that user can continue working after OS X updates immediately. Resolves the boot screen freezing issue with multi-slot enclosures & dGPU equipped Macs, and is beneficial with the nMP, allowing to use any TB port for booting without issues. It’s likely that you can now run more than one Nvidia Kepler eGPUs externally out of the box with any TB2 Mac, without manual delay. You can switch the mode at any time. Confirmed to work with subsequent OS X 10.11 El Capitan Developer builds (you have to disable System Integrity Protection). The script detects if you have turned it on/off.

##What's new in 0.9.5##

- Install Nvidia driver pkg from any valid web address with [-url]
- Fixed and verified functions
##Example outputs##
```
goalques-MBP:Desktop goalque$ sudo ./automate-eGPU.sh -skipdriver
*** automate-eGPU.sh v0.9.5 - (c) 2015 by Goalque ***
-------------------------------------------------------
Detected eGPU
 GK110 [GeForce GTX 780 Rev. 2]
Current OS X
 10.10.4 14E46
Previous OS X
 [not found]
Latest installed Nvidia web driver
 Version: 346.02.02f03
 Source: 3rd Party
 Install Date: 12/08/15 00:54

You are running official Nvidia driver.
Checking IOPCITunnelCompatible keys...

Missing IOPCITunnelCompatible keys.
Mac board-id found.
IOPCITunnelCompatible mods done.
All ready. Please restart the Mac.
```
**R9 390 (worked only with 10.11):**
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
