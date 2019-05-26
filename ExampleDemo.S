
	include "custom.i"


; Select music player
; 0: none
; 1: The Player 6.1a (P61)
; 2: Future Composer
; 3: TFMX
; 4: AHX
; 5: Octamed SoundStudio
;MUSICPLAYER=	1		;note: is set in the bat file
	

;for different music players (AHX, Octamed type 1, the player, TFMX) choose vblank instead of timer interrupt
; 0 = use cia
; 1 = use vblank
; 2 = use cia timing, but actually update the music in vblank (only useful on ahx and TFMX)
MUSICPLAYERUSEVBLANK=		0


TFMXTEST:			equ		4

;0= 4 channel
;1= 8 channel
OCTAMEDPLAYERTYPE=			0

SHOWMUSICRASTERLINES=		Debug		; waits until $2c before starting the vblank code, and shows colors red=vblank, green=non-vblank

; Compact demo-startup by Blueberry/Loonies
; Example usage source code
; Version 1.3, August 22, 2013
; Public Domain

; Set demo compatibility
; 0: 68000 only, Kickstart 1.3 only, PAL only
; 1: All CPUs, Kickstarts and display modes
; 2: 68010+, Kickstart 3.0+, all display modes
COMPATIBILITY=				1

; Set to 1 to require fast memory
FASTMEM=					0

; Set to 1 to enable pause on right mouse button
; with single-step on left mouse button
RMBPAUSE=					1

; Set to 1 if you use FPU code in your interrupt
FPUINT=						0

; Set to 1 if you use bitplane, copper, blitter or sprites, respectively
BITPLANE=					1
COPPER=						1
BLITTER=					1
SPRITE=						1

; Set to 1 to get address of topaz font data in TopazCharData
TOPAZ=						0

; Set to 1 when writing the object file to enable section hack
SECTIONHACK=				UseMiniPacker


										; Demo startup must be first for section hack to work
	include	DemoStartup.s

BLT_A:				equ		%11110000
BLT_B:				equ		%11001100
BLT_C:				equ		%10101010

					rsreset
Bob_WidthInWords:	rs.w	1
Bob_NumSprites:		equ		Bob_WidthInWords
Bob_Height:			rs.w	1
Bob_Width:			rs.w	1
Bob_Offset:			rs.l	1
Bob_AnchorX:		rs.w	1
Bob_AnchorY:		rs.w	1
Bob_SizeOf:			rs.b	0


************************************
_Precalc:
	; Called as the very first thing, before system shutdown
	bsr		Scene1PreCalc
	bsr		Scene2PreCalc
	rts


************************************
_Exit:
			; Called after system restore

	opt o-	;Hannibal disable optimizations when doing self-modifying code

			; Example: Cache flush test
	move.w	#1000-1,d7
.code:
	move.l	#1,d2
	lea.l	.code+2(pc),a0
	addq.l	#1,(a0)
	CACHEFLUSH
	dbf		d7,.code
			; D2 should be 1000 here

	opt o+	;Hannibal re-enable optimizations after self-modifying code
	moveq.l	#0,d0
	rts


************************************
_Main:
	; Main demo routine, called by the startup.
	; Demo will quit when this routine returns.
	; Example: Set copper address

	lea.l	CopperScene1,a1
	move.l	a1, $dff080

.MainLoop:
	;you could do stuff here. This example does everything in interrupt, though, so not needed
	bra.s	.MainLoop


************************************
_Interrupt:
	; Called by the vblank interrupt.

	move.l	ScenePtr,a0
	jmp		(a0)

	even

ScenePtr:
	dc.l	Scene1


*************
** SCENE 1 **
*************
	include scene1.s
	move.l	#Scene2, ScenePtr
	jmp		Scene2Init

*************
** SCENE 2 **
*************
	include scene2.s


; copper plasma
; per row bpl adressing
; Wave on a picture

					; Init picture copperlist in precalc

					;lea.l	VBlank(pc),a0
					;move.l	(a0),d0
					;cmp.w	#FRAMES_ON_SCENE_1,d0
					;bne		.exit
					;move.l	#Scene2,ScenePtr

	if MUSICPLAYER=2
		section	datachip,data_c
FCModule:
		incbin	"Assets/cytax-ice02-intro-14.fc"
	endc


	even

	section datachip,data_c

	***************************
	** Initialized CHIP data **
	***************************

CopperScene1:
	dc.w	diwstrt, $2c81
	dc.l	$00902cc1
	dc.l	$00920038,$009400d0
	dc.l	$01000200,$01020000
	dc.l	$01080000+3*40,$010a0000+3*40
	dc.l	$01060000,$010c0011
	dc.l	$01fc0000
	dc.l	$ffe1fffe
	dc.l	$fffffffe

CopperScene2:
	dc.l	$008e2c81,$00902cc1
	dc.l	$00920038,$009400d0
	dc.l	$01005200,$01020000
	dc.l	$01080000+4*40,$010a0000+4*40
	dc.l	$01060000,$010c0011
Copper2SprPtr:
	dc.l	$01200000,$01220000
	dc.l	$01240000,$01260000
	dc.l	$01280000,$012a0000
	dc.l	$012c0000,$012e0000
	dc.l	$01300000,$01320000
	dc.l	$01340000,$01360000
	dc.l	$01380000,$013a0000
	dc.l	$013c0000,$013e0000
CopperBplPtr2:
	dc.l	$00e00000,$00e20000
	dc.l	$00e40000,$00e60000
	dc.l	$00e80000,$00ea0000
	dc.l	$00ec0000,$00ee0000
	dc.l	$00f00000,$00f20000
					; Wait till start v $2c-1
					;dc.w	$2b01, $ff00

CopperColors2:
	ds.l	33 * 16	; 16 color sets with 32 colors each + wait instruction
CopperPlanePointers:
	dc.l	$01fc0000
	dc.l	$ffe1fffe
	dc.l	$fffffffe

PaletteOne:
	incbin '.\ConvertedAssets\imageGround.PAL'
	even
ImageOne:
	incbin '.\ConvertedAssets\imageGround.BPL'
	even

	even

*****************************************
** Scratch chip data, set to 0 on load **
*****************************************
	; Place all chip space in the single chip section.
	; Define no other sections.

	section	bsschip,bss_c
Chip:

	if MUSICPLAYER=3
TFMXChipBuffer:
		ds.l	512
	endif
Bitplane:
	ds.b	40*256*5
NullSprite:
	dc.l	0,0,0,0
	
;Shallow Hash=14821718825120332491802322484210225518716356
