;              T         T               T

; Compact demo-startup by Blueberry/Loonies
; Version 1.3, August 22, 2013
; Public Domain

; Music players hooked up by Hannibal/Lemon.
LEAVETHESEDMACHANNELSALONE:	set	0
LEAVETHESEINTERRUPTSALONE:	set	$0000


	if MUSICPLAYER=4
		if MUSICPLAYERUSEVBLANK<>1
LEAVETHESEINTERRUPTSALONE:	set	$2000					; ciab
		endif
LEAVETHESEDMACHANNELSALONE:	set	$f
	endif
	if MUSICPLAYER=5
		if OCTAMEDPLAYERTYPE>0
LEAVETHESEINTERRUPTSALONE:	set	$0088					; ciaa, audio channel 3
MUSICPLAYERUSEVBLANK:		set	0
		else
			if		MUSICPLAYERUSEVBLANK=1
LEAVETHESEINTERRUPTSALONE:	set	$0	
			else
LEAVETHESEINTERRUPTSALONE:	set	$0008					; ciaa
			endif
		endif
LEAVETHESEDMACHANNELSALONE:	set	$f
	endif

SETUPCIAINTERRUPT:			set	0
	if MUSICPLAYERUSEVBLANK<>1
		if MUSICPLAYER=3||MUSICPLAYER=4
SETUPCIAINTERRUPT:			set	1

_CIAB:						equ	$bfd000
ciatblo:					equ	$0600
ciatbhi:					equ	$0700
ciacrb:						equ	$0F00
ciaicr:						equ	$0D00

CIAICRF_SETCLR:				equ	(1<<7)
CIAICRF_TB:					equ	(1<<1)

CIACRBF_START:				equ	(1<<0)
CIACRBF_LOAD:				equ	(1<<4)
CIACRBF_INMODE:				equ	(1<<5)
CIACRBF_PBON:				equ	(1<<1)
CIACRBF_RUNMODE:			equ	(1<<3)
		endc
	endc

	if MUSICPLAYER=0||MUSICPLAYER=2
MUSICPLAYERUSEVBLANK:		set	0
	endc
	if MUSICPLAYER=1 && MUSICPLAYERUSEVBLANK=2
MUSICPLAYERUSEVBLANK:		set	1
	endc

WinUAEBreakpoint:macro
														;to stop here in WinUAE, enter "w 4 4 4 w" in the debugger window (shift+f12) to place the breakpoint, and enter "w 4" to remove it
		move.l	4.w,4.w
	endm


;; ********** System constants **********

; Exec
SU_Supervisor=					-30
SU_OldOpenLibrary=				-408
SU_CacheClearU=					-636
SU_TaggedOpenLibrary=			-810
; Graphics
SU_OpenFont=					-72
SU_LoadView=					-222
SU_WaitTOF=						-270

SU_lib_Version=					$14
SU_eb_AttnFlags=				$128
SU_gb_ActiView=					$22
SU_gb_copinit=					$26
SU_tf_CharData=					$22
IVBLIT=							156


; Cache flush macro
; Potentially trashes D0-D1/A0-A1/A6

	if	COMPATIBILITY=0
CACHEFLUSH:macro
		endm
	endc

	if	COMPATIBILITY=1
CACHEFLUSH:macro
			move.l	$4.w,a6
			cmp.w	#37,SU_lib_Version(a6)
			blo.b	.noflush\@
			jsr		SU_CacheClearU(a6)
.noflush\@:	
		endm
	endc

	if	COMPATIBILITY=2
CACHEFLUSH:macro
			move.l	$4.w,a6
			jsr		SU_CacheClearU(a6)
		endm
	endc

DMA_OFF=						$01ff-(LEAVETHESEDMACHANNELSALONE)
DMA_ON=							$8000+(BITPLANE<<8)+(COPPER<<7)+(BLITTER<<6)+(SPRITE<<5)


; Entry point

	if	FASTMEM
		section	code,code_f
	else
		section	code,code
	endc

Startup:

	if	SECTIONHACK
														; Read section pointers from hunk structure
		move.l	Startup-4(pc),d0
		lsl.l	#2,d0
		addq.l	#4,d0
		lea.l	ChipPtr(pc),a1
		move.l	d0,(a1)
	else
		move.l	#Chip,ChipPtr
	endc

														; Call precalc code
	bsr.w	_Precalc

	if MUSICPLAYER=4									;note: AHX player is called before system is shut down because it is more system friendly
		if MUSICPLAYERUSEVBLANK<>1
			lea		ahxSetTempo,a0
			moveq	#1,d0
			jsr		ahxReplayer+ahxInitCIA
			tst.w	d0
			bne		ahxInitFailedInitCIA
		endif

		sub.l	a0,a0									;auto-allocate public (fast)
		sub.l	a1,a1									;auto-allocate chip
		moveq	#1,d0									;dont load waves from hd
		moveq	#0,d1
		jsr		ahxReplayer+ahxInitPlayer
		tst.w	d0
		bne		ahxInitFailedInitPlayer

		lea		AHXModule,a0							;module
		jsr		ahxReplayer+ahxInitModule

		tst.w	d0
		bne		ahxInitFailedInitModule
	endif
	if MUSICPLAYER=5									;note: proplayer is called before system is shut down because it is more system friendly
		move.l	#OSSModule,a0
		bsr		_RelocModule
		move.l	#OSSModule,a0
		bsr		_RequiredPlayRoutine
		cmp.w	#OCTAMEDPLAYERTYPE,d0
		bne		ossInitFailed
		bsr		_InitPlayer
		tst.w	d0
		bne		ossInitFailed
	endif

														; Retrieve Vector Base Register
	move.l	$4.w,a6
	if	COMPATIBILITY=1
		suba.l	a2,a2
		btst.b	#0,SU_eb_AttnFlags+1(a6)
		beq.b	.no010
	endc
	if	COMPATIBILITY>=1
		lea.l	GetVBR(pc),a5
		jsr		SU_Supervisor(a6)
.no010:endc

														; Get graphics.library
	move.l	156(a6),a6

														; Open topaz
	if	TOPAZ
		lea.l	TextAttr(pc),a0
		lea.l	TopazName(pc),a4
		move.l	a4,(a0)
		jsr		SU_OpenFont(a6)
		move.l	d0,a0
		move.l	SU_tf_CharData(a0),TopazCharData-TopazName(a4)
	endc

														; Clear display
	if	COMPATIBILITY>=1
		move.l	SU_gb_ActiView(a6),d7
		suba.l	a1,a1
		jsr		SU_LoadView(a6)
		lea.l	$dff000,a3
		move.w	#$0020,$1dc(a3)							; Ensure PAL
		jsr		SU_WaitTOF(a6)
		jsr		SU_WaitTOF(a6)
	else
		jsr		SU_WaitTOF(a6)
		lea.l	$dff000,a3
	endc

	move.w	#$3fdf&~LEAVETHESEINTERRUPTSALONE,$09a(a3)	;leave vblank running
	move.w	#DMA_OFF,$096(a3)

														;make sure we don't have any ugly flashes on startup: clear colors and set 0 bitplanes
	move.w	#$0200,$100(a3)
	move.w	#$180,d0
.clearColors:
	clr.w	0(a3,d0.w)
	addq.w	#2,d0
	cmp.w	#$1c0,d0
	bne		.clearColors

	if MUSICPLAYER>0
		movem.l	d7/a2/a3/a6,-(a7)
		if MUSICPLAYER=1
			lea		P61Module(pc),a0
			lea		P61Samples,a1
			sub.l	a2,a2
			moveq	#0,d0
			bsr		P61_Init
		endc
		if MUSICPLAYER=2
			lea		FCModule,a0
			bsr		INIT_MUSIC
		endc

		if MUSICPLAYER=3
			lea.l	OldAudioInterrupt(pc),a4
			if	COMPATIBILITY>=1
				move.l	$70(a2),(a4)+
				move.l	a4,$70(a2)						;audioInterruptHandler
			else
				move.l	$70.w,(a4)+
				move.l	a4,$70.w						;audioInterruptHandler
			endc


			move.l	#TFMXmdat,d0
			move.l	#TFMXsmpl,d1
			move.l	#TFMXChipBuffer,d2
			move.w	#TFMXKhzPlaybackRate,d3
			bsr		INITDATA
		endc

		if SETUPCIAINTERRUPT=1
			lea.l	OldCIABSettings(pc),a4
			move.b	_CIAB+ciatblo,(a4)
			move.b	_CIAB+ciatbhi,1(a4)
			move.b	_CIAB+ciacrb,2(a4)

			lea.l	OldCIABInterrupt(pc),a4
			if	COMPATIBILITY>=1
				move.l	$78(a2),(a4)+
				move.l	a4,$78(a2)						;CIABInterruptHandler
			else
				move.l	$78.w,(a4)+
				move.l	a4,$78.w						;CIABInterruptHandler
			endc
			move.b	#(~(CIAICRF_SETCLR))&$ff,_CIAB+ciaicr
			move.b	#0,_CIAB+ciacrb 
			tst.b	_CIAB+ciaicr

			move.w	#$a000,$dff09a
			if MUSICPLAYER=3
				move.l	#_CIAB+ciatblo,VectorDataBlock+vdb_CIATimer
			endc
		endc

		if MUSICPLAYER=3
			move.w	#TFMXSubSong,d0						;song number
			bsr		SONGPLAY
		endc

		if MUSICPLAYER=4
			if MUSICPLAYERUSEVBLANK<>1

				move.b	#1,ahxIsStarted
				move.w	ahxCurrentTempo,d0
				bsr		ahxSetTempo
			endif
.InitSubSong:
			moveq	#ahxSubSong,d0
			moveq	#0,d1								;Play immediately
			jsr		ahxReplayer+ahxInitSubSong
		endif
		if SETUPCIAINTERRUPT=1
			move.b	#(CIACRBF_START),_CIAB+ciacrb 
			move.b	#CIAICRF_SETCLR|CIAICRF_TB,_CIAB+ciaicr
		endif

		if MUSICPLAYER=5
			move.l	#OSSModule,a0
			bsr		_PlayModule
		endc
		movem.l	(a7)+,d7/a2/a3/a6
	endif
														; Init interrupt
	lea.l	InterruptHandler(pc),a4
	if	COMPATIBILITY>=1
		move.l	$6c(a2),a5
		move.l	a4,$6c(a2)
		movem.l	d7/a2/a3/a5/a6,-(a7)
	else
		move.l	$6c.w,a5
		move.l	a4,$6c.w
		movem.l	a3/a5/a6,-(a7)
	endc
	move.l	a7,-(a4)									; StackStore
	move.w	#DMA_ON,$096(a3)

	bsr.w	_Main

StartupEnd:
	move.l	StackStore(pc),a7
														; Restore interrupt
	if	COMPATIBILITY>=1
		movem.l	(a7)+,a1/a2/a3/a4/a6
		move.l	a4,$6c(a2)
	else
		movem.l	(a7)+,a3/a4/a6
		move.l	a4,$6c.w
	endc

	if MUSICPLAYER>0
		movem.l	a1/a3/a6,-(a7)		
		if MUSICPLAYER=1
			bsr		P61_End
		endc
		if MUSICPLAYER=2
			bsr		END_MUSIC
		endc

		if MUSICPLAYER=3
			if	COMPATIBILITY>=1
				move.l	OldAudioInterrupt(pc),$70(a2)
			else
				move.l	OldAudioInterrupt(pc),$70.w
			endc
			bsr		ALLOFF
			moveq	#8-1,d0
.allchannelsoff:
			move.l	d0,-(a7)
			bsr		CHANNELOFF
			move.l	(a7)+,d0
			dbra	d0,.allchannelsoff
		endc

		if MUSICPLAYER=4
			jsr		ahxReplayer+ahxStopSong
		endif
		if SETUPCIAINTERRUPT=1
			move.b	#(~(CIAICRF_SETCLR))&$ff,_CIAB+ciaicr
			tst.b	_CIAB+ciaicr
			move.w	#$2000,$dff09c
			if	COMPATIBILITY>=1
				move.l	OldCIABInterrupt(pc),$78(a2)
			else
				move.l	OldCIABInterrupt(pc),$78.w
			endc
			lea		OldCIABSettings(pc),a2
			move.b	(a2),_CIAB+ciatblo
			move.b	1(a2),_CIAB+ciatbhi
			or.b	#CIACRBF_LOAD,2(a2)
			move.b	2(a2),_CIAB+ciacrb
		endif
		if MUSICPLAYER=5
			bsr		_StopPlayer
		endif
		movem.l	(a7)+,a1/a3/a6		
	endif
														; Restore display
	move.w	#$a00c,$09a(a3)
	move.w	#$001f,$096(a3)
	move.w	#$81e0,$096(a3)
	if	COPPER
		move.l	SU_gb_copinit(a6),$080(a3)
	endc
	if	COMPATIBILITY>=1
		jsr		SU_LoadView(a6)
	endc

; In principle, we should close graphics.library and topaz.font here,
; but since they are always in use, it makes no difference whatsoever,
; so we don't bother.

	if	MUSICPLAYER=4
ahxInitFailedInitModule:
		jsr		ahxReplayer+ahxKillPlayer				;don't forget!
ahxInitFailedInitPlayer:
		if MUSICPLAYERUSEVBLANK<>1
			jsr		ahxReplayer+ahxKillCIA				;don't forget!
ahxInitFailedInitCIA:
		endif
	endif
	if MUSICPLAYER=5
		bsr		_RemPlayer
ossInitFailed:
	endif
	bra.w	_Exit

	if	COMPATIBILITY>=1
GetVBR:	
		if	COMPATIBILITY<2		
			mc68020			
		endif				
		movec	vbr,a2
		if	COMPATIBILITY<2		
			mc68000				
		endif					
		rte
	endc

	if	TOPAZ
TextAttr:
		dc.l	0
		dc.w	8
		dc.b	0,0
TopazCharData:
		dc.l	0
TopazName:
		dc.b	'topaz.font',0
	endc

	even

VBlank:
	dc.l	0
ChipPtr:
	dc.l	0
StackStore:
	dc.l	0
InterruptHandler:
	movem.l	d0-a6,-(a7)
	if	FPUINT
		fsave	-(a7)
		fmovem.x	fp0-fp7,-(a7)
	endc

	lea.l	VBlank(pc),a0
	addq.l	#1,(a0)

	bsr.w	_Interrupt
	if	SHOWMUSICRASTERLINES=1
.waitforscreen:
		cmp.b	#$2c,$dff006
		blt		.waitforscreen
		move.w	#$f00,$dff180
	endc

	if SETUPCIAINTERRUPT=1
		if MUSICPLAYERUSEVBLANK=2
			tst.b	ciaTimerHits
			beq		.noPlay
.loop:		
		endc
	endc
	if MUSICPLAYER=1
		if MUSICPLAYERUSEVBLANK<>0
			lea		$dff000,a6
			bsr		P61_Music
		endc
	endc
	if MUSICPLAYER=2
		bsr		PLAY_MUSIC
	endc

	if MUSICPLAYER=3
		if MUSICPLAYERUSEVBLANK<>0
			bsr		CIAInt
		endc
	endc

	if MUSICPLAYER=4
		if MUSICPLAYERUSEVBLANK<>0
			jsr		ahxReplayer+ahxInterrupt
		endc
	endif
	if MUSICPLAYER=5
		if MUSICPLAYERUSEVBLANK<>0
			bsr		_IntHandler
		endif
	endif

	if SETUPCIAINTERRUPT=1
		if MUSICPLAYERUSEVBLANK=2
			subq.b	#1,ciaTimerHits
			bne		.loop
.noPlay:	
		endc
	endc
	if	SHOWMUSICRASTERLINES=1
		move.w	#$0,$dff180
	endc

	lea.l	$dff000,a3

	if	RMBPAUSE
														; RMB pause
.rmb:	
		btst	#10,$016(a3)
		bne.b	.normb
		move.w	#$0020,$09c(a3)
		move.w	#$0020,$09c(a3)

		btst.b	#6,$bfe001
		bne.b	.rmbloop2
.rmbloop:
		moveq.l	#$0020,d0
		and.w	$dff01e,d0
		beq.b	.rmbloop
		bsr.w	_Interrupt
		lea.l	$dff000,a3
		bra.b	.rmb
.rmbloop2:
		moveq.l	#$0020,d0
		and.w	$dff01e,d0
		beq.b	.rmbloop2
		bsr.w	_Interrupt
		lea.l	$dff000,a3
		btst.b	#6,$bfe001
		bne.b	.rmb
		move.w	#$0020,$09c(a3)
		move.w	#$0020,$09c(a3)
		if	FPUINT
			fmovem.x	(a7)+,fp0-fp7
			frestore	(a7)+
		endc
		movem.l	(a7)+,d0-a6
		rte
.normb:	
	endc

	move.w	#$0020,$09c(a3)
	if	COMPATIBILITY>=1
		move.w	#$0020,$09c(a3)
	endc

	if	FPUINT
		fmovem.x	(a7)+,fp0-fp7
		frestore	(a7)+
	endc
	movem.l	(a7)+,d0-a6

	btst.b	#6,$bfe001
	bne.b	.end
	lea.l	StartupEnd(pc),a1
	move.l	a1,2(a7)
.end:
	rte



	if MUSICPLAYER=1


split4=							0
splitchans=						1
visuctrs=						0
asmonereport=					0
p61system=						0
p61exec=						1
p61fade=						0
channels=						4
playflag=						0
p61bigjtab=						0
opt020=							0
p61jump=						0
C=								0
clraudxdat=						0
optjmp=							1
oscillo=						0
quietstart=						0
use1Fx=							0

p61cia=							1-MUSICPLAYERUSEVBLANK
lev6=							1
noshorts=						0
dupedec=						0
suppF01=						1
	endc

	if MUSICPLAYER=2
		include "FC1.4replay.s"
	endc

	if MUSICPLAYER=3
OldAudioInterrupt:
		dc.l	0
AudioInterruptHandler:
		movem.l	d0-a6,-(a7)	
		lea		$dff000,a0
		move.w	$1e(a0),d1
		and.w	$1c(a0),d1

		btst	#10,d1
		beq		.notVoice3
		lea		Voice3Data(pc),a1
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0f0,$dff180
		endc
		bsr		VoiceInt3
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0,$dff180
		endc
		bra		.end
.notVoice3:
		btst	#9,d1
		beq		.notVoice2
		lea		Voice2Data(pc),a1
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0f0,$dff180
		endc
		bsr		VoiceInt
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0,$dff180
		endc
		bra		.end
.notVoice2:
		btst	#8,d1
		beq		.notVoice1
		lea		Voice1Data(pc),a1
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0f0,$dff180
		endc
		bsr		VoiceInt
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0,$dff180
		endc
		bra		.end
.notVoice1:
		btst	#7,d1
		beq		.notVoice0
		lea		Voice0Data(pc),a1
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0f0,$dff180
		endc
		bsr		VoiceInt
		if	SHOWMUSICRASTERLINES=1
			move.w	#$0,$dff180
		endc
.notVoice0:
.end:	
		movem.l	(a7)+,d0-a6
		rte
	endif
	
	if SETUPCIAINTERRUPT=1
OldCIABInterrupt:
		dc.l	0
CIABInterruptHandler:
		tst.b	_CIAB+ciaicr
		move.w	#$2000,$dff09c
		move.w	#$2000,$dff09c

		if MUSICPLAYERUSEVBLANK=2
			add.b	#1,ciaTimerHits
		else
			if	SHOWMUSICRASTERLINES=1
				move.w	#$0f0,$dff180
			endc
			if MUSICPLAYER=3
				bsr		CIAInt
			endc

			if MUSICPLAYER=4
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		ahxReplayer+ahxInterrupt
				movem.l	(a7)+,d0-d7/a0-a6
			endif
			if	SHOWMUSICRASTERLINES=1
				move.w	#$0,$dff180
			endc
		endif
		rte
OldCIABSettings:
		ds.b	3
		if MUSICPLAYERUSEVBLANK=2
ciaTimerHits:
			dc.b	0
		endc
		even
	endc

	if MUSICPLAYER=4
		if MUSICPLAYERUSEVBLANK<>1
ahxSetTempo:
			move.w	d0,ahxCurrentTempo
			tst.b	ahxIsStarted
			beq		.notStarted

			move.b	d0,_CIAB+ciatblo
			lsr.w	#8,d0
			move.b	d0,_CIAB+ciatbhi
			or.b	#CIACRBF_START,_CIAB+ciacrb
.notStarted:
			rts
ahxCurrentTempo:
			dc.w	0
ahxIsStarted:
			dc.b	0
			even
		endif

		include	"..\dh0\AHX\Examples\AHX-Offsets.I"
ahxReplayer:
		incbin	"..\dh0\AHX\Players\AHX-Replayer000.BIN"

	endif
	if MUSICPLAYER=5
		incdir "..\dh0\OctaMED_Soundstudio\Programmers\"

AUDDEV:						equ	0						;1 = allocate channels using audio.device
SYNTH:						equ	1						;1 = include synth-sound handler
CHECK:						equ	0						;1 = do range checkings (track, sample in mem etc.)
RELVOL:						equ	1						;1 = include relative volume handling code
IFFMOCT:					equ	1						;1 = play IFF multi-octave samples/ExtSamples correctly
HOLD:						equ	1						;1 = handle hold/decay
PLAYMMD0:					equ	1						;1 = play old MMD0 modules
FASTMEMPLAY:				equ	1						;1 = make FastMemPlay available

;	Function: _RequiredPlayRoutine(a0)
;	a0 = pointer to module
;	Returns:
;		0 = 4 channel routine (or no module)
;		1 = 5-8 channel routine
;		2 = mixing routine

_RequiredPlayRoutine:
		move.l	a0,d0
		beq.s	3$
		move.l	8(a0),a0								;song struct
		tst.b	msng_flags2(a0)							;mixing?
		bmi.s	2$
		btst	#6,msng_flags(a0)						;5-8 channel?
		bne.s	1$
3$		moveq	#0,d0
		rts
1$		moveq	#1,d0
		rts
2$		moveq	#2,d0
		rts

		if OCTAMEDPLAYERTYPE=0
VBLANK:						equ	0						;1 = use VBlank interrupt (when absolutely necessary)
			if MUSICPLAYERUSEVBLANK=0
CIAB:						equ	1						;1 = use CIA timers (default)
			else
CIAB:						equ	0
			endif
			include "..\dh0\OctaMED_Soundstudio\Programmers\proplayer.a"
		else
			if COMPATIBILITY>1
OCTAMEDPLAYERHQ:			equ	1						;68010+ can use HQ
			else
OCTAMEDPLAYERHQ:			equ	0						;68000 is not fast enough for HQ.
			endif
_RemPlayer:					equ	_RemPlayer8
_StopPlayer:				equ	_StopPlayer8
_PlayModule:				equ	_PlayModule8
_InitPlayer:				equ	_InitPlayer8
			include "..\dh0\OctaMED_Soundstudio\Programmers\pro8player.a"
		endif
		if	FASTMEM
			section	code,code_f
		else
			section	code,code
		endc
		include "..\dh0\OctaMED_Soundstudio\Programmers\reloc.a"

	endif
	even

	if	FASTMEM
		section	code,code_f
	else
		section	code,code
	endc
	if	COMPATIBILITY<2		
		mc68000				
	endif					
;Shallow Hash=3618711821622516252114551826816810672108
