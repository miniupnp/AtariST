;------------------------------------------------------------------------------
; fast ym dac interrupt by tIn/newline
;------------------------------------------------------------------------------
;-TOS compatible - saves all registers and doesn't require auto interrupt mode
;-31kHz tops on 8 MHz ST
;-uses timer vector to decode sample byte to ym registers, needs 128k for timercode+alignment
;-for streaming with doublebuffering: check buffer switch in main loop with move.l ppplaypointer,A0 / move.l (A0),A0 / btst #15,2(A0)

				TEXT
ym_tos_fast:	;init, deinit, timera
				DC.L 	.yminit, .ymdeinit
.ptimera:		DC.L 	0

.yminit:		movem.l D0-A6,-(SP)
				bsr 	.ymcreatetimercode
				movem.l (SP)+,D0-A6
				rts

.ymdeinit:		rts

;--------------------------------------
;create timer code 
;--------------------------------------
;build 256 timer routines with embedded ym dac values
;for 8 bit non-precomputed sample every timer needs
;to be aligned at 256 bytes - effective address for 
;a timer has to be $xxbb00 with $xx=free $bb=sample 
;byte to write to ym 
.ymcreatetimercode:
				lea	 	ymtimercode,A0
				move.l 	A0,D0
				clr.w 	D0
				move.l 	D0,A0
				move.l 	A0,.ptimera
				lea 	$8000-4(A0),A5 					;playpointer has to be in +-32k range, so we place it at codebuffer+$7ffc
				move.l 	A5,ppplaypointer
				addq.l 	#2,A5
				move.l 	A5,.patch_p2+2 					;patch adress to store the playpointer word for wrapping
				move.l 	ymplaypointer,-2(A5) 			;save replay pointer into middle of replay code

				lea 	ymvolumetable,A1
				lea 	.ymtimera,A2
				move.w 	#.ymtimeraend-.ymtimera-1,D0
				move.w 	#($8000-4)-(.patch_p1-.ymtimera)-2,D1

				move.w 	#256-1,D7
.l:	
				move.b 	1(A1),.patch_a+4
				move.b 	3(A1),.patch_b+4
				move.b 	5(A1),.patch_c+4
				lea 	8(A1),A1
				move.w 	D1,.patch_p1+2 					;PC relative address to play pointer
	
				move.w  D0,D6
				move.l 	A2,A3
				move.l 	A0,A4

.lc:			move.b 	(A3)+,(A4)+	
				dbra 	D6,.lc

				lea 	256(A0),A0 						;next timer code
				sub.w 	#256,D1
				dbra 	D7,.l
				rts

;--------------------------------------
;timer code template
;--------------------------------------
;could be faster with lowmem, but that
;would break TOS compatibility... 
.ymtimera:		move.l 	A0,-(SP) 			;12
				lea		$ffff8800.w,A0 		;08
.patch_a:		move.l	#$8000000,(A0) 		;20
.patch_b:		move.l	#$9000000,(A0) 		;20
.patch_c:		move.l	#$a000000,(A0) 		;20
.patch_p1:		move.l	0(PC),A0 			;16 playpointer is gurabteed to be in PC relative range
				move.b  (A0)+,$136.w 		;16 switch timer according to the next sample
.patch_p2:		move.w 	A0,0.l				;16
				IFEQ 	YM_USE_AUTOINTERRUPT
				bclr    #5,$FFFFFA0F.w      ;20 
				ENDC
				move.l (SP)+,A0 			;12
				rte 						;20
.ymtimeraend:
				;208
				;188 with auto interrupt

				BSS
;--------------------------------------
;timer code buffer
;--------------------------------------
ppplaypointer: 	DS.L 	1 		;pointer to the playpointer location
				DS.B 	65536 	;space for 64k-alignment
ymtimercode:	DS.B 	65536
