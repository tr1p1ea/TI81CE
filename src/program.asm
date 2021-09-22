; tr1p1ea - 04/08/2021 (dd/mm/yyyy):
;------------------------------------
;--------------------------------------------------------------
; TI-81 CE - program.asm (launcher)
;--------------------------------------------------------------
;
	.assume adl = 1									; code is in adl mode

#include "inc\defines.inc"							; program definitions and equates

	.org USERMEM-2									; ti-84+ce user memory location
__code_start:	
	.db $EF,$7B										; ti-84+ce asm program id bytes
	
	di												; disable interrupts
	push iy											; save iy
	ld hl,_relocate_start							; start location of relocatable code
	ld de,RELOCATIONADDRESS							; destination location for relocatable code
	ld bc,_relocate_end-_relocate_start
	ldir
	
	xor a
	ld (RELOCATIONADDRESS+bootSaveState),a			; reset save state flag
	ld hl,appVarName
	call _Mov9ToOP1
	call _chkFindSym
	jr c,bootNewCalc								; if no appvar is found, boot as a new calc
	call _ChkInRam									; is it in RAM/Archive?
	call nz,_arc_Unarc
	inc de
	inc de
	ld hl,RELOCATIONADDRESS+$E000					; RAM address (8k)
	ex de,hl
	ld bc,8192
	ldir											; restore RAM
	ld de,RELOCATIONADDRESS+regBackup
	ld bc,29
	ldir											; restore register backup
	ld a,1
	ld (RELOCATIONADDRESS+bootSaveState),a			; set save state flag

bootNewCalc:
	ld a,RELOCATIONADDRESS>>16						; top 8-bits of relocation address
	ld mb,a											; set mbase to top 8-bits of relocation address
	ld.sis sp,Z80MODEENTRYSTACKADDRESS&$FFFF		; set z80 mode stack pointer (end of 64KB code block)
	call.is RELOCATIONADDRESS&$FFFF+$804B			; code is relocated and run in persistent z80 mode - jump to boot handler first
	ld a,$D0										; default mbase value
	ld mb,a											; restore mbase to default value
	ld a,$2D										; default lcd bpp value
	ld (LCDBASEPORTADDRESS + $18),a					; restore lcd to TIOS default
	ld hl,VRAM										; default lcd vram address
	ld (LCDUPBASE),hl								; set default lcd vram address
	pop iy											; restore iy
	ld hl,$00003011									; default interrupt enable mask
	ld ($F00004),hl									; reset interrupt enable mask
	ld hl,$00000019									; default interrupt latch value
	ld ($F0000C),hl									; reset interrupt latch value	
	ei												; re-enable interrupts

saveAppVar:											; this is totally a last minute hack job ... hopefully there are no issues?
	ld hl,appVarName
	call _Mov9ToOP1
	call _chkFindSym
	jr nc,appVarFound
	ld hl,8192+29									; 8k RAM + 29 bytes for register backup
	call _EnoughMem
	jr c,saveAppVarEnd
	ex de,hl
	call _createAppVar
appVarFound:
	call _ChkInRam									; is it in RAM/Archive?
	jr z,appVarInRAM
	call _arc_Unarc
	jr saveAppVar
appVarInRAM:
	inc de
	inc de
	ld hl,RELOCATIONADDRESS+$E000
	ld bc,8192
	ldir											; save contents of RAM to appvar
	ld hl,RELOCATIONADDRESS+regBackup
	ld bc,29
	ldir											; save register backup
	ld hl,appVarName
	call _Mov9ToOP1
	call _arc_Unarc
saveAppVarEnd:
	call _clrScreenFull								; clear screen
	call _drawStatusBar								; redraw status bar	
	ret												; exit program

appVarName:
	.db appVarObj,"TI81CEAV"
 
_relocate_start:
#import "main.bin"									; main program relocatable binary
_relocate_end:

__code_end:

.echo "Program Summary:"
.echo "Relocatable binary size: ",_relocate_end-_relocate_start," bytes"
.echo "Main program stub size (including header): ",(__code_end-__code_start)-(_relocate_end-_relocate_start)+15," bytes"
.echo "Total program size (including header): ",__code_end-__code_start+15," bytes"
