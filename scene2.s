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
	lea		SC2_FadeIn, a1
	move.l  a1, SC2_Phase
	rts

; Frames to skip before changing colors
SC2_Skip: equ 4

SC2_SkipCounter:
	dc.w	$0

SC2_ColorPhase:
	dc.w	$0
	
SC2_ShowFrames:
	dc.w	100

SC2_Phase:
    dc.l    0

Scene2:
	movea.l SC2_Phase, a2
	jmp     (a2)

; #Run vblank every SC2_Skip frames
	

SC2_Stay:
	move.w	SC2_ShowFrames, d0
	tst.w   d0
	beq		.continue
	subq.w	#1, d0
	move.w  d0, SC2_ShowFrames
	rts
.continue:	
	lea		SC2_FadeOut, a1
	move.l  a1, SC2_Phase
	rts

SC2_FadeIn:
	move.w	SC2_ColorPhase, d0		; d0 : colorphase
	cmp.w	#$f, d0
	beq		.stay
	lea		ColorChangeUp, a3
	bra		SC2_Fade
.stay:
	move.w	#0, SC2_ColorPhase
	lea		SC2_Stay, a1
	move.l  a1, SC2_Phase
	rts

SC2_FadeOut:
	move.w	SC2_ColorPhase, d0		; d0 : colorphase
	cmp.w	#$f, d0
	beq		.down
	lea		ColorChangeDown, a3
	bra		SC2_Fade
.down:
	; no more scenes
	rts

	
SC2_Fade:

	lea		SC2_SmoothColor, a0		; a0 : smooth color pointer [x] 
	lea		CopperColors2, a1		; a1 : copper color table   [x] 
	addq.l  #2, a1
	lea		PaletteOne, a2			; a2 : RAW final palette    [ ]
	moveq   #32-1, d1
.nextColor							
							; a1 : colors in copperlist shifted by 2							
							; d0  :color phase
							; d1 : palette index							
	move.w	(a2)+, d2		; d2 : final color					 => d3 component
	move.w	(a1), d6		; d6 : current color				 => d4 component
	clr.w	d7				; d7 : output color

	; LOWER 4 bits
	move.w	d2, d3			; d3 : 4 bit desired color component
	move.w	d6, d4			; d4  : 4 bit current color component		
	jsr		(a3)
	move.w  d4, d7

	; MIDDLE 4 bits
	lsr.w   #4, d2
	move.w	d2, d3
	lsr.w	#4, d6
	move.w	d6, d4
	jsr		(a3)
	lsl.w   #4, d4
	or.w  d4, d7

	; HIGHEST 4 bites
	lsr.w   #4, d2
	move.w	d2, d3
	lsr.w	#4, d6
	move.w	d6, d4
	jsr		(a3)
	lsl.w   #8, d4
	or.w  d4, d7

	move.w	d7, (a1)
	addq.w	#4, a1

	dbra.w	d1, .nextColor

	addq.w	#1, d0
	move.w	d0, SC2_ColorPhase		; d0 : colorphase		
.skipDirectionSwap

.end
	rts

; TOUCHES d5
; d0 : colorphase
; d3 : 4 bit FINAL color component		-> DESTROYED
; d4 : 4 bit current color component	-> OUT
; d5 :									-> DESTROYED
; a0 : smooth color pointer
ColorChangeUp:
	and.w	#$f, d3
	lsl.w   #1, d3
	and.w   #$f, d4
							; d0 : colorphase
							; d3 : 4 bit color component
	move.w	(a0,d3), d5		; d5 : skip bitmask
	btst    d0, d5
	beq .end
	addq.w	#1, d4
.end
	rts

ColorChangeDown:
	and.w	#$f, d3
	lsl.w   #1, d3
	and.w   #$f, d4
							; d0 : colorphase
							; d3 : 4 bit color component
	move.w	(a0,d3), d5		; d5 : skip bitmask
	btst    d0, d5
	beq .end
	subq.w	#1, d4
.end
	rts


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