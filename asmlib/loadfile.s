; (c) 2016 Thomas Bernard
; https://github.com/miniupnp/AtariST

	code
;	load a file
;	a0 = file name
;	a1 = buffer pointer (a least 32000 bytes)

loadfile
	move.l	a1,-(sp)	; PUSH buffer pointer
	move.w	#0,-(sp)	; read-only
	move.l	a0,-(sp)	; fname
	move.w	#61,-(sp)	; Fopen
	trap	#1			; GEMDOS
	addq.l	#8,sp

	tst.l	d0
	bmi.s	.openerror

	; buffer pointer already on stack
	move.l	#32000,-(sp)	; count   4
	move.w	d0,-(sp)		; handle  6
	move.w	#63,-(sp)		; Fread   8
	trap	#1				; GEMDOS
	move.w	d0,4(sp)		; save byte count
	move.w	#62,(sp)		; Fclose
	trap	#1				; GEMDOS
	move.w	4(sp),d0		; restore byte count
	addq.l	#8,sp

.openerror
	addq.l	#4,sp		; POP buffer pointer
	rts
	
