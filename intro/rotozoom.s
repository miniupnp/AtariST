; (c) 2016 Thomas BERNARD
; https://github.com/miniupnp/AtariST
;
; X = zoom * (x*cos(a) - y*sin(a))
; Y = zoom * (x*sin(a) + y*cos(a))

debug	equ 0
rotowidth	equ	64
rotoheight	equ	48

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

	code

	dc.w $a000 ; Line-A init
	dc.w $a00a ; Line-A hide mouse

	clr.l	-(sp)	; Switch cursor off (hide it)  +4
	move.w    #21,-(sp)    ; Cursconf	+6
	trap      #14          ; XBIOS

	move.w	#4,(sp)	; Getrez
	trap	#14			; XBIOS
	move.w	d0,rezbackup

	move.w    #2,(sp)     ; Physbase
	trap      #14          ; XBIOS
	move.l	d0,physbase

	move.w    #3,(sp)     ; Logbase
	trap      #14          ; XBIOS
	move.l	d0,logbase

	clr.w    (sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)	; +10
	move.l    logbase,-(sp)	; +14
	move.w    #5,-(sp)     ; SetScreen	;+16
	trap      #14          ; XBIOS

	lea       16(sp),sp	; correct stack


	; convert TGA palette to STf
	lea tga+18(pc),a0
	lea	palette(pc),a1
	move.l	a1,-(sp)	; PUSH palette
	moveq.l #0,d1
	move.b tga+5(pc),d2
	subq.w	#1,d2
.pal
	move.b	(a0)+,d0	; Blue
	andi.w	#$00e0,d0
	lsr.w	#5,d0
	move.b	(a0)+,d1	; Green
	andi.w	#$00e0,d1
	lsr.w	#1,d1
	or.w	d1,d0
	move.b	(a0)+,d1	; Red
	andi.w	#$00e0,d1
	lsl.w	#3,d1
	or.w	d1,d0
	move.w	d0,(a1)+
	dbra	d2,.pal

	move.l	a0,imagep	; backup image data pointer
	
	move.w	#6,-(sp)	; Setpalette
	trap	#14			; XBIOS
	addq.l	#6,sp

	; calculate sin/cos table
	lea	sin(pc),a0
	lea	cos-sin(a0),a1
	clr.l	(a0)+	; sin(0) = 0
	move.l	#$00000648,d0		; d0=sin(pi/128) = 0.024541228
	move.l	d0,d2				; d2=sin(x)
	move.l	d0,(a0)+
	move.l	#$00010000,(a1)+	; cos(0) = 1
	move.l	#$0000ffec,d1		; d1=cos(pi/128) = 0.999698818
	move.l	d1,d3				; d3=cos(x)
	move.l	d1,(a1)+
	move.w	#61,d7
.sincosloop
	; sin(x+pi/128) = sin(x)*cos(pi/128)+cos(x)*sin(pi/128)
	; cos(x+pi/128) = cos(x)*cos(pi/128)-sin(x)*sin(pi/128)
	move.w	d2,d4
	mulu.w	d1,d4	; d4 = sin(x)*cos(pi/128)
	clr.w	d4
	swap	d4
	move.w	d3,d5
	mulu.w	d0,d5	; d5 = cos(x)*sin(pi/128)
	clr.w	d5
	swap	d5
	add.l	d5,d4	; d4 = sin(x+pi/128)
	move.l	d4,(a0)+
	move.w	d3,d5
	mulu.w	d1,d5	; d5 = cos(x)*cos(pi/128)
	clr.w	d5
	swap	d5
	move.w	d2,d6
	mulu.w	d0,d6	; d6 = sin(x)*sin(pi/128)
	clr.w	d6
	swap	d6
	sub.l	d6,d5	; d5 = cos(x+pi/128)
	move.l	d5,(a1)+
	move.l	d4,d2	; new sin(x)
	move.l	d5,d3	; new cos(x)
	dbra	d7,.sincosloop

	lea	sin(pc),a0
	move.w	#191,d7
.sincosloop2
	move.l	(a0)+,d0
	neg.l	d0			; sin(x) = -sin(x-pi)
	move.l	d0,(a1)+
	dbra	d7,.sincosloop2

	moveq	#0,d1	; angle
mainloop
	addq.w	#8,d1
	and.w	#$3fc,d1
	move.w	d1,-(sp)

	if debug
	supexec setborderok
	endif

	move.w	#37,-(sp)	; Vsync
	trap	#14			; XBIOS
	addq.l	#2,sp

	if debug
	supexec setborderred
	endif

	; chunky to planar Test
	;move.l	#$0000b505,a4	; dX
	;move.l	#$0000b505,a5	; dY
	lea	cos(pc),a0
	move.w	(sp),d0	; angle
	move.l	(a0,d0.w),a4	; a4 = dX = cos(angle)
	;lea	sin-cos(a0),a0
	sub.w	#256,d0
	move.l	(a0,d0.w),a5	; a5 = dY = sin(angle)

	moveq	#10,d0
	move.l	a4,d1
	asr.l	d0,d1
	move.l	d1,a2		; a2 = dX >> 10
	move.l	a5,d1
	asr.l	d0,d1
	move.l	d1,a3		; a3 = dY >> 10

	moveq.l	#0,d4	; X
	moveq.l	#0,d5	; Y

	move.l	imagep,a0
	move.l	physbase,a1
	lea	80-rotowidth/4+(100-rotoheight/2)*160(a1),a1	; to center

	moveq.l	#rotoheight-1,d0
.loopy
	move.w	d0,-(sp)

	move.l	d4,-(sp)
	move.l	d5,-(sp)

	moveq.l	#rotowidth/16-1,d3
.loopx
	rept	16
	move.l	d4,d6
	swap	d6
	and.w	#$003f,d6
	;move.l	d5,d7
	;swap	d7
	;lsl.w	#6,d7
	move.w	d5,d7
	and.w	#$0fc0,d7
	or.w	d7,d6
	add.l	a4,d4
	;add.l	a5,d5
	add.l	a3,d5
	move.b	(a0,d6.w),d2
	lsr.w	#1,d2	;roxr.w	#1,d2
	addx.w	d0,d0	; bit plane 0
	lsr.w	#1,d2	;roxr.w	#1,d2
	addx.w	d1,d1	; bit plane 1
	endr
	move.w	d0,(a1)+
	move.w	d1,(a1)+
	addq.l	#4,a1	; skip bitplanes 2 & 3
	dbra	d3,.loopx

	move.l	(sp)+,d5
	move.l	(sp)+,d4
	sub.l	a5,d4
	;add.l	a4,d5
	add.l	a2,d5
	move.w	(sp)+,d0
	lea	160-rotowidth/2(a1),a1
	dbra	d0,.loopy

	move.w	#11,-(sp)	; Cconis
	trap	#1			; GEMDOS
	addq.l	#2,sp

	move.w	(sp)+,d1	; angle
	tst.w	d0
	beq		mainloop

	move.w	#7,-(sp)	; Crawcin
	trap	#1			; GEMDOS
	addq.l	#2,sp

	clr -(sp)
	trap #1		; Pterm0

	; -------------------
	if debug
setborderred
	move.w	#$0400,$ffff8240.w
	rts

setborderok
	lea	palette(pc),a0
	move.w	(a0),$ffff8240.w
	rts
	endif ; debug

	; *** DATA ***
	data
	; TGA (Truevision Targa) FORMAT :
	;  0 BYTE  ID length
	;  1 BYTE  color map type (0=None, 1=Yes, 2-255=Reserved)
	;  2 BYTE  Image type (0=None, 1=indexed raw, 2=True color raw,
	;                      3=grey raw, 9=indexed RLE, 10=True color RLE,
	;                      11=grey RLE)
	;  3 WORD  first color map index
	;  5 WORD  color map index length
	;  7 BYTE  color map bit per pixel (24)
	;  8 WORD  X-origin
	; 10 WORD  Y-origin
	; 12 WORD  Width
	; 14 WORD  Height
	; 16 BYTE  Pixel depth
	; 17 BYTE  image descriptor : lower 4bits = alpha depth, bits 4,5 = direction
	; 18     n BYTES image ID field (n at offset 0)
	; 18+n   m BYTES color map data (m=color map length * color map bpp/8)
	; 18+n+m x BYTES Image data

tga
	incbin "logo64.tga"

	; *** BSS ***
	bss
rezbackup
	ds.w	1
physbase
	ds.l	1
logbase
	ds.l	1
imagep
	ds.l	1
palette
	ds.w	16
sin
	ds.l	64
cos
	ds.l	256
