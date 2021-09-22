# TI81CE
TI-81 1.8K ROM port for the TI-84+CE

## Background

As a bit of a mini side project I patched/ported the TI-81 1.8K ROM to run on the CE in z80 mode.

Yes that's right, the OS from a 30 year old calc running on the more recent TI-84+CE :).

There isn't really much to it as the only differences to the ROM are port read/writes have been patched since they can't be used on the CE and even if they could be, the connected hardware isn't the same anyway. The whole ROM is only 32KB so no need to mess with paging etc, so the whole thing was reasonably straight-forward. One thing to note is that instead of patching a call to a routine (which would be 1 byte larger and thus require recalculating of all relevant ROM addresses, not to mention make the ROM larger) I patched with RST $00 and took over that address since it's used rarely.

The LCD is scaled 3x which seems ok size wise and left room for a small 81 style border theme. The actual LCD rendering is kind of hacked in and requires interrupts to be running ... which should normally be the case. Also since this is not emulation, the speed is not consistent with the real thing. Not sure whether to try and restrict it, but I don't see the harm for now.

I hacked in RAM saving to an appvar on exit which seems to mostly work though I need to test it properly.

No other reason than just because, and perhaps a good way to preserve the 81 experience since they are becoming rarer now.

![](https://tr1p1ea.net/files/downloads/screenshots/ti81ce_03.png)

## Installation

The release is split into multiple binary blobs that can be joined together with your 1.8K ROM file.
```
makeprgm - (drag & drop 1.8K ROM file here).bat
TI81CE - TI-84 Plus CE (Native).8xp.001
TI81CE - TI-84 Plus CE (Native).8xp.003
```

Simply drag and drop your 1.8K ROM file onto the **makeprgm - (drag & drop 1.8K ROM file here).bat** file and it will create **TI81CE - TI-84 Plus CE (Native).8xp** for you. The resultant file should be exactly 38,405 bytes.

This is to avoid any complications with distributing my personal ROM dump.

## Running

This program is a native assembly file and can be run as such:
```
Asm(prgmTI81CE
```

**WARNING: If you have updated your calculator to an OS version > 5.5 then you will need to use [arTIfiCE](https://yvantt.github.io/arTIfiCE/) to run assembly programs. I suggest using it to install the [Cesium Shell](https://github.com/mateoconlechuga/cesium) for the best experience.**

## Notes
**This works with ROM version 1.8K ONLY.** A different ROM will likely crash (since this is a port that means the host system will crash).

You cannot install Unity on it the traditional way (since IM 2 interrupts aren't possible on the CE) ... but perhaps I should build similar ASM support into it. The best bit is that I'd store it outside of usable RAM so you'd get ~400+ bytes of precious RAM back. That being said with ASM you wouldn't be able to access ports since this is not emulation, it's a patch/port. No sending files, though it would be entirely possible to modify the RAM/register state stored inside the appvar instead of typing it all in (todo?)

Dumping your own ROM is quite a difficult process since the 81 has no link port. There is some very valuable information here: [http://tiplanet.org/modules/archives/downloads/dump81.pdf](http://tiplanet.org/modules/archives/downloads/dump81.pdf)

## Thanks

Special thanks goes to the amazing work by the pioneers of the 81 scene and those who helped me along the way:
Randy Compton
FloppusMaximus
Benjamin Moody
Zeroko
MateoC
calc84
Everyone at [Cemetech](https://www.cemetech.net)
The creators of TilEm
Everyone at [TIPlanet](https://www.tiplanet.org)


