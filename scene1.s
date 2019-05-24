*****************
** S C E N E 1 **
*****************

S1BackColor:
	dc.w	$fff
S1ColorLoop:
	dc.w	$000
S1ColorDelta:
	dc.w	$010
	dc.w	$100
	dc.w	$001

Scene1PreCalc:
	rts

Scene1Init:
	rts

Scene1:
	; Set Background color
	lea		S1BackColor, a0
	move.w	(a0), d0
	move.w	d0, $dff180 

	; Fetch the subtractor from table
	lea		S1ColorDelta, a1
	move.w	S1ColorLoop, d1
	sub.w	(a1,d1), d0
	addq.w	#2, d1
	cmp.w	#$6, d1
	bne.s	.colorcont
	move.w	#$0, d1
.colorcont:
	move.w	d1, S1ColorLoop
	
	tst.w	d0
	beq.s	.nextScene
	move.w	d0, (a0)
	rts

.nextScene
