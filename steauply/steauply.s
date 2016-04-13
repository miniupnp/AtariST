; 8bit signed PCM .AU player for Atari STE
; (c) 2016 nanard
; https://github.com/miniupnp/AtariST
buffersize equ 65536
	code

	lea _cconws(pc),a5	; we call this function a lot

	lea msg1(pc),a0
	jsr (a5)	;bsr _cconws

	; detect the machine (ST / STE / TT / Falcon / etc.)
	move.l	#'_MCH',d6
	pea		get_cookie(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	cmp.l	#-1,d0		; no cookie jar or no cookie found
	beq		is_st
	swap	d0
	tst		d0
	beq		is_st
	; if not ST, the machine is STE or better (all have DMA sound ?)

	;lea filename(pc),a0
	move	#47,-(sp)	; Fgetdta
	trap	#1
	addq.l	#2,sp
	move.l	d0,a0		; dta / command line
	moveq	#0,d0
	move.b	(a0)+,d0	; command line length
	clr.b	(a0,d0.w)	; zero byte at end of command line

	bsr openfile	; and show info
	tst.l	d6
	bmi	end

	;pea buffersize*2 ; to allocate
	;move.l #$ffffffff,-(sp)	; to get freememory
	;move.w    #72,-(sp)    ; Malloc
	;trap      #1           ; GEMDOS
	;addq.l    #6,sp        ; Correct stack
	;move.l d0,bufferp		;backup buffer address
	lea buffer(pc),a0
	move.l a0,bufferp

	move.l a0,d0
	jsr printlhex(pc)
	lea crlf(pc),a0
	jsr (a5)

	; initial load
	move.l bufferp(pc),-(sp)	; address
	pea buffersize*2 ; len
	move	d6,-(sp) ; handle
	move	#63,-(sp) ; Fread
	trap	#1
	lea 12(sp),sp
	
	jsr printlhex(pc)
	lea crlf(pc),a0
	jsr _cconws(pc)

	pea       setdma       ; Offset 2
	move.w    #38,-(sp)    ; Offset 0
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

	move.l	bufferp(pc),d5
	addi.l	#buffersize,d5

	lea	playmsg(pc),a0
	jsr	(a5)	;_cconws(pc)

mainloop:
	move.w	#11,-(sp)	; Cconis
	trap	#1
	addq.l	#2,sp
	tst.w	d0	; DEV_READY (-1) if char is available / DEV_BUSY (0) if not
	bne		stop

	pea	getdmasoundpos
	move.w    #38,-(sp)    ; Offset 0
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

	;move.l	d0,-(sp)
	;jsr printlhex(pc)
	;lea crlf(pc),a0
	;jsr _cconws(pc)
	;move.l	(sp)+,d0

	cmp.l	d0,d5
	bge	mainloop

	jsr printlhex(pc)
	lea lowbufread(pc),a0
	jsr (a5)

	;load next !
	move.l bufferp(pc),-(sp)	; address
	pea buffersize	; len
	move	d6,-(sp) ; handle
	move	#63,-(sp) ; Fread
	trap	#1
	lea 12(sp),sp
	cmp.l	#buffersize,d0
	bne.s	endoffile

waitloop2:
	move.w	#11,-(sp)	; Cconis
	trap	#1
	addq.l	#2,sp
	tst.w	d0
	bne.s	stop

	pea	getdmasoundpos
	move.w    #38,-(sp)    ; Offset 0
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

	cmp.l	d0,d5
	blt		waitloop2

	jsr printlhex(pc)
	lea hibufread(pc),a0
	jsr (a5)

	;load next !
	move.l d5,-(sp)	; address
	pea buffersize	; len
	move	d6,-(sp) ; handle
	move	#63,-(sp) ; Fread
	trap	#1
	lea 12(sp),sp
	cmp.l	#buffersize,d0
	beq		mainloop

endoffile:
	jsr	printlhex
	lea	endoffilemsg(pc),a0
	jsr	(a5)

	; TODO
	; wait for the last few samples to be played
	; before calling stopdmasound

stop:
	pea	stopdmasound
	move.w    #38,-(sp)    ; Offset 0
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

closefile:
	move	d6,-(sp)
	move	#62,-(sp)	; Fclose
	trap	#1
	addq.l	#4,sp

end:
	bsr.s	presskey
	clr -(sp)
	trap #1		;Pterm0

is_st:
	lea		stmsg(pc),a0
	bsr.s	_cconws
	bra.s	end

presskey:
	;lea	presskey_txt(pc),a0
	;bsr.s	_cconws
	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp
	rts

_cconws:
	move.l	a0,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts

openerr:
	lea	openerrmsg(pc),a0
	jmp (a5)

readerr:
	jsr (a5)
	move	d6,-(sp)
	move	#62,-(sp)	; Fclose
	trap	#1
	addq.l	#4,sp
	move.l	#-1,d6
	rts
	
openfile:
	move.l	a0,-(sp)
	lea msg2(pc),a0
	bsr.s _cconws
	move.l (sp),a0
	bsr.s _cconws
	lea crlf(pc),a0
	bsr.s _cconws
	move.l (sp)+,a0

	clr -(sp)	; read
	move.l	a0,-(sp)
	move	#61,-(sp)	; Fopen
	trap	#1
	addq.l	#8,sp
	; d0 : file handle
	move	d0,d6
	bmi.s	openerr

	pea	auheader(pc)	; address
	pea 24.w		; len
	move	d6,-(sp) ; handle
	move	#63,-(sp) ; Fread
	trap	#1
	lea 12(sp),sp
	lea cannotreadheadermsg,a0
	cmpi.w	#24,d0
	bne.s	readerr

	lea msgmagic(pc),a0
	bsr.s _cconws
	lea magic(pc),a0
	bsr.s _cconws
	lea msgheadersize(pc),a0
	bsr.s _cconws
	move.l headersize(pc),d0
	bsr printwdec
	lea msgencoding(pc),a0
	bsr _cconws	
	move.l encoding(pc),d0
	bsr printwdec
	lea msgsamplerate(pc),a0
	bsr _cconws
	move.l samplerate(pc),d0
	bsr.s printwdec
	lea msgnchannels(pc),a0
	jsr (a5) ;bsr.s _cconws
	move.l nchannel(pc),d0
	bsr.s printwdec
	lea crlf(pc),a0
	jsr (a5) ;bsr.s _cconws

	move.l	encoding(pc),d0
	lea		encodingerrmsg,a0
	cmpi.l	#2,d0
	bne		readerr	

	move.l headersize(pc),d0
	subi.l #24,d0
	;bcs noinfo	; branch on carry set
	bls noinfo	; branch on lower than or same

	pea info(pc)
	move.l d0,-(sp)	; len
	move.w d6,-(sp) ; handle
	move.w #63,-(sp) ; Fread
	trap #1
	lea 12(sp),sp

	;bsr.s printwdec
	;lea crlf(pc),a0
	;jsr (a5) ;bsr.s _cconws

	lea info(pc),a0
printinfoloop:
	move.l a0,a1
lbl1:
	move.b (a1)+,d0
	beq	printinfoend
	cmpi.b	#$a,d0
	bne	lbl1
	move.b #0,-1(a1)
	move.l a1,-(sp)
	jsr (a5) ;bsr.s _cconws
	lea crlf(pc),a0
	jsr (a5) ;bsr.s _cconws
	move.l (sp)+,a0
	bra	printinfoloop
printinfoend:
	jsr (a5) ;bsr.s _cconws
	lea crlf(pc),a0
	jsr (a5) ;bsr.s _cconws

noinfo:

	rts

printwdec:
	lea printbufferend(pc),a0
printwdecloop:
	divu.w #10,d0
	move.w d0,-(sp)	;push quotient
	swap d0	; low word = reminder
	addi.w #48,d0 ; '0'
	move.b d0,-(a0)
	;move.w d0,-(sp)
	;move.w #2,-(sp)	; Cconout
	;trap #1
	;addq.l #4,sp
	moveq.l     #0,d0 ;sub.l d0,d0	; zero d0
	move.w (sp)+,d0	; pop quotient
	bne printwdecloop
	jmp (a5)	;bra _cconws
	;jsr (a5)
	;rts

printlhex:
	lea printbufferend(pc),a0
	lea hexdigits(pc),a1
	move.w #7,d2
printlhexloop:
	move.l d0,d1
	lsr.l #4,d0
	andi.l #$f,d1
	move.b (a1,d1),-(a0)
	dbra D2,printlhexloop
	;jmp (a5)
	bra _cconws

	; STE only !
setdmaaddrsub:	; set start/end address
	swap	d1
	move.b	d1,1(a0)	; hi byte
	swap	d1
	clr.l	d2
	move.b	d1,d2
	lsr.w	#8,d1
	move.b	d1,3(a0)	; mid byte
	move.b	d2,5(a0)	; low byte
	rts

setdma:
	clr.b    $FFFF8901.w;DMA OFF
	; SET DMA playback
	move.l   bufferp(pc),d1
	lea		$FFFF8902.w,a0
	bsr.s	setdmaaddrsub

	move.l   bufferp(pc),d1
	add.l	#buffersize*2,d1
	lea		12(a0),a0	;$FFFF890E.w,a0
	bsr.s	setdmaaddrsub

	move.l	samplerate(pc),d1
	move.l	#4096,d2	; rate <  8192 => play at  6258HZ (d0=0)
	move.b	#-1,d0		; rate < 16384 => play at 12517HZ (d0=1)
ratechooseloop:			; rate < 32768 => play at 25033HZ (d0=2)
	addi.b	#1,d0		; rate < 65536 => play at 50066HZ (d0=3)
	add.l	d2,d2
	cmp.l	d1,d2
	blt.s	ratechooseloop
	move.l	nchannel(pc),d1
	cmpi.b	#2,d1
	beq.s mono
	ori.b	#$80,d0		; set stereo bit
mono:
	move.b	d0,$FFFF8921.w

	;move.b  #1,$FFFF8901.w     * Start playback, single pass mode - stops at end
	move.b  #3,$FFFF8901.w     * Start playback, loop mode  - stops not self. Stop by resetting bit 0 .
	rts

getdmasoundpos:
	moveq	#0,d0
	move.b	$FFFF8909.w,d0	; high byte
	swap	d0
	move.b	$FFFF890B.w,d0	; mid byte
	lsl.w	#8,d0
	move.b	$FFFF890D.w,d0	; low byte
	rts

stopdmasound:
	clr.b    $FFFF8901.w;DMA OFF
	rts

get_cookie:
	move.l	$5a0.w,d0	; _p_cookies
	beq.s	gcknf
	move.l	d0,a0
gcknx:	move.l	(a0)+,d0	; cookie name
	beq.s	gcknf
	cmp.l	d6,d0
	beq.s	gckf
	addq.l	#4,a0
	bra.s	gcknx
gckf:	move.l	(a0)+,d0	; cookie value
	rts
gcknf:	moveq	#-1,d0
	rts

	; ---- data section
	data
hexdigits:
	dc.b	"0123456789abcdef"
msg1:
	dc.b	"STE .AU Player (c) 2016 nanard",$d,$a,0
msg2:
	dc.b	"Loading ",0
crlf:
	dc.b	$d,$a,0
cannotreadheadermsg:
	dc.b	"Failed to read header",$d,$a,0
encodingerrmsg:
	dc.b	"Only encoding 2 is supported : signed 8bits PCM",$d,$a,0
playmsg:
	dc.b	"Press any key to stop",$d,$a,0
endoffilemsg:
	dc.b	" End of file reached    ",$d,$a,0
lowbufread:
	dc.b	"  Low Half buffer played",$d,0
hibufread:
	dc.b	" High Half buffer played",$d,0
msgmagic:
	dc.b	$d,$a,"Magic:       ",0
msgheadersize:
	dc.b	$d,$a,"header size: ",0
msgencoding:
	dc.b	$d,$a,"encoding:    ",0
msgsamplerate:
	dc.b	$d,$a,"sample rate: ",0
msgnchannels:
	dc.b	$d,$a,"chan count:  ",0
;filename:
	;dc.b	"DEFAULT.AU",0
	;dc.b	"SURFIUSA.AU",0
	;dc.b	"GRANBLON.AU",0
	;dc.b	"EVRYBREA.AU",0
openerrmsg:
	dc.b	"Error opening file",$d,$a,0
stmsg:
	dc.b	"Sorry, only STE+ machines with DMA are",$d,$a,"supported.",$d,$a,0
printbuffer:
	dc.b	"00000000"
printbufferend:
	dc.b	0

	bss
bufferp:
	ds.l	1
auheader:
magic:
	ds.l	1	; '.snd'
headersize:
	ds.l	1
datasize:
	ds.l	1
encoding:
	ds.l	1	; 2 = 8-bit linear PCM
samplerate:
	ds.l	1
nchannel:
	ds.l	1

info:
	ds.b	2048

buffer:
buffer0:
	ds.b	buffersize
buffer1:
	ds.b	buffersize
