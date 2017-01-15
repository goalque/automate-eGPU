***
Why did I remove the links to T|I?

Why my name was changed to euqlaog?

No idea why I and other long term T|I users were banned.

Where is Nando4?

See: https://egpu.io/nando4-ti-ban/
***
#Automate-eGPU EFI#

I’ve been working on a completely new application - eGPU boot manager for Mac computers. Installation script is not required as with rEFInd which invokes bless for the changing of the default boot partition. Settings can be done within the app.

You can download the demo version here:

https://github.com/goalque/automate-eGPU/releases/download/v0.0.1-demo/bootx64.efi

#Automate-eGPU.sh is reborn with AMD Polaris & Fiji support for macOS#

https://egpu.io/forums/mac-setup/automate-egpu-sh-is-reborn-with-amd-polaris-fiji-support-for-macos/#post-1487

I've ceased development of this script in favour of my EFI app.

Please do not release anything under the MIT license (v0.9.8), it would be VOID under the Apple’s SLA.

http://images.apple.com/legal/sla/docs/macOS1012.pdf

This script automates Nvidia and AMD eGPU setup on OS X.
<table>
<tr>
<td width="60%" valign="top">
<ul>
<li>Native AMD support</li>
<li>Detects your OS X product version and build version</li>
<li>Automatic Nvidia web driver download and installation</li>
<li>Automatic IOPCITunnelCompatible mods + Nvidia web driver mod</li>
<li>Detects Thunderbolt connection</li>
<li>Detects your Mac board-id and enables eGPU screen output</li>
<li>Background services</li>
<li>Automatic backups with rsync and uninstalling</li>
<li>Detects GPU name by scraping device id from http://pci-ids.ucw.cz</li>
<li>OpenCL benchmarking</li>
</ul>
</td>
</tr>
</table>

The script can be executed by two OS X Terminal commands:
```
chmod +x automate-eGPU.sh
sudo ./automate-eGPU.sh
```

##Options##
<table>
<tr>
<td>-a</td><td>Switch on automatic mode</td>
</tr>
<tr>
<td>-m</td><td>Switch off automatic mode (default)</td>
</tr>
<tr>
<td>-url</td><td>Install Nvidia driver pkg from any valid web address</td>
</tr>
<tr>
<td>-clpeak</td><td>OpenCL performance test (http://github.com/krrishnarraj/clpeak)</td>
</tr>
<tr>
<td>-skip-web-driver</td><td>Skip Nvidia Web driver installation (for Kepler cards)</td>
</tr>
<tr>
<td>-skip-agdc</td><td>Skip AddBoardId() function</td>
</tr>
<tr>
<td>-uninstall</td><td>Restore original kexts, unload services and delete application support files</td>
</tr>
</table>

The manual [-m] mode does only the minimum initialization in order to use the eGPU.

The advanced [-a] mode aims to configure everything automatically in the background, so that user can continue working after OS X updates immediately. Resolves the boot screen freezing issue with multi-slot enclosures & dGPU equipped Macs, and is beneficial with the nMP, allowing to use any TB port for booting without issues. It’s likely that you can now run more than one Nvidia Kepler eGPUs externally out of the box with any TB2 Mac, without manual delay. You can switch the mode at any time. Confirmed to work with subsequent OS X 10.11 El Capitan Developer builds (you have to disable System Integrity Protection). The script detects if you have turned it on/off.

OS X 10.11 brings Metal to Mac. I wrote a piece of code to determine if your eGPU supports Metal API. Just follow these steps:

```
curl -o ~/Desktop/metaltest.swift https://raw.githubusercontent.com/goalque/automate-eGPU/master/metaltest.swift

cd ~/Desktop

swiftc -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macosx10.11 -o metaltest metaltest.swift

./metaltest
```
Thanks to jrprice’s NBody-Metal app, a GTX 980 runs 65536 bodies nearly 30 FPS on retina display. Approximately 7 times faster than Iris Pro. A simulation of 32768 bodies achieves 60 FPS.
https://github.com/jrprice/NBody-Metal

![](http://imgur.com/2QY14yH.png)

![](http://i.imgur.com/C34UhKO.png)

##What’s new in 1.0.0##

* A new method for rebuilding cache files
* AMD Polaris and Fiji support (limited CUs)
* -skip-agdc option
* -skipdriver renamed to -skip-web-driver
* Removed secondary data scraping methods

Version 1.0.0 is released with new licensing:

https://github.com/goalque/automate-eGPU/blob/master/SCRIPT-LICENSE.txt

##What’s new in 0.9.9##

Version 0.9.9 is released with new licensing:
https://github.com/goalque/automate-eGPU/blob/master/SCRIPT-LICENSE.txt

* ~~Native support (experimental) for R9 Nano and RX 480 with a Baffin personality (just remember to turn on -a mode).~~

* Nvidia web driver support (experimental) for macOS Sierra beta builds

##What's new in 0.9.8##

* Support for OS X Mavericks 10.9.5 and Kepler cards
* Added board-ids for iMac15,1 and iMac17,1
* Fixed issue #8 https://github.com/goalque/automate-eGPU/issues/8
* Fixed issue #9 https://github.com/goalque/automate-eGPU/issues/9 (thanks keymone)
* Fixed issue #13 https://github.com/goalque/automate-eGPU/issues/13
   
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

When the [-a] mode is turned on, Nvidia eGPU connected to nMP Bus 0 (port 5 or 6) works, but Thunderbolt Bus 1 or 2 (ports 1-4) require one additional restart and shut down without eGPU.

##Example outputs##

```
*** automate-eGPU.sh v0.9.7 - (c) 2015 by Goalque ***
-------------------------------------------------------
Detected eGPU
 GM204 [GeForce GTX 980]
Current OS X
 10.11 15A284
Previous OS X
 10.10.5 14F27
Latest installed Nvidia web driver
 Version: 346.02.03f01
 Source: 3rd Party
 Install Date: 9/26/15, 4:57 PM


You are running official Nvidia driver.
Checking IOPCITunnelCompatible keys...


Missing IOPCITunnelCompatible keys.
Mac board-id found.
Searching for matching driver...


Driver [346.03.02f01] found from:
http://us.download.nvidia.com/Mac/Quadro_Certified/346.03.02f01/WebDriver-346.03.02f01.pkg
Do you want to download this driver (y/n)?
y
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 68.9M  100 68.9M    0     0  3500k      0  0:00:20  0:00:20 --:--:-- 3577k
Driver downloaded.
Removing validation checks...
Modified package ready. Do you want to install (y/n)?
y
installer: Package name is NVIDIA Web Driver 346.03.02f01
installer: Upgrading at base path /
installer: The upgrade was successful.
installer: The install requires restarting now.
Checking IOPCITunnelCompatible keys...


Missing IOPCITunnelCompatible keys.
IOPCITunnelCompatible mods done.
SetIOPCIMatch() set device ID 0x13C010DE in /System/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
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


