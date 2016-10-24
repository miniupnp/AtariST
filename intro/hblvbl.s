; (c) 2016 nanard
; https://github.com/miniupnp/AtariST
;
; Fade the screen to black using HBL (timer B) interrupt

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	endm

	; CODE ENTRY POINT
	code

	move.l	#msgkey,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp

	supexec	backuppalette
	supexec install

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	supexec uninstall
	supexec	restorepalette

	clr -(sp)
	trap #1		;Pterm0

	; subroutines :
backuppalette:
	lea	$ffff8240.w,a0
	lea palettebackup(pc),a1
cpypal:
	move.w	#15,d0
.palcpyloop:
	move.w	(a0)+,(a1)+
	dbra	d0,.palcpyloop
	rts

restorepalette:
	lea	palettebackup(pc),a0
	lea	$ffff8240.w,a1
	bra.s	cpypal

install:
	move.l	#hbl,$120
	or.b 	#1,$fffffa07.w 	;enable Timer B
	or.b 	#1,$fffffa13.w
	move.l	$70,oldvbl+2
	move.l	#vbl,$70
	move.b 	#0,$fffffa1b.w 	;Timer B stop
	rts

uninstall:
	move.l	oldvbl+2,$70
	move.b 	#0,$fffffa1b.w 	;Timer B stop
	rts

vbl:
	move.l	#hbl,$120
	move.l	d0,-(sp)
	move.b	#200,d0
	sub.b	count,d0
	sub.b	count,d0
	move.b	d0,count2
	move.l	(sp)+,d0
	move.b 	#0,$fffffa1b.w 	;Timer stop
	cmpi.b	#100,count
	bge.s	.allscreen
	move.b 	count,$fffffa21.w 	;Counter value
	move.b 	#8,$fffffa1b.w 	;Timer start
	addq.b	#1,count
.allscreen:
;	move.w	#$0FFF,$FFFF8240	;	white
;	move.w	#$0000,$FFFF8240	;	black
oldvbl:
	jmp	$0.l

hbl:
	movem.l	d0/a0-a1,-(sp)
	lea	palettebackup(pc),a0
	move	#$FFFF8240,a1
	move.w	#7,d0
.cpyloop:
	move.l	(a0)+,(a1)+		; copy palettes entry 2 by 2
	dbra	d0,.cpyloop
	movem.l	(sp)+,d0/a0-a1
	move.l	#hbl2,$120
	move.b 	#0,$fffffa1b.w 	;Timer stop
	move.b 	count2,$fffffa21.w 	;Counter value
	move.b 	#8,$fffffa1b.w 	;Timer start
	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	rte

hbl2:
	move.l	d0,-(sp)
	moveq	#0,d0				; black
	move.l	d0,$FFFF8240.w	; color 0 & 1
	move.l	d0,$FFFF8244.w	;   "   2 & 3
	move.l	d0,$FFFF8248.w	;   "   4 & 5
	move.l	d0,$FFFF824c.w	;   "   6 & 7
	move.l	d0,$FFFF8250.w	;   "   8 & 9
	move.l	d0,$FFFF8254.w	;   "  10 & 11
	move.l	d0,$FFFF8258.w	;   "  12 & 13
	move.l	d0,$FFFF825c.w	;   "  14 & 15
	move.l	(sp)+,d0
	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	rte

	; ---- data section
	data
msgkey:
	dc.b	"Press any key",$d,$a,0

	bss
palettebackup:
	ds.w	16
count:
	ds.b	1
count2:
	ds.b	1
