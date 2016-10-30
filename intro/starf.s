; (c) 2016 nanard
; https://github.com/miniupnp/AtariST
;
; starfield

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

	; CODE ENTRY POINT
	code

	supexec setuppalette
 	

	pea	$0	; Switch cursor off (hide it)
	move.w    #21,-(sp)    ; Cursconf
	trap      #14          ; 
	addq.l    #6,sp        ;

	move.w	#4,-(sp)	; Getrez
	trap	#14			; XBIOS
	addq.l	#2,sp
	move.w	d0,rezbackup

	move.w    #2,-(sp)     ; Physbase
	trap      #14          ; XBIOS
	addq.l    #2,sp        ;
	move.l	d0,physbase

	move.w    #3,-(sp)     ; Logbase
	trap      #14          ; XBIOS
	addq.l    #2,sp        ;
	move.l	d0,logbase

	move.w    #0,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	move.l	physbase,a0
	move.w	#$aaaa,(a0)+	; 16 pixel gradient from white to black
	move.w	#$cccc,(a0)+
	move.w	#$f0f0,(a0)+
	move.w	#$ff00,(a0)+
	move.w	#$5555,(a0)+	; 16 pixel gradient from black to white
	move.w	#$3333,(a0)+
	move.w	#$0f0f,(a0)+
	move.w	#$00ff,(a0)+

	move	#$8000,d0
	move	#15,d1
.loop0
	lea	160(a0),a0
	move.w	d0,6(a0)
	lsr.w	#1,d0
	dbra	d1,.loop0

	move.l	physbase,a0
	moveq	#0,d0
	moveq	#0,d1
.loop:
	move.w	d0,-(sp)
	move.w	d1,-(sp)
	bsr		putpixel	; d0=X d1=Y
	move.w	(sp)+,d1
	move.w	(sp)+,d0
	addq	#1,d0
	addq	#1,d1
	cmp.w	#200,d1
	bne.s	.loop

	move.w	#500,d3
.loopr
	;supexec	rand
	bsr	rand
	move.l	d0,d1
	swap	d0
	andi.w	#127,d1
	andi.w	#255,d0
	move.l	physbase,a0
	bsr.s	putpixel
	dbra	d3,.loopr

mainloop:
	move.w	#0,setpal+2	;black
	supexec	setpal

	move.w    #37,-(sp) ; Vsync (wait VBL)
	trap      #14       ; XBIOS
	addq.l    #2,sp

	move.w	#$f00,setpal+2	;red
	supexec	setpal

	move.w	#4000,d0
.lp
	nop
	dbra	d0,.lp

	move.w	#11,-(sp)	; Cconis
	trap	#1
	addq.l	#2,sp
	tst.w	d0	; DEV_READY (-1) if char is available / DEV_BUSY (0) if not
	beq		mainloop

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	supexec restorepalette

	move.w    rezbackup,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	clr -(sp)
	trap #1		;Pterm0

	; d0 = X, d1 = Y, a0 = screen
	; trashes d2
putpixel:
	lsl.w	#5,d1	; d1 = 32 * Y
	move.w	d1,d2
	lsl.w	#2,d1	; d1 = 128 * Y
	add.w	d2,d1	; d1 = 160 * Y
	move.w	d0,d2
	andi.w	#$f,d0	; d0 = X % 16
	andi.w	#$fff0,d2
	lsr.w	#1,d2
	add.w	d2,d1	; d1 = 160 * Y + (X / 16)*8

	; shift + OR version
	;move.w	#$8000,d2
	;lsr.w	d0,d2	; d2 = bit mask
	;or.w	d2,6(a0,d1)	; 4th word (bit plan)

	; bset.b version
	move.w	d0,d2
	lsr.w	#3,d2
	add.w	d2,d1	; d1 = 160 * Y + (X / 16)*8 + ((X / 8) % 2)
	eor.w	#$f,d0
	bset.b	d0,6(a0,d1)	; ; 4th bit plan

	rts

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

setpal:
	move.w	#$0f0f,$ffff8240.w	; set color 0
	rts

setuppalette:
	lea	palettebackup(pc),a1
	lea	$ffff8240.w,a0
	move.w	#15,d0
.backuppal:
	move.w	(a0)+,(a1)+
	dbra	d0,.backuppal
	clr.w	d0
	lea	$ffff8240,a0
.setpal:
	move.w	d0,d1
	lsr.w	#1,d1
	andi.w	#$0fff,d1
	move.w	d1,(a0)+
	addi.w	#$1111,d0
	bcc.s	.setpal
	rts

restorepalette:
	lea	palettebackup,a1
	lea	$ffff8240.w,a0
	move.w	#15,d0
.restorepal:
	move.w	(a1)+,(a0)+
	dbra	d0,.restorepal
	rts

	include 'random.s'

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
palettebackup:
	ds.w	16
physbase:
	ds.l	1
logbase:
	ds.l	1
rezbackup:
	ds.w	1
