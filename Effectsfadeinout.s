*****************
** S C E N E 2 **
*****************

; copper plasma

; sprites 
; lines

; image wave appear
Scene2PreCalc:
	; Example: Set bitplane pointer
	;move.l	ChipPtr(pc),a1
	;lea.l	Bitplane-Chip(a1),a3
	
	lea.l	ImageOne, a3

	lea.l	CopperBplPtr2,a2
	moveq	#5-1,d7
.setupBitplanes:
	move.l	a3,d0
	add.w	#40,a3
	move.w	d0,6(a2)
	swap	d0
	move.w	d0,2(a2)
	add.w	#8,a2
	dbra	d7,.setupBitplanes

; Setup sprites to zero sprites to avoid glitches

	lea		Copper2SprPtr,a2
	lea		NullSprite,a3
	moveq	#8-1,d7
.setupSprites:
	move.l	a3,d0
	move.w	d0,6(a2)
	swap	d0
	move.w	d0,2(a2)
	add.w	#8,a2
	dbra	d7,.setupSprites


; Creates a full black colorpalette in copperlist
; d0 colorregister + color
; d7 color counter
; a0 copperlist pointer
; 	
	clr.w	d1
	move.l	#color, d0			
	move    #32-1, d7
	lea		CopperColors2, a0
.loadPal
	swap	d0	; reg:color
	move.l	d0, (a0)+
	swap	d0
	addq.w	#2, d0
	dbra	d7, .loadPal

	rts

Scene2Init:
	lea CopperScene2, a1
	move.l	a1, $dff080

	move.l	#SC2_FadeIn, SC2_Phase	
	move.w	#SC2FadeInFrames, SC2_ShowFrames
	rts

; Frames to skip before changing colors
SC2_Skip: equ 4

SC2_SkipCounter:
	dc.w	$0
SC2_ColorPhase:
	dc.w	$0
SC2_ShowFrames:
	ds.w	1
SC2_Phase:
    dc.l    0

SC2FadeInFrames:	equ 15
SC2FadeOutFrames:	equ 15
SC2HoldFrames:		equ 100

Scene2:
	movea.l SC2_Phase, a2
	jmp     (a2)

SC2_Stay:
	move.w	SC2_ShowFrames, d0
	tst.w   d0
	beq		.nextPart
	subq.w	#1, d0
	move.w  d0, SC2_ShowFrames
	rts
.nextPart:	
	move.l	#SC2_FadeOut, SC2_Phase	
	move.w	#SC2FadeOutFrames, SC2_ShowFrames
	rts

SC2_FadeIn:
	move.w	SC2_ShowFrames, d0
	tst.w   d0
	beq		.nextPart
	subq.w	#1, d0
	move.w  d0, SC2_ShowFrames
	moveq	#1, d0
	bra.s   SC2_Fade
.nextPart:
	move.w  #0, SC2_ColorPhase
	move.l	#SC2_Stay, SC2_Phase	
	move.w	#SC2HoldFrames, SC2_ShowFrames
	rts

SC2_FadeOut:
	move.w	SC2_ShowFrames, d0
	tst.w   d0
	beq		.nextPart
	subq.w	#1, d0
	move.w  d0, SC2_ShowFrames
	moveq	#-1, d0
	bra.s   SC2_Fade
.nextPart:
	; no more 	scenes
	; Jmp NextScene to go to next scene
	rts


	;d0 : upordown INPUT : 1 up, -1 down
	;d1 : desired color component
	;d2 : mask
	;d3 : colorphase
SC2_Fade:
	; Calculate the current fade for all 15 intensities
	lea		SC2_SmoothColor+30, a0
	lea		SC2_CurrentColorComponent+30, a1
	moveq	#$f, d1			; f->0
	move.w  SC2_ColorPhase, d3 
	WinUAEBreakpoint
.nextComponent
	move.w	(a0), d2
	subq.w  #2, a0
	btst    d3, d2
	beq.s   .skipChange
	move.w	(a1), d2
	add.w	d0,d2
	move.w	d2, (a1)
.skipChange:
	subq.w  #2, a1
	dbra	d1, .nextComponent
	
	addq.w	#1, d3
	move.w  d3, SC2_ColorPhase

	; d0 counter
	; a0 copper palette
	; a1 final RAW palette
	; d1 final color
	; d2 scratch
	; d3 current color
	lea		CopperColors2, a0
	addq.w  #2, a0			; Skip the register identification word
	lea     PaletteOne, a1
	lea		SC2_CurrentColorComponent, a2
	moveq   #32-1, d0
	
.nextColor
	move.w	(a1)+, d1
	move.w	d1, d2
	and.w   #$0f, d2
	lsl		#1, d2
	move.w  (a2, d2), d3 ; 00X done
	lsr.w	#4, d1
	move.w  d1, d2
	and.w 	#$0f, d2
	lsl		#1, d2
	move.w  (a2, d2), d2
	lsl.w   #4, d2
	or.w    d2, d3       ; 0Xx done
	lsr.w	#4, d1
	move.w  d1, d2
	lsl		#1, d2
	move.w	(a2, d2), d2
	lsl.w   #8, d2
	or.w    d2, d3       ; Xxx done
	move.w  d3, (a0)
	addq.w  #4, a0
	dbra    d0, .nextColor
	rts

NextScene:


SC2_SmoothColor
	dc.w	$0000  ; 0
	dc.w	$0020  ; 1
	dc.w	$2020  ; 2 
	dc.w	$2022  ; 3 
	dc.w	$2222  ; 4 
	dc.w	$22a2  ; 5 
	dc.w	$a2a2  ; 6 
	dc.w    $a2aa  ; 7 
	dc.w    $aaaa  ; 8 
	dc.w    $aaba  ; 9 
	dc.w    $baba  ; 10
	dc.w    $babb  ; 11
	dc.w    $bbbb  ; 12
	dc.w    $bbfb  ; 13
	dc.w    $fbfb  ; 14
	dc.w    $ffbf  ; 15
SC2_CurrentColorComponent:
	ds.w    15