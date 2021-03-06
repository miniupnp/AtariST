; CosmosEx media player prototype for Atari ST/STE
; AUDIO support only
; (c) 2016 nanard

YM_USE_AUTOINTERRUPT	EQU 0  	;0=no auto interrupt, 1=use auto interrupt

;buffersize equ	32768
buffersize equ	65536
buffersectorcount	equ	buffersize/512
;buffersizecode equ	6
buffersizecode equ	7
flock	equ	$43e

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

	; CODE ENTRY POINT
	code

	lea msg(pc),a0
	bsr _cconws

	; make $10000 aligned buffer
	move.l	#buffer+$fffe,d0
	clr.w	d0
	move.l	d0,pbuffer

	; check sound hardware through _SND cookie
	move.l	#'_SND',d6
	supexec get_cookie
	cmp.l	#-1,d0
	beq	.use_ym
	btst #1,d0
	sne.b	use_ste_dma
.use_ym

	;sf.b	use_ste_dma	; force use of YM chip

	; set parameters
	lea	openparams,a4
	move.l	#'CEMP',(a4)+	; signature
	move.w	#1,(a4)+		; audio rate :
	tst.b	use_ste_dma
	beq.s	.ymparams
	;move.w	#25033,(a4)+	;   25033
	move.w	#50066,(a4)+	;   50066
	move.w	#2,(a4)+		; Force Mono :
	move.w	#0,(a4)+		;   false
	bra.s	.cont
.ymparams
	move.w	#20000,(a4)+	;   20000
	move.w	#2,(a4)+		; Force Mono :
	move.w	#1,(a4)+		;   true
.cont
	move.w	#$ff,(a4)+		; path / url

	; Build full file path for argument !
	;move	#47,-(sp)	; Fgetdta
	;trap	#1
	;addq.l	#2,sp
	;move.l	d0,a0		; dta / command line
	move.l	4(sp),a0	; process basepage
	lea	128(a0),a0	; command line
	moveq	#0,d0
	move.b	(a0)+,d0	; command line length
	clr.b	(a0,d0.w)	; zero byte at end of command line
	; look for \ in argument :
	movea.l	a0,a1
	move.l	a0,-(sp)	; push command line addr
	move.w	d0,-(sp)	; push command line length
.loop0:
	cmpi.b	#$5c,(a1)+	; 5c = '\'
.loopentry0:
	dbeq	d0,.loop0
	; d0=-1 => not found => relative path
	move.w	d0,-(sp)	; push relative/absolute flag
	bsr _cconws
	lea	crlf(pc),a0
	bsr _cconws

	move.l a4,a1
	move.w	(sp)+,d0	; pop relative/absolute flag
	bge		.absolute

	move.w	#25,-(sp)	; Dgetdrv
	trap	#1
	addq.l	#2,sp

	addi.b	#'A',d0
	move.b	d0,(a1)+
	move.b	#':',(a1)+
	move.w	#0,-(sp)	; default drive
	move.l	a1,-(sp)	; destination buffer
	move.w	#71,-(sp)	; Dgetpath
	trap	#1
	addq.l	#8,sp
.fwdloop:
	move.b	(a1)+,d0
	bne	.fwdloop
	subq.l	#1,a1		; back to the terminating null char
	cmpi.b	#'\',-1(a1)	; test last string character
	beq	.absolute
	move.b	#'\',(a1)+	; add anti-slash if needed

.absolute:
	move.w	(sp)+,d0	; pop command line length
	move.l	(sp)+,a0	; push command line addr
	bsr		nndmemcpy

	; fill buffer with easily recognizable data
	; to track transmission bugs :)
	lea		openparams+512,a0
.fillbuffer:
	addi.b	#1,d0
	move.b	d0,(a1)+
	cmp.l	a1,a0
	bne	.fillbuffer

	; now path is filled
	move.l	a4,a0
	bsr _cconws
	lea	crlf(pc),a0
	bsr _cconws

	supexec	openstream
	tst.w	d0
	beq.s	.openok
	; stop if the open failed
	bsr		printlhex
	bra		end

.openok
	; display info
	lea msgmagic(pc),a0
	bsr _cconws
	lea magic,a0
	bsr _cconws
	lea msgheadersize(pc),a0
	bsr _cconws
	move.l headersize,d0
	bsr printwdec
	lea msgencoding(pc),a0
	bsr _cconws	
	move.l encoding,d0
	bsr printwdec
	lea msgsamplerate(pc),a0
	bsr _cconws
	move.l samplerate,d0
	bsr printwdec
	lea msgnchannels(pc),a0
	bsr _cconws
	move.l nchannel,d0
	bsr printwdec

	move.l	datasize,d4
	bmi	.nolength
	lea playtime(pc),a0
	bsr _cconws
	move.l nchannel,d0
	cmpi.l #1,d0
	beq .ismono
	lsr.l #1,d4
.ismono:
	move.l	samplerate,d0
	divu.w	d0,d4
	moveq.l #0,d1
	move.w	d4,d1	; quotient = total seconds
	divu.w #60,d1
	move.w	d1,d0	; minutes
	bsr printwdec
	pea	$0002003a	; 0x3a=':'
	trap #1 		; Cconout
	addq.l #4,sp
	swap	d1
	move.w	d1,d0	; seconds
	bsr printwdec
	pea	$0002002e	; 0x2e='.'
	trap #1 		; Cconout
	addq.l #4,sp
	swap	d4		; samples reminder
	move.l	samplerate,d1
	;mulu.w	#100,d4		; to get 1/100th seconds
	mulu.w	#1000,d4	; to get milliseconds
	divu.w	d1,d4
	move.w	d4,d0
	bsr printwdec
.nolength:

	lea crlf(pc),a0
	bsr _cconws

	; check encoding ?
	;move.l	encoding(pc),d0
	;lea		encodingerrmsg,a0
	;cmpi.l	#2,d0
	;bne		readerr	

	move.l headersize,d0
	subi.l #24,d0
	bls .noinfo	; branch on lower than or same

	lea info,a0
.printinfoloop:
	move.l a0,a1
.lbl1:
	move.b (a1)+,d0
	beq	.printinfoend
	cmpi.b	#$a,d0
	bne	.lbl1
	move.b #0,-1(a1)
	move.w d0,-(sp)
	move.l a1,-(sp)
	bsr _cconws
	lea crlf(pc),a0
	bsr _cconws
	move.l (sp)+,a0
	move.w (sp)+,d0
	dbra d0,.printinfoloop
.printinfoend:
	bsr _cconws
	lea crlf(pc),a0
	bsr _cconws

.noinfo:

	lea	msgdma(pc),a0
	tst.b	use_ste_dma
	bne.s	.use_dma
	lea	msgym(pc),a0
.use_dma:
	bsr _cconws
	lea	msgplayback(pc),a0
	bsr _cconws

	; stream and play data

	; initial buffer fill
	supexec	fillbuffer0
	supexec	fillbuffer1

	lea	playmsg(pc),a0
	bsr _cconws

	tst.b	use_ste_dma
	bne.s	.initdma
.initym
	move.l 	pbuffer,ymplaypointer
	lea		replay_ym_tos_slow,a0
	;lea		replay_ym_tos_fast,a0

	;get replay entries (init,deinit,timer)
	move.l 	(a0)+,a1
	jsr 	(a1) 		;ym replay init - initialize _before_ reading the other pointers!
	movem.l (a0),a2-a3
	movem.l a1-a3,preplay_current

	supexec	yminit

	; MFP clock 2457600Hz
	; Interrupt frequency = 2457600 / divider / data
	; data * divider = 2457600 / frequency
	; data = 8bit (0 to 255)
	; divider =  %001 => 4, %010 => 10, %011 => 16
	;     %100 => 50, %101 => 64, %110 => 100, %111 => 200

	move.l	#2457600/4,d0
	move.l	samplerate,d1
	divu.w	d1,d0

	move.l 	preplay_current_timer,-(sp) ; vector
	move.w	d0,-(sp)	; data = count
	move.w	#%0001,-(sp)	;Delay mode, divide by 4
	move.w	#0,-(sp)	; Timer A
	move.w  #31,-(sp)	; Xbtimer
	trap    #14			; Call XBIOS
	lea		12(sp),sp

	lea		buffer0,a0
	move.l	#buffersize,d0
	add.l	a0,d0
	move.l	a0,ymbuffcurrent
	move.l	d0,ymbuffend

	move.w	#13,-(sp)	; Timer A
	move.w	#27,-(sp)	; Jenabint
	trap	#14			; Call XBIOS
	addq.l	#4,sp

	bra	mainloop

.initdma
	supexec	setdma

	lea	buffer1,a0
	move.l	a0,d5

mainloop:
	move.w	#11,-(sp)	; Cconis
	trap	#1
	addq.l	#2,sp
	tst.w	d0	; DEV_READY (-1) if char is available / DEV_BUSY (0) if not
	bne		stop

	supexec	getdmasoundpos
	cmp.l	d0,d5
	bge	mainloop

	bsr printlhex
	lea lowbufread(pc),a0
	bsr _cconws

	supexec fillbuffer0
	;bsr printlhex
	tst.b	d0
	bne	endoffile

waitloop2:
	move.w	#11,-(sp)	; Cconis
	trap	#1
	addq.l	#2,sp
	tst.w	d0
	bne.s	stop

	supexec	getdmasoundpos

	cmp.l	d0,d5
	blt		waitloop2

	bsr printlhex
	lea hibufread(pc),a0
	bsr _cconws

	supexec fillbuffer1
	tst.b	d0
	beq	mainloop

endoffile:
	lea	endoffilemsg(pc),a0
	bsr _cconws

	; TODO : wait until end of file is played.

stop:
	supexec	stopdmasound
	lea	stoppedmsg(pc),a0
	bsr _cconws

	; close stream
	supexec closestream
	bsr printlhex

end:
	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	clr (sp)
	trap #1		; Pterm0
	; -------------------------

_cconws:
	move.l	a0,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts

printwdec:
	lea printbufferend(pc),a0
printwdecloop:
	divu.w #10,d0
	move.w d0,-(sp)	;push quotient
	swap d0	; low word = reminder
	addi.w #48,d0 ; '0'
	move.b d0,-(a0)
	moveq.l     #0,d0 ;sub.l d0,d0	; zero d0
	move.w (sp)+,d0	; pop quotient
	bne printwdecloop
	bra _cconws

printlhex:
	lea printbufferend(pc),a0
	lea hexdigits(pc),a1
	move.w #7,d2
.printlhexloop:
	move.l d0,d1
	lsr.l #4,d0
	andi.l #$f,d1
	move.b (a1,d1.w),-(a0)
	dbra d2,.printlhexloop
	bra _cconws

	; arguments : a0=source a1=destination d0=count
nndmemcpyloop:
	move.b	(a0)+,(a1)+
nndmemcpy:
	dbra	d0,nndmemcpyloop
	rts

	; acsi related functions
fillbuffer0:
	lea	buffer0,a1
	bra	fillbuffer
fillbuffer1:
	lea	buffer1,a1
fillbuffer:
	move.l	a1,d1
	lea acsicmd(pc),a0
	move.b	#3,4(a0)	; command readStream
	move.b	streamid,d0
	ori.b	#32*buffersizecode,d0
	move.b	d0,5(a0)	; stream id + buffer size
	move.w	#buffersectorcount,d2
	moveq	#0,d3	; read
	bra	sendacsicmd

closestream:
	lea	acsicmd(pc),a0
	move.b	#4,4(a0)	; command closeStream
	move.b	streamid,5(a0)	; stream id
	bsr	sendacsicmdnodma

	; open media stream
openstream:
	lea	acsicmd(pc),a0
	lea	openparams,a1
	move.l	a1,d1
	moveq	#1,d2		; sector count
	move.w	#$100,d3	; write
	bsr	sendacsicmd
	btst	#7,d0		; is it signed ?
	bne		.return
	move.b	d0,streamid		; backup stream id

	; wait 2 second
	move.l	$4ba,d0		; 200 Hz System clock
	addi.l	#200*2,d0
.waitloop
	cmp.l	$4ba,d0
	bcc		.waitloop

	lea	acsicmd(pc),a0
	move.b	#2,4(a0)	; command getStreamInfo
	move.b	streamid,5(a0)	; stream id
	lea	infoheader,a1
	move.l	a1,d1
	moveq	#1,d2		; sector count
	moveq	#0,d3		; read
	bsr	sendacsicmd
	btst	#7,d0		; is it signed ?
	bne		.return

	; wait 1 second
	move.l	$4ba,d0		; 200 Hz System clock
	addi.l	#200,d0
.waitloop2
	cmp.l	$4ba,d0
	bcc		.waitloop2

	moveq.l	#0,d0		; ok
.return
	rts


	; ===================== ACSI/DMA =======================
	; sendacsicmd a0 = cmd
	;             d1 = buffer address
	;             d2 = sector count
	;             d3 = 0=read/$100=write
	; read/write flag
sendacsicmd:
.waitflock
	tst.w	flock
	bne.s	.waitflock
	st	flock

	; set dma address
	lea		$ffff8609.w,a2	; DMA ADDR (high)
	move.b	d1,4(a2)		; low byte
	lsr.w	#8,d1
	move.b	d1,2(a2)		; middle byte
	swap	d1
	move.b	d1,(a2)			; high byte

	lea		$ffff8604,a2	; DMA DATA

	move.w	#$88,2(a2)		; DMA MODE <= NO_DMA | HDC
	move.b	(a0)+,d0		; cmd[0]
	move.w	d0,(a2)
	move.w	#$8a,2(a2)		; DMA MODE <= NO_DMA | HDC | A0

	moveq	#3,d1			; 4 next command bytes !
.sendcmdloop:
	move.b	(a0)+,d0
	swap	d0
	move.b	#$8a,d0			; DMA MODE <= NO_DMA | HDC | A0
	move.l	d0,(a2)			; DMA DATA + DMA MODE
	bsr.s	waitdma
	bmi.s	.timeout
	dbra	d1,.sendcmdloop

	;move.w	#$090,2(a2)		; DMA_MODE <=          NO_DMA | SC_REG
	;move.w	#$190,2(a2)		; DMA_MODE <= DMA_WR | NO_DMA | SC_REG
	move.w	d3,d0
	bchg	#8,d0
	ori.w	#$090,d0
	move.w	d0,2(a2)		; DMA_MODE <= !wr_flag | NO_DMA | SC_REG
	bchg	#8,d0
	move.w	d0,2(a2)		; DMA_MODE <=  wr_flag | NO_DMA | SC_REG
	move.w	d2,(a2)			; sector count
	;move.w	#$18a,2(a2)		; DMA_MODE <= DMA_WR | NO_DMA | HDC | A0
	move.w	d3,d0
	ori.w	#$08a,d0
	move.w	d0,2(a2)		; DMA_MODE <=  wr_flag | NO_DMA | HDC | A0

	move.b	(a0)+,d0
	swap	d0
	;move.w	#$100,d0		; DMA MODE <= DMA_WR (start DMA transfer)
	move.w	d3,d0			; DMA MODE <=  wr_flag (start DMA transfer)
	move.l	d0,(a2)			; DMA DATA + DMA MODE

	move.w	#32000,d0
	bsr.s	waitdma2
	;move.w	#$18a,2(a2)	; DMA MODE <= DMA_WR | NO_DMA | HDC | A0
	ori.w	#$08a,d3
	move.w	d3,2(a2)	; DMA MODE <=  wr_flag | NO_DMA | HDC | A0
	move.w	(a2),d1		; read status
	;bsr.s	waitdma
.timeout:
	move.w	#$80,2(a2)		; NO_DMA
	clr.w	flock
	moveq	#0,d0
	move.w	d1,d0
	rts

waitdma:
	move.w	#15000,d0
waitdma2:
	lea		$fffffa01.w,a3
.waitdmaloop:
	btst	#5,(a3)
	btst	#5,(a3)
	btst	#5,(a3)
	btst	#5,(a3)
	beq		.waitdmaend
	dbra	d0,.waitdmaloop
.waitdmaend
	rts

	; ===================== ACSI/DMA =======================
	; sendacsicmdnodma a0 = cmd
sendacsicmdnodma:
.waitflock
	tst.w	flock
	bne.s	.waitflock

	lea		$ffff8604,a2	; DMA DATA

	move.w	#$88,2(a2)		; DMA MODE <= NO_DMA | HDC
	move.b	(a0)+,d0		; cmd[0]
	move.w	d0,(a2)
	move.w	#$8a,2(a2)		; DMA MODE <= NO_DMA | HDC | A0

	moveq	#3,d1			; 4 next command bytes !
.sendcmdloop:
	move.b	(a0)+,d0
	swap	d0
	move.b	#$8a,d0			; DMA MODE <= NO_DMA | HDC | A0
	move.l	d0,(a2)			; DMA DATA + DMA MODE
	bsr.s	waitdma
	bmi.s	.timeout
	dbra	d1,.sendcmdloop

	; last byte
	move.b	(a0)+,d0		; cmd[5]
	move.w	d0,(a2)
	move.w	#$0a,2(a2)		; DMA MODE <= HDC | A0
	bsr.s	waitdma

	move.w	#$8a,2(a2)		; DMA MODE <= NO_DMA | HDC | A0
	move.w	(a2),d1		; read status
	;bsr.s	waitdma
.timeout:
	move.w	#$80,2(a2)		; NO_DMA
	clr.w	flock
	moveq	#0,d0
	move.w	d1,d0
	rts




	; =================== DMA SOUND (STE+ ONLY) =================
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
	;move.l   bufferp(pc),d1
	lea		buffer,a1
	move.l	a1,d1
	lea		$FFFF8902.w,a0	; start address
	bsr.s	setdmaaddrsub

	;move.l   bufferp(pc),d1
	move.l	a1,d1
	add.l	#buffersize*2,d1
	lea		12(a0),a0	;$FFFF890E.w,a0	; end address
	bsr.s	setdmaaddrsub

	move.l	samplerate,d1
	move.l	#4096,d2	; rate <  8192 => play at  6258HZ (d0=0)
	move.b	#-1,d0		; rate < 16384 => play at 12517HZ (d0=1)
ratechooseloop:			; rate < 32768 => play at 25033HZ (d0=2)
	addi.b	#1,d0		; rate < 65536 => play at 50066HZ (d0=3)
	add.l	d2,d2
	cmp.l	d1,d2
	blt.s	ratechooseloop
	move.l	nchannel,d1
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


	; ----- YM -----
yminit:
	moveq	#10,d0
.yminitloop:
	move.b	d0,$ffff8800.w
	clr.b	$ffff8802.w
	dbra	d0,.yminitloop
	move.b	#7,$ffff8800.w
	;move.b	#%11111111,$ffff8802.w
	move.b	$ffff8800.w,d0
	ori.b	#%00111111,d0
	move.b	d0,$ffff8802.w

	move.l  $114.w,save114 		;save 200 Hz timer
	move.l 	#emptyirq,$114.w 	;empty 200Hz timer
	IFNE YM_USE_AUTOINTERRUPT
	bclr 	#3,$ffFFFA17.w 		;enable autointerrupt
	ENDC
	rts

emptyirq:
	rte

	; back to silence
ymstop:
	move.l 	#$0700F800,$ffff8800.w
	move.l 	#$08000000,$ffff8800.w
	move.l 	#$09000000,$ffff8800.w
	move.l 	#$0A000000,$ffff8800.w

	move.l 	save114,$114.w 	;restore 200Hz timer
	IFNE YM_USE_AUTOINTERRUPT
	bset 	#3,$ffFFFA17.w 		;disable autointerrupt
	ENDC
	rts

	; ------ includes -----
	include "../asmlib/getcooki.s"
replay_ym_tos_slow:
	include "../ym_digit/replays/ym_tos_slow.s"
replay_ym_tos_fast:
	include "../ym_digit/replays/ym_tos_fast.s"



	; ------ DATA ----------
	data
playmsg:
	dc.b	"Press any key to stop",$d,$a,0
stoppedmsg:
	dc.b	"Playback stopped",$d,$a,0
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
	dc.b	" bytes",$d,$a,"encoding:    ",0
msgsamplerate:
	dc.b	$d,$a,"sample rate: ",0
msgnchannels:
	dc.b	" Hz",$d,$a,"chan count:  ",0
playtime:
	dc.b	$d,$a,"duration:    ",0

hexdigits:
	dc.b	"0123456789abcdef"
printbuffer:
	dc.b	"00000000"
printbufferend:
	dc.b	0
msgdma:
	dc.b	"Using STE DMA Sound",0
msgym:
	dc.b	"Using YM2149F for",0
msgplayback:
	dc.b	" playback",$d,$a,0
msg:
	dc.b	"CosmosEx Media Player (prototype)"
crlf:
	dc.b	$d,$a,0
acsicmd:
	dc.b	$60,"CE",6,1,0

ymplaypointer:
	ds.l 	1
ymvolumetable:
	include	"../ym_digit/ymtable.s"


	; --- BSS ---
	bss
use_ste_dma:
	ds.b	1
streamid:
	ds.b	1

	align 2
preplay_current:
preplay_current_init:
	ds.l 	1
preplay_current_deinit:
	ds.l 	1
preplay_current_timer:
	ds.l 	1

save114:
	ds.l 	1
ymbuffcurrent:
	ds.l	1
ymbuffend:
	ds.l	1
ymbuffnext:
	ds.l	1
ymbuffnextend:
	ds.l	1
currentbuffer:
	ds.w	1
functiontocall:
	ds.l	1

pbuffer:
	ds.l	1
openparams:
	ds.b	512
infoheader:
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
	ds.b	512-24

	align 2
buffer:
buffer0:
	ds.b	buffersize
buffer1:
	ds.b	buffersize

	ds.b 	$10000 		;space for buffer alignment
