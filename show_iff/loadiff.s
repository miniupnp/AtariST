;
; http://www.atari-wiki.com/?title=ST_Picture_Formats
; http://wiki.amigaos.net/wiki/ILBM_IFF_Interleaved_Bitmap
; http://www.textfiles.com/programming/AMIGA/iff.txt

; BMHD : 20 bytes
; offset  0   UWORD width     (320)
; offset  2   UWORD height    (200)
; offset  4   WORD x position (0)
; offset  6   WORD y position (0)
; offset  8   BYTE number of bitplanes (4)
; offset  9   BYTE masking mode (0=none, 1=mask, 2=transp color, 3=Lasso)
; offset 10   BYTE compression (0=none, 1=packbits, 2=vertical RLE)
; offset 11   BYTE reserved
; offset 12   WORD transparent color (for masking mode 2)
; offset 14   BYTE x-aspect
; offset 15   BYTE y-aspect
; offset 16   UWORD page width  (320)
; offset 18   UWORD page height (200)
	code

	; d0 = byte count
	; a0 = input data
	; a1 = picture output
	; a2 = palette output
	; trashes d1-d6
loadiff
.readchunk
	sub.w	#8,d0
	bge	.ok
	; not enough data to read
	rts
.ok
	movem.l	(a0)+,d1-d2	; chunk name + chunk length
	cmp.l	#'ILBM',d1
	bne.s	.notilbm
	; ILBM : next chunk following
	subq.l	#4,a0
	addq.w	#4,d0
	bra		.readchunk
.notilbm
	cmp.l	#'CMAP',d1
	bne.s	.notcmap
	; palette
	sub.w	d2,d0
	; convert in ST(e) format
.paloop
	move.b	(a0)+,d3	; R
	lsl.w	#3,d3
	move.w	d3,d4
	and.w	#$0700,d3
	and.w	#$0080,d4
	lsl.w	#4,d4
	or.w	d3,d4
	move.b	(a0)+,d3	; G
	move.w	d3,d5
	lsr.b	#1,d3
	and.b	#$70,d3
	or.b	d3,d4
	lsl.b	#3,d5
	and.b	#$80,d5
	or.b	d5,d4
	move.b	(a0)+,d3	; B
	lsr.b	#1,d3
	move.b	d3,d5
	and.b	#$08,d3
	or.b	d3,d4
	lsr.b	#4,d5
	or.b	d5,d4
	move.w	d4,(a2)+
	subq.w	#3,d2
	bgt.s	.paloop
	bra.s	.readchunk
.notcmap
	cmp.l	#'BODY',d1
	bne.s	.notbody
	movem.l	d2/a0,-(sp)
	; unpack packbits
	lea	.scanline(pc),a3
	moveq.l	#0,d5
.bodyloop
	cmp.w	#160,d5
	bne.s	.noscanlinecopy
	lea	.scanline(pc),a3
	move.w	#3,d6
.lp2
	move.w	#19,d3
.lp1
	move.w	(a3)+,(a1)
	addq.l	#8,a1
	dbra	d3,.lp1
	sub.l	#160-2,a1
	dbra	d6,.lp2
	add.l	#160-8,a1
	lea	.scanline(pc),a3
	moveq.l	#0,d5
.noscanlinecopy
	cmp.w	#1,d2
	bgt	.contbody
	movem.l	(sp)+,d2/a0
	bra.s	.endswitch
.contbody
	move.b	(a0)+,d3	; read byte n
	subq.w	#1,d2
	ext.w	d3
	bmi.s	.negative
	; n >= 0 : copy n+1 bytes
	sub.w	d3,d2
	add.w	d3,d5
.copyloop
	move.b	(a0)+,(a3)+
	dbra	d3,.copyloop
	subq.w	#1,d2
	addq.w	#1,d5
	bra.s	.bodyloop
.negative
	cmp.w	#-128,d3	; nop
	beq.s	.bodyloop
	; -127 <= n <= -1 : repeat next byte (-n + 1) times
	move.b	(a0)+,d4
	subq.w	#1,d2
	neg.w	d3
	add.w	d3,d5
.rleloop
	move.b	d4,(a3)+
	dbra	d3,.rleloop
	addq.w	#1,d5
	bra.s	.bodyloop
.notbody
	cmp.l	#'FORM',d1
	bne.s	.notform
	movem.l	d0-d2/a0,-(sp)
	bsr		.readchunk
	movem.l	(sp)+,d0-d2/a0
.notform
.endswitch
	; default => ignore
	add.l	d2,a0
	sub.w	d2,d0
	bra		.readchunk

	bss
	align 2
.scanline
	ds.w	80
.scanlineend
