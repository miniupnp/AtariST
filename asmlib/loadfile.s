; (c) 2016 Thomas Bernard
; https://github.com/miniupnp/AtariST

	code
;	load a file
;	a0 = file name
loadfile
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
	move.w	d0,10(sp)
	move.w	#62,(sp)		; Fclose
	trap	#1				; GEMDOS
	lea		10(sp),sp
	move.w	(sp)+,d0

.openerror
	rts
	
