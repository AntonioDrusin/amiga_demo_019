*****************
** S C E N E 2 **
*****************

; Copper horizontal light ray


; First run should be all black not low luma 2
; Second run is all FFFF

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

	; d4 wait position
	; d5 loop control
	; d6 scratch
	; d7 color register
	move.w	#16-1, d5
	lea		CopperColors2, a4  ; the block of stuff
	move.w	#$6a, d4			

.nextBlock:
	move.w	#color, d7
			; Setup Copper wait ; dc.w	$2b01, $ff00
	move.w	d4, d6
	lsl.w	#8, d6
	or.w	#1, d6	   ; wait
	move.w  d6, (a4)+
	move.w  #$ff00, d6 ; waitmask
	move.w  d6, (a4)+
	add.w	#bandSize, d4

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

	dbra    d5, .nextBlock

	; Now do the reverse in the next 15 blocks 
	; the vertical location register is still in  d4
	add.w   #14*bandSize, d4
	; a4 Copperlist Location of blocks to copy 
	; d0 block counter
	lea 	CopperColors2, a4	
	; 31 color sets, 4 per instruction, 32 colors, 1 wait instruction	
	move.l 	#CopperColors2+(31-1)*4*(32+1), a2 ; Destination copper-list location
	move.w   #15-1, d0 ; 
.nextCopy:
	move.l  a2, a3
	addq.w  #4, a4   ; Skip wait instruction from source

	; Sets wait instruction to the next scanline in dest
	move.w	d4, d6
	lsl.w	#8, d6
	or.w	#1, d6	   ; wait
	move.w  d6, (a3)+
	move.w  #$ff00, d6 ; waitmask
	move.w  d6, (a3)+
	sub.w	#bandSize, d4

	move.w  #32-1, d1  ; Color counter.
.nextCopyColor:	
	move.l  (a4)+, (a3)+
	dbra	d1, .nextCopyColor


	sub.l   #4*(32+1), a2 ; Move back one on destination pointer
	dbra	d0, .nextCopy

	lea		CopperColors2, a0
	rts

Scene2Init:
	lea CopperScene2, a1
	move.l	a1, $dff080
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

bandSize:			equ 1
SC2FadeInFrames:	equ 15
SC2FadeOutFrames:	equ 15
SC2HoldFrames:		equ 100


Scene2:
	rts

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

SC2_CurrentColorComponent:
	ds.w    15