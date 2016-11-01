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

	move.w	#0,-(sp)	; read-only
	move.l	a0,-(sp)	; fname
	move.w	#61,-(sp)	; Fopen
	trap	#1			; GEMDOS
	addq.l	#8,sp

	tst.l	d0
	bmi.s	.openerror

	pea	filebuffer			; buf
	move.l	#32000,-(sp)	; count
	move.w	d0,-(sp)		; handle
	move.w	#63,-(sp)		; Fread
	trap	#1				; GEMDOS
	move.w	d0,d7
	move.w	#62,(sp)		; Fclose
	trap	#1				; GEMDOS
	lea		12(sp),sp

	move.w	d7,d0
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

.openerror:
	lea	.openerrormsg(pc),a0
	bsr	_cconws

	data
.openerrormsg
	dc.b	"Fopen error",$d,$a,0

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
	include 'loadiff.s'

	data
crlf
	dc.b	$a,$d,0

	bss
	align	2
filebuffer
	ds.b	32000

	align	2
palette
	ds.w	16
rezbackup
	ds.w	1
logbase
	ds.l	1
physbase
	ds.l	1
