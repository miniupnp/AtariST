; (c) 2016 nanard
; https://github.com/miniupnp/AtariST

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

 	
	macro cconout		; 1 argument : character to output
	move.w    \1,-(sp)     ; Offset 2
	move.w    #2,-(sp)     ; Cconout
	trap      #1           ; GEMDOS
	addq.l    #4,sp        ; Correct stack
	endm

	; CODE ENTRY POINT
	code

	; Line-A initialization / linea_init
 	movem.l   D0-D2/A0-A2,-(A7)  ; Save registers
	dc.w      $A000              ; Line-A opcode
	;move.l    A0,pParamblk       ; Pointer parameter block LINEA
	move.l    A1,pFnthdr         ; Pointer system fonts
	;move.l    a2,pFktadr         ; Pointer start addr. Line-A routines
	dc.w	$a00a			; Line-A Hide mouse
	movem.l   (a7)+,d0-d2/a0-a2  ; Restore registers


	move.l	pFnthdr,a2
.loopfont:
	move.l	(a2)+,d0		; font address
	move.l	d0,d3
	bsr		printlhex
	tst.l	d3
	beq		.exitloopfont
	cconout #$20
	addq.l	#4,d3		; font name
	move.l	d3,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	cconout #$20
	move.l	d3,a0
	move.l	76(a0),d0	; font width and heigth
	bsr		printlhex
	cconout #$A
	cconout #$D
	bra.s	.loopfont
.exitloopfont

	pea		msg1
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp

.mainloop
	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	; check key in '0'..'2'
	cmpi.w	#'2'+1,d0
	bcc	.exit
	subi.w	#'0',d0
	bcc	.keyok
.exit
	clr -(sp)
	trap #1		;Pterm0

.keyok
	andi.w	#3,d0
	add.w	d0,d0
	add.w	d0,d0

	move.l	pFnthdr,a4
	;move.l	0(a4),a3	; font #0 = 6x6
	;move.l	4(a4),a3	; font #1 = 8x8
	;move.l	8(a4),a3	; font #2 = 8x16
	move.l	(a4,d0.w),a3
	;move.l	72(a3),a3	; character offset table
	move.l  76(a3),a4	; pointer to font image
	;move.l	a4,d0
	;bsr		printlhex

	; character display
	move.w    #2,-(sp)     ; Physbase
	trap      #14          ; XBIOS
	addq.l    #2,sp        ;
	;move.l	d0,a6
	move.l	d0,a5

	move.w	80(a3),d0	; font image Width
	move.w	82(a3),d1	; font image height = character height
	move.w	d1,d2
	move.w	d1,d3
	mulu.w	#160,d1		; screen pointer return offset
	subq	#1,d1
	mulu.w	d0,d2		; font pointer offset
	subq	#1,d2
	subq	#1,d3		; screen pointer line offset
	mulu.w	#160,d3
	add.w	#32,d3

	; d0 = font image width (in bytes)
	; d1 = screen offset to next line of the character (1 pixel below)
	; d2 = font offset to next character
	; d3 = screen offset to next line of characters (8 or 16 pixels below)
	; d4
	; d5 = character line counter (8 lines of 32 chars)
	; d6 = character couple counter (16*2 characters per line)
	; d7 = character pixels line counter

	move.w	#7,d5	; 8 lines
.loopa
	cmp.w	#6,52(a3)	; Largest character width
	beq		.size6
	move.w	#15,d6	; of 2*16 characters
.loop0
	move.w	82(a3),d7	; character height (height of the font image)
	subq	#1,d7
.loop1
	move.b  (a4),0(a5)
	move.b  (a4),2(a5)
	move.b  (a4),4(a5)
	move.b  (a4),6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5		; next screen line
	dbra	d7,.loop1
	;sub.l	#2559,a5	; 160*16-1
	sub.l	d1,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4

	move.w	82(a3),d7	; character height
	subq	#1,d7
.loop2
	move.b  (a4),0(a5)
	move.b  (a4),2(a5)
	move.b  (a4),4(a5)
	move.b  (a4),6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5
	dbra	d7,.loop2
	;sub.l	#2553,a5	; 160*16-7
	sub.l	d1,a5
	addq	#6,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4

	dbra	d6,.loop0

	;add.l	#2432,a5	; 160*(16-1)-32
	add.l	d3,a5
	dbra	d5,.loopa

	bra .mainloop

	; for the 6x6 font, display characters 4 by 4 :
	; AAAAAABB BBBBCCCC CCDDDDDD
.size6
	move.w	d5,-(sp)

	move.w	#7,d6	; of 4*8 characters
.loop0b

	move.w	82(a3),d7	; character height
	subq	#1,d7
.loop1b
	move.b (a4),d4
	lsr		#2,d4
	andi.w	#$003f,d4
	move.b  d4,0(a5)
	move.b  d4,2(a5)
	move.b  d4,4(a5)
	move.b  d4,6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5		; next screen line
	dbra	d7,.loop1b
	;sub.l	#2559,a5	; 160*16-1
	sub.l	d1,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4
	subq	#1,a4

	move.w	82(a3),d7	; character height
	subq	#1,d7
.loop2b
	move.b 1(a4),d4
	lsr.w	#4,d4
	andi.w	#$003f,d4
	move.b (a4),d5
	andi.w	#$003,d5
	lsl.w	#4,d5
	or.w	d5,d4
	move.b  d4,0(a5)
	move.b  d4,2(a5)
	move.b  d4,4(a5)
	move.b  d4,6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5
	dbra	d7,.loop2b
	;sub.l	#2553,a5	; 160*16-7
	sub.l	d1,a5
	addq	#6,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4

	move.w	82(a3),d7	; character height
	subq	#1,d7
.loop3b
	move.b 1(a4),d4
	lsr.w	#6,d4
	andi.w	#$003f,d4
	move.b (a4),d5
	andi.w	#$000f,d5
	lsl.w	#2,d5
	or.w	d5,d4
	move.b  d4,0(a5)
	move.b  d4,2(a5)
	move.b  d4,4(a5)
	move.b  d4,6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5
	dbra	d7,.loop3b
	;sub.l	#2553,a5	; 160*16-7
	sub.l	d1,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4

	move.w	82(a3),d7	; character height
	subq	#1,d7
.loop4b
	move.b (a4),d4
	andi.w	#$003f,d4
	move.b  d4,0(a5)
	move.b  d4,2(a5)
	move.b  d4,4(a5)
	move.b  d4,6(a5)
	lea		(a4,d0.w),a4
	add.l	#160,a5
	dbra	d7,.loop4b
	;sub.l	#2553,a5	; 160*16-7
	sub.l	d1,a5
	addq	#6,a5
	;sub.l	#4095,a4	; 256*16-1
	sub.l	d2,a4


	dbra	d6,.loop0b

	;add.l	#2432,a5	; 160*(16-1)-32
	add.l	d3,a5

	; add a blank line after characters for 6x6 font
	move.w	#79,d5
.loopblankline
	clr.w	(a5)+
	dbra	d5,.loopblankline

	move.w	(sp)+,d5
	dbra	d5,.loopa

	bra .mainloop

	; ---- sub routines
printlhex:
	lea printbufferend(pc),a0
	lea hexdigits(pc),a1
	move.w #7,d2
.printlhexloop:
	move.l d0,d1
	lsr.l #4,d0
	andi.l #$f,d1
	move.b (a1,d1),-(a0)
	dbra D2,.printlhexloop
	move.l	a0,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts

	; ---- data section
	data
hexdigits:
	dc.b	"0123456789abcdef"
printbuffer:
	dc.b	"00000000"
printbufferend:
	dc.b	0
msg1:
	dc.b	$a,$d,'Press key 0, 1 or 2 to display font',$a,$d,0

	; bss
	bss
pFnthdr:
	ds.l	1


