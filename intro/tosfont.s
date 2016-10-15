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

	; affichage des caracteres
	move.w    #2,-(sp)     ; Physbase
	trap      #14          ; XBIOS
	addq.l    #2,sp        ;
	move.l	d0,a6

	move.l	pFnthdr,a4
	;move.l	0(a4),a4	; font #0 = 6x6
	;move.l	4(a4),a4	; font #1 = 8x8
	move.l	8(a4),a4	; font #2 = 8x16
	move.l	72(a4),a3	; character offset table
	move.l  76(a4),a4	; pointer to font image
	move.l	a4,d0
	bsr		printlhex
	;cconout #$20
	;move.l	pFnthdr,a4
	;move.l	8(a4),a0	; font #2 = 8x16
	;move.l	80(a4),d0	; width and heigth
	;bsr		printlhex

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	move.l	a6,a5

	move.w	#7,d5	; 8 lignes
.loopa
	move.w	#15,d6	; 16 caracteres par ligne
.loop0
	move.w	#15,d7
.loop1
	move.b  (a4),0(a5)
	move.b  (a4),2(a5)
	move.b  (a4),4(a5)
	move.b  (a4),6(a5)
	add.l	#256,a4
	add.l	#160,a5
	dbra	d7,.loop1
	sub.l	#2559,a5
	sub.l	#4095,a4

	move.w	#15,d7
.loop2
	move.b  (a4),0(a5)
	move.b  (a4),2(a5)
	move.b  (a4),4(a5)
	move.b  (a4),6(a5)
	add.l	#256,a4
	add.l	#160,a5
	dbra	d7,.loop2
	sub.l	#2553,a5
	sub.l	#4095,a4

	dbra	d6,.loop0

	add.l	#2432,a5
	dbra	d5,.loopa

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	clr -(sp)
	trap #1		;Pterm0

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

	; bss
	bss
pFnthdr:
	ds.l	1


