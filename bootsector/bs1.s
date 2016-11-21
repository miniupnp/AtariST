;
	code

	pea	msg(pc)
	move.w	#9,-(sp)	; CConws
	trap	#1			; GEMDOS
	addq.l	#6,sp

	move.w	#7,-(sp)	; Crawcin
	trap	#1			; GEMDOS
	addq.l	#2,sp

	rts
msg
	dc.b	'Hello world!',13,10,0
