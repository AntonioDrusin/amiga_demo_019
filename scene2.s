*****************
** S C E N E 2 **
*****************

; Copper horizontal light ray

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

SetupCopperWaits:
	lea		CopperColors2, a0		; a0 copperlist pointer
	lea		CopperColortable, a1	; a1 colortable pointer.
	move.w	#$2b, d2				; d2 Vertical BEAN POSITION
	move.w	#256 - 1, d0			; d0 counter (256 iterations)
									; d1 SCRATCH
.next:
	move.w	#cop1lc+2, (a0)+
	move.l	a1, d1
	move.w	d1, (a0)+			; MOVE A1, COP1LCL
	swap	d1
	move.w	#cop1lc, (a0)+		
	move.w	d1, (a0)+			; MOVE A1, COP1LCH
	move.l	a0, d1
	add.w	#16, d1				; Skips 4 instructions (4 longs)
	move.w	#cop2lc+2, (a0)+
	move.w	d1, (a0)+			; MOVE RET, COP2LCL
	move.w	#cop2lc, (a0)+
	swap	d1
	move.w	d1, (a0)+			; MOVE RET, COP2LCH

	move.w	d2, d1
	lsl.w	#8, d1
	or.w	#$db, d1			; Horizontal spacing + set bit 0 DB seems to be after last paint
	move.w	d1, (a0)+			; WAIT d2,00 
	move.w	#$fffe, (a0)+		; ignore horizontals for now.		

	move.w	#copjmp1, (a0)+		;
	move.w	d0, (a0)+			; MOVE garbage, COMPJMP1

	addq.w	#1, d2				; next scanline
	dbra	d0, .next


	; finish copper list
	move.l  #CopperScene2, d1
	move.w	#cop1lc+2, (a0)+
	move.w	d1, (a0)+			; MOVE A1, COP1LCL
	swap	d1
	move.w	#cop1lc, (a0)+		; MOVE A1, COP1HCL
	move.w	d1,(a0)+

	move.l	a1, $dff080

	move.l	#$01fc0000, (a0)+
	move.l	#$ffe1fffe, (a0)+
	move.l	#$fffffffe, (a0)+


SetupCopperColortable:
	; d5 loop control
	; d6 scratch
	; d7 color register
	move.w	#16-1, d5
	lea		CopperColortable, a4  ; the block of stuff

.nextBlock:
	move.w	#color, d7

	;d0 : upordown INPUT : 1 up, -1 down
	;d1 : desired color component
	;d2 : mask
	;d3 : colorphase
	; Calculate the current fade for all 15 intensities
	lea		SC2_SmoothColor+30, a0
	lea		SC2_CurrentColorComponent+30, a1
	moveq	#$f, d1			; f->0
	move.w  SC2_ColorPhase, d3 
.nextComponent
	move.w	(a0), d2
	subq.w  #2, a0
	btst    d3, d2
	beq.s   .skipChange
	move.w	(a1), d2
	add.w	#1,d2
	move.w	d2, (a1)
.skipChange:
	subq.w  #2, a1
	dbra	d1, .nextComponent
	
	addq.w	#1, d3
	move.w  d3, SC2_ColorPhase

	; d0 counter
	; a4 copper palette
	; a1 final RAW palette
	; d1 final color
	; d2 scratch
	; d3 current color


	lea     PaletteOne, a1
	lea		SC2_CurrentColorComponent, a2
	moveq   #32-1, d0
	
.nextColor


	; write the register in copper list
	move.w	d7, (a4)+
	addq.w  #2, d7
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
	move.w  d3, (a4)+
	dbra    d0, .nextColor

	move.w	#copjmp2, (a4)+		; MOVE garbage, COPJMP2
	move.w	d5, (a4)+

	dbra    d5, .nextBlock


SetupInitialGradient:
	;lea		SC2_Stars, a0
	;move.b	#$1, (20, a0)
	;move.w	#56-1, d0
.loop:
	;move.b 	d0, (a0)+
	;dbra	d0, .loop


SetupCopperAddresses:
	lea 	SC2_CopSubAddresses, a0
	move.l 	#CopperColortable, d0
	move.w	#16-1, d1
.loop:
	move.l	d0, (a0)+
	add.l	#132, d0    ; Size of each copper subroutine
	dbra	d1, .loop

	rts

Scene2Init:
	lea CopperScene2, a1
	move.l	a1, $dff080
	rts

; Frames to skip before changing colors
SC2_Skip: equ 4

SC2_ColorPhase:
	dc.w	$0
SC2_Phase:
    dc.l    0
SC2_Position:
	dc.w    $9

bandSize:			equ 1
SC2FadeInFrames:	equ 15
SC2FadeOutFrames:	equ 15
SC2HoldFrames:		equ 100


Scene2:

LoadPalette:


	lea		SC2_Gradient, a0
	lea		CopperColors2, a1		;	 This is where the waits and jumps are
	lea		CopperColortable, a2	; 	This is the color table
	lea		SC2_CopSubAddresses, a3
	move.w	#256-1, d0
	addq.l	#2, a1
.loop
	move.b	(a0)+, d1
	and.w	#$3c,d1
	; 00 - 3f is the color range
	;and.w	#$f,d1
	;lsl	#2, d1
	move.l	(a3,d1), d1
	move.w	d1, (a1)	
	swap	d1
	move.w	d1, 4(a1)
	add.l	#24, a1		; move to the next cop1l load
	dbra	d0, .loop

	; d1 - Next color (up)
	; d2 - Current color
UpdateGradient:
	lea 	SC2_Stars + 255,a0
	lea		SC2_Gradient + 255, a1
	move.w	#255, d0
	move.b  #0, d5
	move.w	#10, d2
.loop
	sub.b	d2,d5
	tst.b	d5
	bge		.skipZero
	move.b	#0, d5
.skipZero:

	move.b	(a0), d1	
	tst.b	d1	
	beq		.isZero
	move.b	#$3f, d5
	move.b	d1,d2
.isZero:
	move.b  d5, (a1)
	sub		#1, a0
	sub		#1, a1
	dbra	d0, .loop

	; d1 - Next color (up)
	; d2 - Current color
UpdateStars:
	lea 	SC2_Stars + 255,a0
	move.w	#255, d0
	move.b	(a0), d2
.loop
	move.b	(a0,-1), d1

	tst.b	d2
	bne		.skipDrop
	move.b	d1, d2
	move.b	#0, d1

.skipDrop:

	move.b	d2, (a0)
	move.b	d1, d2

	sub		#1, a0
	dbra	d0, .loop


AddStarTop:
	move.w	SC2_StarCounter, d0
	add.w	#1,d0
	lea		SC2_StarWaits, a0
	move.w	SC2_StarWait, d1
	add.w	d1,a0
	add.w	d1,a0
	cmp.w	(a0),d0
	ble		.finish
	move.w	(a0),d2
	move.b	d2, SC2_Stars+2
	add.w	#$1, d1
	and.w	#$7, d1
	move.w	d1, SC2_StarWait
	move.w	#0, d0
.finish:	
	move.w	d0, SC2_StarCounter
	rts

SC2_StarCounter: 
	dc.w 	0
SC2_StarWait:
	dc.w	0
SC2_StarWaits:
	dc.w	3
	dc.w	12
	dc.w	8
	dc.w	20
	dc.w	3
	dc.w	16
	dc.w	4
	dc.w	10


NextScene:

SC2_SmoothColor:
	dc.w    $0000
	dc.w    $0100
	dc.w    $1010
	dc.w    $2108
	dc.w    $4444
	dc.w    $4924
	dc.w    $5294
	dc.w    $5554
	dc.w    $aaaa
	dc.w    $ad6a
	dc.w    $b6da
	dc.w    $bbba
	dc.w    $def6
	dc.w    $efee
	dc.w    $fefe
	dc.w    $fffe

SC2_CopSubAddresses:
	ds.l	16

SC2_Gradient:
	dc.b	0 		; Above the line padding
	dc.b	0		; Above the line padding
	ds.b	256 	; 1 byte per row. This should not be here to save executable size.
	dc.b	0
	dc.b	0		; pad last

SC2_Stars:
	dc.b 	0
	dc.b 	0
	ds.b	256
	dc.b 	0
	dc.b 	0


SC2_CurrentColorComponent:
	ds.w    15

