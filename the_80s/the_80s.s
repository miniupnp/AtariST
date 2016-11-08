; Atari ST Slide Show "The Eighties"
;
; code:  nanard    https://github.com/miniupnp/AtariST/the_80s
; music: Estryak

enable_music	equ 1
loadiff_store_current_line	equ 1
debug	equ 0


	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

	if debug
	include '../asmlib/hatari.s'
	endif

	; CODE ENTRY POINT
	code

	move.l  4(sp),a5        ; address to basepage
    move.l  $0c(a5),d0      ; length of text segment
    add.l   $14(a5),d0      ; length of data segment
	add.l   $1c(a5),d0      ; length of bss segment
    add.l   #$1000,d0       ; length of stackpointer
	add.l   #$100,d0        ; length of basepage
	move.l  a5,d1           ; address to basepage
	add.l   d0,d1           ; end of program
	and.l   #-2,d1          ; make address even
	move.l  d1,sp           ; new stackspace

	move.l  d0,-(sp)        ; new size
	move.l  a5,-(sp)        ; memory block pointer
	;move.w  d0,-(sp)        ; ?
	clr.w	-(sp)
	move.w  #$4a,-(sp)      ; Mshrink
	trap    #1          	; GEMDOS
	lea 	12(sp),sp       ; http://toshyp.atari.org/en/00500c.html#Mshrink


	supexec backuppalette
	lea		palettebackup,a0
	lea		palettea,a1
	lea		paletteb,a2
	move.w	#15,d0
.cpypala
	move.w	(a0),(a1)+
	move.w	(a0)+,(a2)+
	dbra	d0,.cpypala

	move.l	#framebuffer+255,d0
	clr.b	d0
	move.l	d0,framep

	move.w	#4,-(sp)	; Getrez
	trap	#14			; XBIOS
	move.w	d0,rezbackup

	move.w    #2,(sp)     ; Physbase
	trap      #14          ; XBIOS
	move.l	d0,physbase

	move.w    #3,(sp)     ; Logbase
	trap      #14          ; XBIOS
	move.l	d0,logbase
	addq.l    #2,sp        ; correct stack

	move.w    #0,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	; VT52 part
	pea	msg1
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	move.l	#fileiddiz,2(sp)
	trap	#1		; GEMDOS
	addq.l	#6,sp

	lea	fileiddiz,a0
	bsr loadfile

	tst.w	d0
	bmi.s	.fileiddizerror

	pea	msgok
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	addq.l	#6,sp

	lea	filebuffer,a6
	bsr	printslow
	bra.s	.checkfiles

.fileiddizerror
	pea	msgnotfound
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	addq.l	#6,sp

.checkfiles
	lea	files,a6
.filecheckloop
	pea	msgcheck
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	move.l	a6,2(sp)
	trap	#1		; GEMDOS
	addq.l	#6,sp
	move.w	#0,-(sp)	; read-only
	move.l	a6,-(sp)	; fname
	move.w	#61,-(sp)	; Fopen
	trap	#1			; GEMDOS
	addq.l	#8,sp
	tst.l	d0
	bmi.s	.openerror
	move.w	d0,-(sp)	; handle
	move.w	#62,(sp)	; Fclose
	trap	#1			; GEMDOS
	move.l	#msgok,(sp)
	bra.s	.continue
.openerror
	pea		msgnotfound
.continue
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	addq.l	#6,sp
	add.l	#13,a6	; 8+3+dot+null term = 13 chars
	tst.b	(a6)
	bne	.filecheckloop

	; Load font
	pea	msgfont
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	move.l	#fontfile,2(sp)
	trap	#1		; GEMDOS
	addq.l	#2,sp
	move.l	(sp)+,a0
	bsr loadfile
	tst.w	d0
	bmi	.fontloadfailed

	; decode font IFF
	lea	filebuffer,a0
	move.l	framep,a1
	lea	palettec,a2
	bsr	loadiff

	; prepare (preshift font)

	lea	font,a1
	moveq.l	#0,d7	; char index
.charloop
	move.l	d7,-(sp)
	divu.w	#10,d7	; upperword = column, lower word = line
	move.w	#25*160,d0	; char height = 25
	mulu.w	d7,d0
	swap	d7
	lsl.w	#4,d7
	add.w	d7,d0
	move.l	framep,a0
	adda.w	d0,a0	; pointer to character

	move.l	a1,a2
	moveq.l	#0,d0
	; unshifted char
	move.w	#25-1,d1
.ccl1
	move.l	d0,(a1)+	; 16 black pixels
	move.l	d0,(a1)+
	move.l	(a0)+,(a1)+	; 32 font pixels
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	add.l	#144,a0
	dbra	d1,.ccl1

	; shifted by 2 pixels 7 times
	move.w	#7*25-1,d1
.ccl2
	move.w	#8-1,d2
.ccl2b
	move.w	(a2)+,d0
	swap	d0
	move.w	6(a2),d0
	lsl.l	#2,d0
	swap	d0
	move.w	d0,(a1)+
	dbra	d2,.ccl2b
	rept 4
	move.w	(a2)+,d0
	lsl.w	#2,d0
	move.w	d0,(a1)+
	endr
	dbra	d1,.ccl2

	move.l	(sp)+,d7	; char index
	addq.l	#1,d7
	cmp.w	#64,d7
	blt.s	.charloop

	pea		msgok
	bra.s	.continuef

.fontloadfailed
	pea		msgnotfound
.continuef
	move.w	#9,-(sp)	; Cconws
	trap	#1		; GEMDOS
	addq.l	#6,sp

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp


	; starting for real...

	supexec	install		; install interrupt handlers
	;clr.l	-(sp)			; supervisor mode
	;move.w	#$20,-(sp)		;
	;trap	#1			;
	;addq.l	#6,sp			;
	;move.l	d0,oldusp		; store old user stack pointer

	if	enable_music
	supexec	MUSIC+0			; init music
	endif

	move.w    #$27,-(sp)   ; attr  includes everything except volumes and dirs
	pea       searchpattern; filename
	move.w    #78,-(sp)    ; Fsfirst
	trap      #1           ; GEMDOS
	addq.l    #8,sp
	tst.l	d0
	bmi.s	end
.loop
	move.w    #47,-(sp)    ; Fgetdta
	trap      #1           ; GEMDOS
	addq.l    #2,sp
	add.l	#30,d0	; offset of file name in DTA
	move.l	d0,a0
	bsr loadfile
	tst.l	d0
	bmi.s	end

	lea	filebuffer,a0
	;move.l	physbase,a1
	move.l	framep,a1
	lea	palettea,a2
	bsr	loadiff

	supexec setvideobase

	lea		palettea,a0
	lea		paletteb,a1
	move.w	#15,d0
.cpypalb
	move.w	(a0)+,(a1)+
	dbra	d0,.cpypalb
	;pea	palette
	;move.w	#6,-(sp)	; Setpalette
	;trap	#14			; XBIOS
	;addq.l	#6,sp

	;move.w	#150,loadiff_current_line

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	move.w    #79,-(sp)    ; Fsnext
	trap      #1           ; GEMDOS
	addq.l    #2,sp
	tst.l	d0
	bge	.loop


end:
	move.w	#7,-(sp)	; Crawcin
	trap	#1			; GEMDOS
	addq.l	#2,sp

	if	enable_music
	supexec MUSIC+4			; de-init music
	endif
	supexec uninstall

	; restore palette
	pea	palettebackup
	move.w	#6,-(sp)	; Setpalette
	trap	#14			; XBIOS
	addq.l	#6,sp

	move.w    rezbackup,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	clr (sp)
	trap #1		; Pterm0

	; ------------------------------------------------------

	; subroutines

	; arguments :
	; d0 = character (ascii)
	; d1 = X position
	; trashes d0-d1/a0-a1
putchar
	cmp.w	#-32,d1
	blt.s	.exit
	cmp.w	#320,d1
	bge.s	.exit

	; TODO : to upper case
	sub.w	#32,d0
	lsl.w	#4,d0	; *16
	eor.w	d1,d0
	and.w	#%1111111111110001,d0
	eor.w	d1,d0
	eor.w	#%1110,d0
	mulu.w	#25*3*4,d0
	lea		font,a0
	adda.l	d0,a0
	move.l	framep,a1
	add.l	#160*201,a1

	cmp.w	#-16,d1
	blt.s	.skiptwowords
	cmp.w	#0,d1
	blt.s	.skiponeword

	move.w	d1,d0
	lsr.w	#1,d0
	and.w	#-8,d0
	adda.w	d0,a1

	cmp.w	#320-16,d1
	bge.s	.skiplasttwowords
	cmp.w	#320-32,d1
	bge.s	.skiplastoneword

	move.w	#25-1,d0
.loopline
	rept	3*2
	move.l	(a0)+,(a1)+
	endr
	add.l	#160-24,a1
	dbra	d0,.loopline
.exit
	rts

.skiponeword
	move.w	#25-1,d0
.looplineb
	addq.l	#8,a0
	rept	2*2
	move.l	(a0)+,(a1)+
	endr
	add.l	#160-16,a1
	dbra	d0,.looplineb
	rts

.skiptwowords
	move.w	#25-1,d0
.looplinec
	add.l	#16,a0
	rept	2
	move.l	(a0)+,(a1)+
	endr
	add.l	#160-8,a1
	dbra	d0,.looplinec
	rts

.skiplastoneword
	move.w	#25-1,d0
.looplined
	rept	2*2
	move.l	(a0)+,(a1)+
	endr
	addq.l	#8,a0
	add.l	#160-16,a1
	dbra	d0,.looplined
	rts

.skiplasttwowords
	move.w	#25-1,d0
.looplinee
	rept	2
	move.l	(a0)+,(a1)+
	endr
	add.l	#16,a0
	add.l	#160-8,a1
	dbra	d0,.looplinee
	rts
	; *** putchar end ***

	; argument : a6
printslow
	pea	$00020040	; 2 = Cconout
.loop
	move.b	(a6)+,3(sp)
	beq.s	.breakloop
	trap	#1		; GEMDOS
	cmp.b	#10,3(sp)	; LF ?
	beq.s	.lf
	move.b	(a6)+,3(sp)
	beq.s	.breakloop
	trap	#1		; GEMDOS
	cmp.b	#10,3(sp)	; LF ?
	bne.s	.notlf
.lf
	move.b	#7,3(sp)	; BEL
	trap	#1		; GEMDOS
.notlf
	move.w    #37,-(sp)    ; Vsync
	trap      #14          ; XBIOS
	addq.l	#2,sp
	bra	.loop
.breakloop
	addq.l	#4,sp
	rts


backuppalette
	lea	$ffff8240.w,a0
	lea palettebackup,a1
cpypal
	move.w	#15,d0
.palcpyloop:
	move.w	(a0)+,(a1)+
	dbra	d0,.palcpyloop
	rts

setvideobase
	move.l	framep,d0
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w	; Video base medium
	lsr.w	#8,d0
	move.b	d0,$ffff8201.w	; Video base high
	rts

install
	move.l	#hbl199,$120
	or.b 	#1,$fffffa07.w 	;enable Timer B
	or.b 	#1,$fffffa13.w	;interrupt mask
	move.l	$70,oldvbl+2
	move.l	#vbl,$70
	move.b 	#0,$fffffa1b.w 	;Timer B stop
	rts

uninstall:
	move.l	oldvbl+2,$70
	move.b 	#0,$fffffa1b.w 	;Timer B stop
	rts

	; Interrupt handlers
vbl
	move.l	#hbl199,$120
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	loadiff_current_line,d0
	;addq.w	#1,d0
	move.w	#199,d1
	cmp.w	d1,d0
	bge.s	.nopalswap
	move.l	#hbl,$120
	addq.w	#1,d0
	sub.w	d0,d1
	move.b	d1,hblcount2
	move.w	d0,d1
.nopalswap
	move.b 	#0,$fffffa1b.w 	;Timer stop
	;move.b	#199,$fffffa21.w 	;Counter value
	move.b	d1,$fffffa21.w 	;Counter value
	move.b 	#8,$fffffa1b.w 	;Timer start

	;move.w	#$00f,$ffff8240.w	; blue
	move.w	#$000,$ffff8240.w	; black
	if	enable_music
	bsr 	MUSIC+8			; call music
	endif
	; set palettea
	lea		palettea,a0
	lea		$ffff8240.w,a1
	move.w	#15,d0
.loop
	move.w	(a0)+,(a1)+
	dbra	d0,.loop

	; scrolltext
	if debug
	move.w	#$b00,$ffff8240.w	; red
	endif
	move.w	tmppos,d0
	move.w	tmppos+2,d1
	sub.w	#48,d1
.scrollloop
	movem.w	d0-d1,-(sp)
	lea		scrolltext,a0
	move.b	(a0,d0),d0
	and.w	#$ff,d0
	bsr		putchar
	movem.w	(sp)+,d0-d1
	addq.w	#1,d0
	cmp.w	#scrolltextlen,d0
	blt.s	.ok
	moveq.l	#0,d0
.ok
	add.w	#48,d1
	cmp.w	#320,d1
	blt.s	.scrollloop

	sub.w	#4,tmppos+2
	bge.s	.okc
	add.w	#48,tmppos+2
	move.w	tmppos,d0
	addq.w	#1,d0
	cmp.w	#scrolltextlen,d0
	blt.s	.okb
	moveq.l	#0,d0
.okb
	move.w	d0,tmppos
.okc

	if debug
	move.w	#$000,$ffff8240.w	; black
	endif
	movem.l	(sp)+,d0-d1/a0-a1
oldvbl
	jmp $0.l
tmppos
	dc.w	0
	dc.w	320*2

hbl
	move.l	#hbl199,$120
	move.b 	#0,$fffffa1b.w 	;Timer B stop
	move.b	hblcount2,$fffffa21.w 	; timer B data : Counter value
	move.b 	#8,$fffffa1b.w 	;Timer B start : Event count mode
	; set paletteb
	movem.l	d0/a0-a1,-(sp)
	lea		paletteb,a0
	lea		$ffff8240.w,a1
	move.w	#15,d0
.loop
	move.w	(a0)+,(a1)+
	dbra	d0,.loop
	movem.l	(sp)+,d0/a0-a1
	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	rte

hbl199
	movem.l	d0/a0-a1,-(sp)
	if debug
	move.w	#$00f,$ffff8240.w	; blue
	endif
	lea	$ffff8209.w,a0
	move.b	(a0),d0
	add.b	#160,d0
.waitlineend
	cmp.b	(a0),d0
	bne.s	.waitlineend

	eor.b	#2,$ffff820a.w		; 50Hz/60Hz switch
	if debug
	move.w	#$0f0,$ffff8240.w	; green
	or.l	d0,d0
	or.l	d0,d0
	else
	rept 6
	or.l	d0,d0
	endr
	endif
	eor.b	#2,$ffff820a.w		; 50Hz/60Hz switch
	;set palettec
	lea		palettec,a0
	lea		$ffff8240.w,a1
	move.w	#15,d0
.loop
	move.w	(a0)+,(a1)+
	dbra	d0,.loop

	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	movem.l	(sp)+,d0/a0-a1
	rte

	; includes

	include '../asmlib/loadfile.s'
	include '../show_iff/loadiff.s'
	code
MUSIC
	incbin	'TELEPHO3.SND'; SNDH file

	data
searchpattern
	dc.b	'*.IFF',0
fileiddiz
	dc.b	'FILE_ID.DIZ',0
	; see http://toshyp.atari.org/en/VT_52_terminal.html
msg1
	dc.b	27,'E',27,'e'	; clear screen, show cursor
msgloading
	dc.b 	"Loading ",0
msgfont
	dc.b	"Loading font ",0
msgok
	dc.b	27,'b',2	; Forground color 2=green
	dc.b	' OK',27,'b',15,13,10,7,0
msgcheck
	dc.b	'Checking ',0
msgnotfound
	dc.b	27,'b',1	; Forground color 1 = red
	dc.b	' NOT FOUND',27,'b',15,13,10,7,0
files	;   '12345678.123',0,''
	dc.b	'80.IFF',0,'      '
	dc.b	'BARCO1.IFF',0,'  '
	dc.b	'BATMAN.IFF',0,'  '
	dc.b	'BRUCE.IFF',0,'   '
	dc.b	'FERRARIW.IFF',0
	dc.b	'PANDA.IFF',0,'   '
	dc.b	'RACHEL.IFF',0,'  '
	dc.b	'REPLCANT.IFF',0
	dc.b	'RIPLEY.IFF',0,'  '
	dc.b	'ROBOCOP.IFF',0,' '
	dc.b	'STORMTRO.IFF',0
	dc.b	'SUPERMAN.IFF',0
	dc.b	'T800B.IFF',0,'   '
	dc.b	0
fontfile
	dc.b	'KNIGHT6.IFF',0

scrolltext
	dc.b	'HELLO TO THIS OLD SCHOOL SLIDE SHOW...'
	dc.b	' CREDITS:  '
	dc.b	'CODE: NANARD '
	dc.b	'MUSIC: ESTRYAK '
	dc.b	'        ... '
	dc.b	'STAY ATARI!!!  LOOPING  '
scrolltextend

scrolltextlen	equ	scrolltextend-scrolltext

	bss
	align	2
;oldusp
;	ds.l	1
palettebackup
	ds.w	16
palettea
	ds.w	16
paletteb
	ds.w	16
palettec
	ds.w	16
rezbackup
	ds.w	1
logbase
	ds.l	1
physbase
	ds.l	1
framep
	ds.l	1
font
	ds.w	8*64*25*3*4	; 64 chars in 32*25 => 25*3*4 words. preshifted
filebuffer
	ds.b	32000
hblcount2
	ds.b	1
framebuffer
	ds.b	160*248