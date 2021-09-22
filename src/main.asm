; tr1p1ea - 04/08/2021 (dd/mm/yyyy):
;------------------------------------
;--------------------------------------------------------------
; TI-81 CE - main.asm (z80 mode)
;--------------------------------------------------------------
;
	.assume adl = 0									; code is in z80 mode (non-adl mode)

#include "inc\defines.inc"							; program definitions and equates

_relocate_location:									; relocatable binary location
	.org 0											; relocate main section of code in z80 mode (non-adl mode)
__MAINPROGRAM:										; main entry point
_relocate_start:
TI81ROM:
#import "res\ti81v18k.bin"							; TI-81 1.8K ROM
PORTCODE:
#include "src\port.asm"								; port handling, lcd etc
#include "res\titlebar.inc"							; title bar graphic
_4bppPaletteTable:
#include "res\ti81pal.inc"							; 16 colour palette
_relocate_end:										; end of relocatable binary

#if PORTCODE != $8000								; check ROM is OK
	.echo "WARNING! - TI-81 ROM misalignment!"
#endif
