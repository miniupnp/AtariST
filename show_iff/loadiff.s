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
	; trashes d1-d6 / a3-a4
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
	bne		.notbody
	cmp.b	#1,10(a4)	; compression mode
	beq.s	.packbits
	; vertical RLE packing. BODY Contains VDAT chunks (1 per bitplane)
	movem.l	d0-d2/a0,-(sp)
	move.l	d2,d0
	bsr		.readchunk
	movem.l	(sp)+,d0-d2/a0
	bra		.endswitch
.packbits
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
	bra		.endswitch
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

	cmp.l	#'VDAT',d1
	bne.s	.notvdat
	movem.l	a0-a1,-(sp)
	move.w	2(a4),d1	; image height
	move.w	(a0)+,d3	; cmd count (+2)
	lea	-2(a0,d3.w),a2	; data address
	lea	-2(a0,d2.w),a5	; end address
	subq.w	#3,d3
.vdatloop
	cmp.l	a2,a5
	beq.s	.breakvdatloop
	move.b	(a0)+,d4	; read command
	ext.w	d4
	bmi.s	.vdatcpy
	bne.s	.vdatnonzero
	move.w	(a2)+,d4	; cmd=0 : load count from data
	bra.s	.vdatcpy2
.vdatnonzero
;	cmp.w	#1,d4
;	bne.s	.vdatnotone
;	addq.l	#1,a1	; crash
;	move.w	d4,(a1)
;	nop
;.vdatnotone
	move.w	(a2)+,d5	; cmd >1 : count = cmd, RLE
	subq.w	#1,d4
.vdatrleloop
	move.w	d5,(a1)
	bsr.s	.adjustdest
	dbra	d4,.vdatrleloop
	dbra	d3,.vdatloop
	movem.l	(sp)+,a0-a1
	addq.l	#2,a1
	bra		.endswitch
.vdatcpy
	neg.w	d4	; cmd < 0 : count = -cmd, COPY
.vdatcpy2
	subq.w	#1,d4
.vdatcpyloop
	move.w	(a2)+,(a1)
	bsr.s	.adjustdest
	dbra	d4,.vdatcpyloop
	dbra	d3,.vdatloop
.breakvdatloop
	movem.l	(sp)+,a0-a1
	addq.l	#2,a1
	bra		.endswitch
.adjustdest
	add.l	#160,a1
	subq.w	#1,d1
	bne.s	.noadjust0
	move.w	2(a4),d1	; image height
	mulu.w	#160,d1
	sub.l	d1,a1
	move.w	2(a4),d1	; image height
	addq.l	#8,a1
.noadjust0
	rts
.notvdat

	cmp.l	#'BMHD',d1
	bne.s	.notbmhd
	move.l	a0,a4
	bra.s	.endswitch
.notbmhd

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
