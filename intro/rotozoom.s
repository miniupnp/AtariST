; (c) 2016 Thomas BERNARD
; https://github.com/miniupnp/AtariST
;
; X = zoom * (x*cos(a) - y*sin(a))
; Y = zoom * (x*sin(a) + y*cos(a))

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


mainloop
	move.w	#37,-(sp)	; Vsync
	trap	#14			; XBIOS
	addq.l	#2,sp

	; chunky to planar Test
	move.l	imagep,a0
	move.l	physbase,a1

	moveq.l	#64-1,d6
.loopy
	moveq.l	#4-1,d7
.loopx
	rept	16
	move.b	(a0)+,d2
	lsr.w	#1,d2	;roxr.w	#1,d2
	addx.w	d0,d0	; bit plane 0
	lsr.w	#1,d2	;roxr.w	#1,d2
	addx.w	d1,d1	; bit plane 1
	endr
	move.w	d0,(a1)+
	move.w	d1,(a1)+
	addq.l	#4,a1	; skip bitplanes 2 & 3
	dbra	d7,.loopx

	lea	128(a1),a1
	dbra	d6,.loopy

	move.w	#11,-(sp)	; Cconis
	trap	#1			; GEMDOS
	addq.l	#2,sp
	tst.w	d0
	beq		mainloop

	move.w	#7,-(sp)	; Crawcin
	trap	#1			; GEMDOS
	addq.l	#2,sp

	clr -(sp)
	trap #1		; Pterm0

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
