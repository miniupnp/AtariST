; (c) 2016 Thomas Bernard
;
; IFF image loader
; http://www.atari-wiki.com/?title=ST_Picture_Formats
;

	; CODE ENTRY POINT
	code

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

	move.l	4(sp),a0	; process basepage
	lea		128(a0),a0	; command line
	moveq	#0,d0
	move.b	(a0)+,d0	; command line length
	clr.b	(a0,d0.w)	; zero byte at end of command line

	move.l	a0,-(sp)
	bsr _cconws
	lea		crlf(pc),a0
	bsr _cconws
	move.l	(sp)+,a0

	bsr	loadfile
	move.w	d0,d7
	bmi.s	.fileerror

	bsr	printwdec

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	move.w    #0,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	lea	filebuffer(pc),a0
	move.l	physbase,a1
	lea	palette(pc),a2
	move.w	d7,d0
	bsr	loadiff

	pea	palette(pc)
	move.w	#6,-(sp)	; Setpalette
	trap	#14			; XBIOS
	addq.l	#6,sp

	bra	end

.fileerror:
	lea	.fileerrormsg(pc),a0
	bsr	_cconws

	data
.fileerrormsg
	dc.b	"loadfile error",$d,$a,0

	code

end:
	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	move.w    rezbackup,-(sp)    ; resolution (0=ST low, 1=ST Mid)
	move.l    physbase,-(sp)
	move.l    logbase,-(sp)
	move.w    #5,-(sp)     ; SetScreen
	trap      #14          ; XBIOS
	lea       12(sp),sp

	clr (sp)
	trap #1		; Pterm0

_cconws:
	move.l	a0,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts

	include '../asmlib/printdec.s'
	include '../asmlib/loadfile.s'
	include 'loadiff.s'

	data
crlf
	dc.b	$a,$d,0

	bss
	align	2
palette
	ds.w	16
rezbackup
	ds.w	1
logbase
	ds.l	1
physbase
	ds.l	1

filebuffer
	ds.b	32000