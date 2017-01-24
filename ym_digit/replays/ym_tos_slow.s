;------------------------------------------------------------------------------
; simple and slow ym dac interrupt by tIn/newline
;------------------------------------------------------------------------------
;-TOS compatible - saves all registers and doesn't require auto interrupt mode
;-only 26kHz tops on 8 MHz ST
;-nothing special except: use 65k aligned sample buffer and wrap by saving only a word pointer
;-for streaming with doublebuffering: check buffer switch in main loop with btst #15,ymplaypointer+2

				TEXT
				;init, deinit, timer
ym_tos_slow:	DC.L 	.yminit, .ymdeinit, .ymtimera

.yminit:		rts
.ymdeinit:		rts

.ymtimera:		movem.l	D0/A0-A1,-(SP) 				;32
				lea		ymplaypointer(PC),A0 		;08 ymcolumetab has to be at ymplaypointer+4
				move.l	(A0)+,A1 					;12 get current play pointer
				moveq 	#0,D0 						;04
				move.b	(A1)+,D0    				;08 current sample
				move.w	A1,-2(A0) 					;12 store play pointer and wrap
				lsl.w	#3,D0 						;12
				add.l	D0,A0 						;08 get YM volume registers
				lea		$fffffa0f.w,A1 			;08 
				move.l	(A0)+,D0 					;12
				movep.l	D0,($8800-$fa0f)(A1) 		;24
				move.w	(A0)+,D0 					;08
				movep.w	D0,($8800-$fa0f)(A1) 		;16
				IFEQ 	YM_USE_AUTOINTERRUPT
				bclr    #5,(A1)       				;16 Interrupt In-service A - Timer A done
				ENDC
				movem.l	(SP)+,D0/A0-A1 				;36
				rte 								;20
				;236 + IRQ
				;216 + IEQ (w autointerrupt)
