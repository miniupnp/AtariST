; (c) 2016 Thomas Bernard
;
; routing to print a decimal number
;

	code

; d0.w = number to print
; trashes a0
printwdec
	lea .printbufferend(pc),a0
	clr.b	(a0)
.loop
	divu.w #10,d0
	move.w d0,-(sp)	;push quotient
	swap d0	; low word = reminder
	addi.w #48,d0 ; '0'
	move.b d0,-(a0)
	moveq.l     #0,d0 ;sub.l d0,d0	; zero d0
	move.w (sp)+,d0	; pop quotient
	bne .loop
	move.l	a0,-(sp)
	move.w	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts

	bss
.printbuffer
	ds.b	8
.printbufferend
	ds.b	1

