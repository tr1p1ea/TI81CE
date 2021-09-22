; tr1p1ea - 04/08/2021 (dd/mm/yyyy):
;------------------------------------
;--------------------------------------------------------------
; TI-81 CE - defines_stub.inc
;--------------------------------------------------------------
;

#define USERMEM					$D1A881						; usermem
#define VRAM 					$D40000						; vram
#define LCDUPBASE					$E30010						; lcd base address
#define LCDIMSC					$E3001C
#define LCDRIS					$E30020
#define LCDICR					$E30028
#define LCDBASEPORTADDRESS			$E30000
#define _clrScreenFull				$020810						; clear the screen
#define _drawStatusBar				$021A3C						; draw the status bar
#define _Mov9ToOP1				$020320
#define _chkFindSym				$02050C
#define _createAppVar				$021330
#define _ChkInRam					$021F98
#define _arc_Unarc				$021448
#define _EnoughMem				$02051C
#define appVarObj					$15

#define RELOCATIONADDRESS			VRAM							; relocation address for main section of code
#define Z80MODEENTRYSTACKADDRESS		$A100							; address of stack when entering z80 mode (non-adl mode) - to detect boot
#define PORTDATA					$A000							; temporary port data
#define GRAM0					RELOCATIONADDRESS+$10000			; GRAM 0 address
#define GRAM1					GRAM0+((320/2)*240)				; GRAM 1 address
#define GRAMCURRENT				RELOCATIONADDRESS+PORTDATA + 0		; 3 bytes current GRAM pointer
#define regBackup					PORTDATA + 3					; 25 bytes for af, bc, de, hl, af', bc', de', hl', ix, iy, sp, pc, interrupts
#define bootSaveState				regBackup + 25					; 1 byte boot into save state flag (0 = boot new, 1 = restore session)
#define port1KeyGroup				bootSaveState + 1					; 1 byte for key group
#define port5Page					port1KeyGroup + 1					; 1 byte for mem page
#define updateLCDCounter			port5Page + 1					; 1 byte for updateLCD counter
#define exitKeyHoldCounter			updateLCDCounter + 1				; 2 bytes for exit key hold counter

#define EXITKEYHOLDDURATION			300							; default exit key hold counter value (approx 3 seconds)

#define BAK_AF					0
#define BAK_BC					2
#define BAK_DE					4
#define BAK_HL					6
#define BAK_AFS					8
#define BAK_BCS					10
#define BAK_DES					12
#define BAK_HLS					14
#define BAK_IX					16
#define BAK_IY					18
#define BAK_SP					20
#define BAK_PC					22
#define BAK_INT					24

#define LCDOFFCOLOUR				$88
#define TI81BGCOLOUR				$77
#define DARKGRAYCOLOUR				$66