; (c) 2016 Thomas BERNARD
; https://github.com/miniupnp/AtariST
;
; Atari ST/STE/TT/Falcon Boot sector

	code

start
	lea	msg(pc),a0
	bsr.s	cconws

	move.l	$5a0.w,d0
	beq.s	.nocookie
	move.l	d0,a0
.loop
	move.l	(a0)+,d0	; cookie signature
	beq.s	.nocookie
	move.l	(a0)+,d1	; cookie data
	cmp.l	#"_MCH",d0
	bne.s	.loop
.mchfound
	swap	d1
	dbra	d1,.nost
.nocookie
.st
	lea		msgst(pc),a0
	bra.s	end
.nost
	dbra	d1,.noste
.ste
	btst.l	#20,d1
	bne.s	.megaste
	lea		msgste(pc),a0
	bra.s	end
.megaste
	lea		msgmste(pc),a0
	bra.s	end
.noste
	dbra	d1,.nott
.tt
	lea		msgtt(pc),a0
	bra.s	end
.nott
	dbra	d1,.nofalcon
.falcon
	lea		msgfalcon(pc),a0
	bra.s	end

.nofalcon
	; unknown
	lea		msgunknown(pc),a0

end
	bsr.s	cconws

	lea	msgstram(pc),a0
	bsr.s	cconws

	move.l	$42e,d0		; phystop     Physical RAM top
	lsr.l	#5,d0		; bytes to kilo-bytes
	lsr.l	#5,d0		; bytes to kilo-bytes
	bsr.s	printwdec

	lea	msgkb(pc),a0
	;bsr.s	cconws

	;move.w	#7,-(sp)	; Crawcin
	;trap	#1			; GEMDOS
	;addq.l	#2,sp

	;rts

cconws
	move.l	a0,-(sp)
	move.w	#9,-(sp)	; CConws
	trap	#1			; GEMDOS
	addq.l	#6,sp
	rts
	
printwdec
	clr.w	-(sp)
.loop
	divu.w	#10,d0
	swap	d0
	add.w	#'0',d0
	move.w	d0,-(sp)
	clr.w	d0
	swap	d0
	tst.w	d0
	bne.s	.loop
.printloop
	tst.w	(sp)
	beq.s	.end
	move.w	#2,-(sp)	; Cconout
	trap	#1			; GEMDOS
	addq.l	#4,sp
	bra.s	.printloop
.end
	addq.l	#2,sp
	rts

msg
	dc.b	'Machine : ',0
msgst
	dc.b	'ST',0
msgste
	dc.b	'STe',0
msgmste
	dc.b	'MegaSTE',0
msgtt
	dc.b	'TT',0
msgfalcon
	dc.b	'Falcon',0
;msgct60
;	dc.b	'Falcon CT60',0
msgunknown
	dc.b	'Unknown',0
msgstram
	dc.b	'   ST RAM : ',0
msgkb
	dc.b	'kB',13,10,0
;crlf
;	dc.b	13,10,0
