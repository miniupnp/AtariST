; (c) 2016 Thomas Bernard
; https://github.com/miniupnp/AtariST

	xdef	_c2p_line
	; prototype :
	; void c2p_line(UWORD * planar, UBYTE * chunky, int count)
	; count is the number of 16 pixels chunk to decode

	code
_c2p_line
	movem.w	d2-d5,-(sp)	; push 4*2 = 8 bytes on stack
	move.l	12(sp),a1	; 8+4(SP) = 12 : 1st arg
	move.l	16(sp),a0
	ifd LONGINTABI
	move.l	20(sp),d5
	else
	move.w	20(sp),d5
	endif
	subq.w	#1,d5
	bmi	.end
.loop
	rept	16
	move.b	(a0)+,d4
	lsr.w	#1,d4
	addx.w	d0,d0
	lsr.w	#1,d4
	addx.w	d1,d1
	lsr.w	#1,d4
	addx.w	d2,d2
	lsr.w	#1,d4
	addx.w	d3,d3
	endr
	move.w	d0,(a1)+
	move.w	d1,(a1)+
	move.w	d2,(a1)+
	move.w	d3,(a1)+
	dbra	d5,.loop
.end
	movem.w	(sp)+,d2-d5
	rts
