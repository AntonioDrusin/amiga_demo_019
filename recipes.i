**************************************************
; Load raw palette into copper palette
**************************************************

; Setup CopperList ColorPalette
; d0 colorregister + color
; d7 color counter
; a0 copperlist pointer,
; a1 raw palette pointer

; arg1 : raw palette
; arg1 : 

macro SET_COLOR_COPPERLIST	

	WinUAEBreakpoint
	clr.w	d1
	move.w	#color, d0			
	move    #32-1, d7
	lea		CopperColors, a0
	lea		PaletteOne, a1
.loadPal
	swap	d0	; reg:color
	move.w	(a1)+, d0
	move.l	d0, (a0)+
	swap	d0
	addq.w	#2, d0
	dbra	d7, .loadPal

