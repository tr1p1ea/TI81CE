; tr1p1ea - 04/08/2021 (dd/mm/yyyy):
;------------------------------------
;--------------------------------------------------------------
; TI-81 CE - port.inc
;--------------------------------------------------------------
;
	.assume adl = 0									; code is in z80 mode (non-adl mode)
	
handlePort:
	ld (regBackup + BAK_AF),a						; save registers - using too much stack interferes with self-test?
	ld (regBackup + BAK_BC),bc
	ld (regBackup + BAK_DE),de
	ld (regBackup + BAK_HL),hl
	ld (regBackup + BAK_SP),sp
	push af											; preserve flags
	
	ld de,(exitKeyHoldCounter)						; check if exit key counter has reached zero (on key held for approx 3 seconds)
	ld a,d
	or e
	jp z,exitROM

	ld hl,(regBackup + BAK_SP)
	ld de,(hl)
	ld a,(de)										; get port value from code address
	inc de
	ld (hl),de										; advance return address on stack beyond port byte

	cp 1											; jump to appropriate port handler (no contrast handling for now)
	jp z,handlePortIn1
	cp 3
	jp z,handlePortIn3
	cp 5
	jp z,handlePortIn5
	cp 1|$80
	jp z,handlePortOut1
	cp 3|$80
	jp z,handlePortOut3
	cp 4|$80
	jp z,handlePortOut4
	cp 5|$80
	jp z,handlePortOut5
	jp portExit										; port invalid or doesnt require handling

ROMBooting:
	di												; just to be sure
	
	ld hl,ROMPatchTable
	ld a,(hl)										; patch ROM
	inc hl
_patchROMLoop:
	ld de,(hl)										; get address
	inc hl
	inc hl
	ld bc,(hl)										; get patch data
	ex de,hl
	ld (hl),bc										; write
	ex de,hl
	inc hl
	inc hl
	dec a
	jr nz,_patchROMLoop	
	
	ld a,$25
	ld.lil (LCDBASEPORTADDRESS + $18),a				; set 4bpp mode
	ld.lil hl,RELOCATIONADDRESS&$FF0000|_4bppPaletteTable
	ld.lil de,LCDBASEPORTADDRESS + $200				; palette mem
	ld.lil bc,16*2									; 16 * 16-bit (RGB1555) colour entries
	ldir.lil										; copy palette to palette mem
	ld.lil hl,GRAM1
	ld.lil (LCDUPBASE),hl							; set lcdupbase pointer
	ld.lil hl,GRAM0
	ld.lil (GRAMCURRENT),hl							; set starting GRAM pointer
	push.lil hl
	pop.lil de
	inc.lil de
	ld.lil (hl),TI81BGCOLOUR
	ld.lil bc,((320/2)*240)-1
	ldir.lil										; fill screen with bg colour
	
	ld.lil hl,RELOCATIONADDRESS&$FF0000|titleBar	; draw titlebar graphic
	ld.lil de,GRAM0+(14/2)+(5*(320/2))
	ld.lil bc,292/2
	ld.lil ix,0
	ld a,27
	call fillLCDBlock
	
	call drawLCDAreaOff
	
	ld.lil hl,GRAM0									; copy GRAM0 to GRAM1
	ld.lil de,GRAM1
	ld.lil bc,(320/2)*240
	ldir.lil
	
	xor a
	ld.lil ($F20030 + 0),a							; disable timer1
	ld.lil ($F20000 + 1),a
	ld.lil ($F20000 + 2),a
	ld.lil ($F20000 + 3),a							; timer1 counter
	ld.lil ($F20004 + 1),a
	ld.lil ($F20004 + 2),a
	ld.lil ($F20004 + 3),a							; timer1 reset value
	ld.lil ($F00004 + 0),a							; disable interrupts for on key and timer1 on boot
	ld.lil ($F00004 + 1),a
	ld.lil ($F00004 + 2),a
	ld.lil ($F00004 + 3),a
	ld.lil ($F0000C + 0),a							; disable latches for on key and timer1
	ld.lil ($F0000C + 1),a
	ld.lil ($F0000C + 2),a
	ld.lil ($F0000C + 3),a
	cpl												; value that it will never reach (not sure if required)
	ld.lil ($F20008 + 3),a							; match value 1
	ld.lil ($F2000C + 3),a							; match value 2
	ld a,32768/200
	ld.lil ($F20000 + 0),a							; apparently the TI-81 timer runs at 200Hz?
	ld.lil ($F20004 + 0),a
	
	ld hl,(1<<0)|(1<<1)|(1<<2)|(0<<9)				; enable | 32KHz | generate interrupt on zero | count down
	ld a,l
	ld.lil ($F20030 + 0),a
	ld a,h
	ld.lil ($F20030 + 1),a							; setup & enable timer1
	
	ld hl,EXITKEYHOLDDURATION
	ld (exitKeyHoldCOunter),hl

	ld a,%00000100
	ld.lil ($F5000C),a								; latch indiscriminate key detection interrupt
	
	ld a,(bootSaveState)
	or a	
	jp z,$020F										; boot new calc if no save state is detected
	
loadSaveState:										; restore registers and interrupt data (port data restored by launcher)
	ld a,(regBackup + BAK_INT)
	ld c,a
	and %00000011
	ld.lil ($F0000C + 0),a							; restore latched interrupt
	ld a,c
	rrca
	rrca
	and %00000011
	ld.lil ($F00004 + 0),a							; restore enabled interrupts
	and %10000000
	jr z,$+4
	ld a,$FB										; opcode for ei
	ld (_smc_ei_0 + 0),a							; enable interrupts if required

	ld hl,(regBackup + BAK_AF)
	push hl
	pop af											; restore af
	ex af,af'
	ld hl,(regBackup + BAK_AFS)
	push hl
	pop af											; restore af'
	ex af,af'
	ld bc,(regBackup + BAK_BC)						; restore bc
	ld de,(regBackup + BAK_DE)						; restore de
	ld hl,(regBackup + BAK_HL)						; restore hl
	exx
	ld bc,(regBackup + BAK_BCS)						; restore bc'
	ld de,(regBackup + BAK_DES)						; restore de'
	ld hl,(regBackup + BAK_HLS)						; restore hl'
	exx
	ld ix,(regBackup + BAK_IX)						; restore ix
	ld iy,(regBackup + BAK_PC)						; restore pc
	ld sp,(regBackup + BAK_SP)						; restore sp
	push iy											; set pc address for ret
	ld iy,(regBackup + BAK_IY)						; restore iy
_smc_ei_0:
	nop												; enable interrupts if required (self-modified)
	ret												; jump to save state pc

exitROM:											; save register state
	pop bc
	ld (regBackup + BAK_AF),bc						; save af
;	ld (regBackup + BAK_BC),bc						; save bc - already saved
;	ld (regBackup + BAK_DE),de						; save de - already saved
;	ld (regBackup + BAK_HL),hl						; save hl - already saved
	exx
	ld (regBackup + BAK_BCS),bc						; save bc'
	ld (regBackup + BAK_DES),de						; save de'
	ld (regBackup + BAK_HLS),hl						; save hl'
	exx
	ex af,af'
	push af
	ex af,af'
	pop bc
	ld (regBackup + BAK_AFS),bc						; save af'
	ld (regBackup + BAK_IX),ix						; save ix
	ld (regBackup + BAK_IY),iy						; save iy
;	ld (regBackup + BAK_SP),sp						; save sp - already saved
	or a
	sbc hl,hl
	add hl,sp
	ld hl,(hl)
	dec hl											; fix pc to current port instruction
	ld (regBackup + BAK_PC),hl						; save pc

	ld c,%10000000									; detect interrupts?
	ld a,i
	jp pe,$+5
	ld c,%00000000

	ld.lil a,($F00004 + 0)							; save enabled interrupts
	and %00000011
	rlca
	rlca
	ld b,a
	ld.lil a,($F0000C + 0)							; save latched interrupts
	and %00000011
	or b
	or c											; set interrupt enabled flag
	ld (regBackup + BAK_INT),a						; save interrupt status

	ld sp,Z80MODEENTRYSTACKADDRESS - 2				; hopefully nothing overwrote this ... :X
	ret.l											; exit back to launcher

handlePortIn1:
	ld a,(port1KeyGroup)							; key group
	ld.lil hl,$F50000
	or a
	jr nz,_checkKeyGroup							; 0 = TIOS checks for any key press before checking each row
	ld.lil (hl),1									; set indiscriminate key detection mode
	ld.lil a,($F50008)
	and %00000100
	ld.lil ($F50008),a								; acknowledge interrupt if present
	ld.lil (hl),2									; set single scan mode  -should complete before we check again
	jp _checkKeyEnd
_checkKeyGroup:
	ld b,a
	xor a
	cp.lil a,(hl)									; wait for key scan to complete
	jr nz,$-2
	ld.lil hl,$F5001E + 2							; select appropriate CE key group
	dec.lil hl
	dec.lil hl
	rrc b											; key group
	jr c,$-6
	ld.lil a,(hl)
_checkKeyEnd:
	cpl
	ld (regBackup + BAK_AF),a
	jp portExit

handlePortIn3:
	ld.lil a,($F00014)
	and %00000011									; get on key & timer1 interrupt status
	ld.lil hl,$F00020
	bit.lil 0,(hl)
	jr nz,$+4
	or %00001000									; clear on key pressed if applicable
	ld (regBackup + BAK_AF),a
	jp portExit

handlePortIn5:
	ld a,(port5Page)
	ld (regBackup + BAK_AF),a
	jp portExit

handlePortOut1:
	ld a,(regBackup + BAK_AF)
	ld (port1KeyGroup),a
	jp portExit
	
handlePortOut3:										; probably overkill on the timer stuff
	ld a,(regBackup + BAK_AF)
	cp $09											; update LCD once everything is running, this port write *mostly* occurs once/twice per interrupt?
	call z,updateLCD
	ld a,(regBackup + BAK_AF)
	ld c,a
	rrca
	jr nc,_ackOnInt
_OnInt:
	ld.lil a,($F00004)								; enable on key interrupt
	or %00000001
	ld.lil ($F00004),a
	ld.lil a,($F0000C + 0)							; latch on key interrupt
	or %00000001
	ld.lil ($F0000C + 0),a
	jr _checkTimer
_ackOnInt:
	ld a,%00000001
	ld.lil ($F00008),a								; acknowledge on key interrupt
_checkTimer:
	bit 1,c
	jr z,_ackTmrInt
_TmrInt:
	ld.lil a,($F00004)								; enable timer1 interrupt
	or %00000010
	ld.lil ($F00004),a
	jr _checkLCD
_ackTmrInt:
	ld a,%00000010
	ld.lil ($F00008),a								; acknowledge timer1 interrupt
	ld.lil a,($F00004)								; disable timer1 interrupt
	and %11111101
	ld.lil ($F00004),a
_checkLCD:
	bit 3,c
	jp nz,portExit
_lcdOff:
	call drawLCDAreaOff
	ld.lil hl,GRAM0									; copy GRAM0 to GRAM1
	ld.lil de,GRAM1
	ld.lil bc,(320/2)*240
	ldir.lil
	jp portExit

handlePortOut4:
	ld a,(regBackup + BAK_AF)
	rrca
	jr nc,_timer1On
_timer1Off:
	ld.lil a,($F0000C + 0)							; dont latch timer1 interrupt
	and %11111101
	ld.lil ($F0000C + 0),a
	jp portExit
_timer1On:
	ld.lil a,($F0000C + 0)							; latch timer1 interrupt
	or %00000010
	ld.lil ($F0000C + 0),a
	jp portExit
handlePortOut5:
	ld a,(regBackup + BAK_AF)
	ld (port5Page),a
	jp portExit

portExit:
	pop af											; resetore registers (and flags)
	ld a,(regBackup + BAK_AF)
	ld bc,(regBackup + BAK_BC)
	ld de,(regBackup + BAK_DE)
	ld hl,(regBackup + BAK_HL)
	ret

updateLCD:											; expands each pixel into 3x3 CE pixels ... a hack that may need to be reworked, seems ok for now though
	ld.lil a,($F00020)								; check for exit key being held only when calc is running (LCD is ok to be updated)
	ld hl,(exitKeyHoldCounter)						; count down if on key is pressed, reset counter if not pressed
	dec hl
	rrca
	jr c,$+5
	ld hl,EXITKEYHOLDDURATION
	ld (exitKeyHoldCounter),hl

	ld a,(updateLCDCounter)
	inc a
	cp 15
	jr nz,$+3
	xor a
	ld (updateLCDCounter),a
	ret nz											; 200Hz / 16 = 12.5fps? ... need to measure how often it is actually updating

	ld.lil hl,(GRAMCURRENT)							; expand each row of pixels 1->3
	ld.lil de,(32/2/2)+(40*(320/2))
	add.lil hl,de
	push.lil hl
	ex.lil de,hl

	ld hl,$E000
	ld b,64
_copyLCDLoop1:
	push bc
	xor a
	ld b,96/8
_copyLCDLoop2:
	rlc (hl) \ sbc a,a \ ld.lil (de),a \ inc.lil de \ inc.lil de \ and %00001111 \ ld c,a \ rlc (hl)
	sbc a,a \ ld.lil (de),a \ dec.lil de \ and %11110000 \ or c \ ld.lil (de),a \ inc.lil de \ inc.lil de
	rlc (hl) \ sbc a,a \ ld.lil (de),a \ inc.lil de \ inc.lil de \ and %00001111 \ ld c,a \ rlc (hl)
	sbc a,a \ ld.lil (de),a \ dec.lil de \ and %11110000 \ or c \ ld.lil (de),a \ inc.lil de \ inc.lil de
	rlc (hl) \ sbc a,a \ ld.lil (de),a \ inc.lil de \ inc.lil de \ and %00001111 \ ld c,a \ rlc (hl)
	sbc a,a \ ld.lil (de),a \ dec.lil de \ and %11110000 \ or c \ ld.lil (de),a \ inc.lil de \ inc.lil de
	rlc (hl) \ sbc a,a \ ld.lil (de),a \ inc.lil de \ inc.lil de \ and %00001111 \ ld c,a \ rlc (hl)
	sbc a,a \ ld.lil (de),a \ dec.lil de \ and %11110000 \ or c \ ld.lil (de),a \ inc.lil de \ inc.lil de
	inc hl
	djnz _copyLCDLoop2
	ex.lil de,hl
	ld.lil bc,((320/2)-(96+(96/2)))+(320/2*2)
	add.lil hl,bc
	ex.lil de,hl
	pop bc
	dec b
	jp nz,_copyLCDLoop1
	
	pop.lil de										; copy rows vertically 1->3
	ld.lil hl,320/2
	add.lil hl,de
	ex.lil de,hl
	ld b,64
_copyLCDYLoop:
	push bc
	ld.lil bc,288/2
	ldir.lil
	ld.lil bc,(320/2)-(288/2)
	add.lil hl,bc
	ex.lil de,hl
	add.lil hl,bc
	ex.lil de,hl
	ld.lil bc,288/2
	ldir.lil
	ld.lil bc,(320/2*2)-(288/2)
	add.lil hl,bc
	ex.lil de,hl
	add.lil hl,bc
	ex.lil de,hl
	pop bc
	djnz _copyLCDYLoop

	ld.lil hl,GRAM0									; swap GRAM pointers (double buffering)
	ld.lil de,(LCDUPBASE)
	or a
	sbc.lil hl,de
	add.lil hl,de
	ld.lil de,GRAM1
	jr nz,$+12
	ld.lil hl,GRAM1
	ld.lil de,GRAM0
	ld.lil (GRAMCURRENT),de							; set up the new buffer location
	ld.lil (LCDUPBASE),hl							; set the new pointer location
	ld.lil hl,LCDICR
	set.lil 2,(hl)									; clear the previous interrupt set
	ld.lil l,LCDRIS&$ff
	bit.lil 2,(hl)									; wait until the interrupt triggers
	jr z,$-3
	ret

drawLCDAreaOff:
	ld.lil hl,GRAM0+(12/2)+(36*(320/2))				; fill 'inactive' lcd border area
	push.lil hl
	push.lil hl
	pop.lil de
	inc.lil de
	ld.lil (hl),LCDOFFCOLOUR
	ld.lil bc,296/2-1
	push.lil bc
	ldir.lil										; copy 1st line
	pop.lil bc
	inc.lil bc
	pop.lil hl
	ld.lil de,GRAM0+(12/2)+(37*(320/2))
	ld.lil ix,(320/2)-(296/2)
	ld a,200-1
	call fillLCDBlock
	
	ld a,(DARKGRAYCOLOUR&$F0)|(TI81BGCOLOUR&$0F)	; round corners of 'inactive' lcd border area
	ld.lil (GRAM0+(12/2)+(36*(320/2))),a
	ld a,(LCDOFFCOLOUR&$F0)|(DARKGRAYCOLOUR&$0F)
	ld.lil (GRAM0+(12/2)+(37*(320/2))),a
	ld a,(TI81BGCOLOUR&$F0)|(DARKGRAYCOLOUR&$0F)
	ld.lil (GRAM0+(306/2)+(36*(320/2))),a
	ld a,(DARKGRAYCOLOUR&$F0)|(LCDOFFCOLOUR&$0F)
	ld.lil (GRAM0+(306/2)+(37*(320/2))),a
	ld a,(LCDOFFCOLOUR&$F0)|(DARKGRAYCOLOUR&$0F)
	ld.lil (GRAM0+(12/2)+(234*(320/2))),a
	ld a,(DARKGRAYCOLOUR&$F0)|(TI81BGCOLOUR&$0F)
	ld.lil (GRAM0+(12/2)+(235*(320/2))),a
	ld a,(DARKGRAYCOLOUR&$F0)|(LCDOFFCOLOUR&$0F)
	ld.lil (GRAM0+(306/2)+(234*(320/2))),a
	ld a,(TI81BGCOLOUR&$F0)|(DARKGRAYCOLOUR&$0F)
	ld.lil (GRAM0+(306/2)+(235*(320/2))),a
	ret

fillLCDBlock:
	; hl = source
	; de = destination
	; bc = width
	; a = height
	; ix = hl offset after line
	;
	push.lil bc
	push.lil bc
	ldir.lil
	ld.lil bc,320/2
	ex.lil de,hl
	add.lil hl,bc
	pop.lil bc
	or a
	sbc.lil hl,bc
	ex.lil de,hl
	push.lil ix
	pop.lil bc
	add.lil hl,bc	
	pop.lil bc
	dec a
	jr nz,fillLCDBlock
	ret

;_4bppPaletteTable:
;	.dw $CA8F,$EACB,$BD84,$A4E3,$F39B,$C210,$A108,$94C7
;	.dw $CED0,$8000,$BE2D,$B1CB,$A969,$9D07,$94A5,$8863

ROMPatchTable:										; 1.8K only
	.db 34
	.dw $0000 \ .db $C3,$00
	.dw $0002 \ .db $80,$00
	.dw $003A \ .db $C7,$03
	.dw $0044 \ .db $C7,$83
	.dw $0048 \ .db $C7,$83
	.dw $006F \ .db $C7,$03
	.dw $007F \ .db $C7,$05
	.dw $008D \ .db $C7,$83
	.dw $0093 \ .db $C7,$05
	.dw $00A2 \ .db $C7,$83
	.dw $00B5 \ .db $C7,$83
	.dw $00E9 \ .db $C7,$83
	.dw $00F1 \ .db $C7,$83
	.dw $00FA \ .db $C7,$83
	.dw $0108 \ .db $C7,$84
	.dw $010C \ .db $C7,$85
	.dw $0113 \ .db $C7,$83
	.dw $0142 \ .db $C7,$82
	.dw $01B7 \ .db $C7,$03
	.dw $01C3 \ .db $C7,$83
	.dw $0222 \ .db $C7,$84
	.dw $0226 \ .db $C7,$80
	.dw $022C \ .db $C7,$87
	.dw $022F \ .db $C7,$82
	.dw $0232 \ .db $C7,$83
	.dw $0236 \ .db $C7,$83
	.dw $266A \ .db $C7,$81
	.dw $2670 \ .db $C7,$01
	.dw $2675 \ .db $C7,$81
	.dw $271E \ .db $C7,$82
	.dw $70AA \ .db $C7,$82
	.dw $70EB \ .db $C7,$82
	.dw $70FE \ .db $C7,$82
	.dw $7FFE \ .db $B7,$C0
