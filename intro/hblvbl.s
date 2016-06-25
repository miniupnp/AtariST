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

	supexec install

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp

	supexec uninstall

	clr -(sp)
	trap #1		;Pterm0

	; subroutines :
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
	move.w	#$0FFF,$FFFF8240	;	white
	rts

vbl:
	move.l	#hbl,$120
	move.l	d0,-(sp)
	move.b	#200,d0
	sub.b	count,d0
	sub.b	count,d0
	move.b	d0,count2
	move.b 	#0,$fffffa1b.w 	;Timer stop
	cmpi.b	#100,count
	bge.s	.allscreen
	move.b 	count,$fffffa21.w 	;Counter value
	move.b 	#8,$fffffa1b.w 	;Timer start
	addq.b	#1,count
.allscreen:
;	move.w	#$0FFF,$FFFF8240	;	white
	move.w	#$0000,$FFFF8240	;	black
	move.l	(sp)+,d0
oldvbl:
	jmp	$0.l

hbl:
	move.w	#$0FFF,$FFFF8240	;	white
	move.l	#hbl2,$120
	move.b 	#0,$fffffa1b.w 	;Timer stop
	move.b 	count2,$fffffa21.w 	;Counter value
	move.b 	#8,$fffffa1b.w 	;Timer start
	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	rte

hbl2:
	move.w	#$0000,$FFFF8240	;	black
	bclr 	#0,$fffffa0f.w 	; acknowledge interrupt
	rte

	; ---- data section
	data
msgkey:
	dc.b	"Press any key",$d,$a,0

	bss
count:
	ds.b	1
count2:
	ds.b	1
