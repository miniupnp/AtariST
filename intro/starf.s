; (c) 2016 nanard
; https://github.com/miniupnp/AtariST
;
; 68000 instruction timings :
; http://oldwww.nvg.ntnu.no/amiga/MC680x0_Sections/mc68000timing.HTML
;
; starfield

nb_stars	equ 220
raster_dbg	equ	0

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
	lea	160(a0),a0		; next line
	move.w	d0,6(a0)
	lsr.w	#1,d0		; pixel to the right
	dbra	d1,.loop0

	if 0
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
	endif

	; fill stars array
	lea		stars(pc),a1
	move.w	#nb_stars-1,d3
.loopr
	;supexec	rand
	bsr	rand
	move.w	d0,d1
	swap	d0
	;andi.w	#511,d1
	;andi.w	#1023,d0
	;subi.w	#256,d1
	;subi.w	#512,d0
	move.w	d0,(a1)+	; X
	move.w	d1,(a1)+	; Y
	bsr	rand
	andi.w	#1023,d0
	add.w	#1,d0
	move.w	d0,(a1)+	; Z
	move.w	#0,(a1)+	; old addr
	dbra	d3,.loopr

	; ==== MAIN LOOP ====
mainloop:
	if	raster_dbg
	move.w	#0,setpal+2	;black
	supexec	setpal
	endif

	move.w    #37,-(sp) ; Vsync (wait VBL)
	trap      #14       ; XBIOS
	addq.l    #2,sp

	if	raster_dbg
	move.w	#$a00,setpal+2	;red
	supexec	setpal
	endif

	move.l	physbase,a0
	lea	stars(pc),a1
	addq	#6,a1
	move.w	#nb_stars-1,d7
	moveq.l	#0,d0
.blankloop
	move.w	(a1),d1
	;move.b	d0,6(a0,d1)
	;move.w	d0,6(a0,d1)
	move.l	d0,4(a0,d1)
	addq	#8,a1
	dbra	d7,.blankloop

	if	raster_dbg
	move.w	#$00a,setpal+2	;blue
	supexec	setpal
	endif

	move.w	#200,d4		; Y max
	move.w	#160*2-1,d5	; X center
	move.w	#99*2-1,d6	; Y center
	if	raster_dbg
	move.l	physbase,a0
	lea	stars(pc),a1
	else
	sub.l	#nb_stars*8+6,a1
	endif
	move.w	#nb_stars-1,d7
.starloop
	move.w	(a1)+,d0	; X
	move.w	(a1)+,d1	; Y
	move.w	(a1),d3	; Z
	ext.l	d0
	ext.l	d1

	divs.w	d3,d0
	divs.w	d3,d1

	; decrement Z
	subq.w	#7,d3
	;cmp.w	#8,d3
	bge.s	.zok
	;bne.s	.zok
	add.w	#1024,d3
.zok
	move.w	d3,(a1)+

	add.w	d6,d1	; Y center
	bmi.s	.skipstar
	add.w	d5,d0	; X center
	bmi.s	.skipstar
	asr.w	#1,d1
	asr.w	#1,d0
	cmp.w	d4,d1	; Y max
	bge.s	.skipstar
	cmp.w	#320,d0	; X max
	bge.s	.skipstar
	bsr		putpixel
	move.w	d1,(a1)+
	dbra	d7,.starloop
	bra.s	.endstarloop

.skipstar
	addq	#2,a1
	dbra	d7,.starloop
.endstarloop

	if	raster_dbg
	move.w	#$0a0,setpal+2	;green
	supexec	setpal
	endif

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
	lsl.w	#5,d1	; d1 = 32 * Y		6+2*5=16 clock cycles
	move.w	d1,d2	;                   4 clock cycles
	;lsl.w	#2,d1	; d1 = 128 * Y      6+2*2=10 clock cycles
	add.w	d1,d1	; d1 = 64 * Y       4 clock cycles
	add.w	d1,d1	; d1 = 128 * Y      4 clock cycles
	add.w	d2,d1	; d1 = 160 * Y      8 clock cycles
	; 16 + 4 + 10 + 8 = 38 clock cycles
	; 16 + 4 + 4 + 4 + 8 ) 36 clock cycles
	;mulu.w	#160,d1	; d1 = 160 * Y      38+2*2+4=42+4=46 clock cycles
	move.w	d0,d2
	andi.w	#$f,d0	; d0 = X % 16
	andi.w	#$fff0,d2	; 8 clock cycles
	lsr.w	#1,d2		; 8 clock cycles
	add.w	d2,d1	; d1 = 160 * Y + (X / 16)*8

	; shift + OR version
	move.w	#$8000,d2	;                     8 clock cycles
	lsr.w	d0,d2	; d2 = bit mask           6+2n : from 6 to 36 clock cycles
	or.w	d2,6(a0,d1)	; 4th word (bit plan) 8+10=18 cycles
	or.w	d2,4(a0,d1)	; 4th word (bit plan) 8+10=18 cycles
	; 8 + [6;36] + 18 = [32;62] mean is 47...

	; bset.b version
	;move.w	d0,d2	;   4 clock cycles
	;lsr.w	#3,d2	;   6+2*3=12 clock cycles
	;add.w	d2,d1	; d1 = 160 * Y + (X / 16)*8 + ((X / 8) % 2)  4 clock cycles
	;eor.w	#$f,d0	;   8 clock cycles
	;bset.b	d0,6(a0,d1)	; 4th bit plan   8+10=18 cycles
	; 4 + 12 + 4 + 8 + 18 = 46 clock cycles

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
stars:
	ds.w	4*nb_stars	; word (X,Y,Z,old_addr)
