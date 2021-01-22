; (c) 2011 nanard
; https://github.com/miniupnp/AtariST

	; MACRO(S) DEFINITION(S)
	macro supexec		; 1 argument : subroutine address
	movem.l d0-a6,-(sp)
	pea		\1(pc)
	move	#38,-(sp)	; Supexec
	trap	#14			; XBIOS
	addq.l	#6,sp
	movem.l (sp)+,d0-a6
	endm

	; CODE ENTRY POINT
	code

	move.w #$2222,d2
	move.w #$3333,d3
	move.w #$4444,d4
	move.w #$5555,d5
	move.w #$6666,d6
	move.w #$7777,d7
	supexec play_do

	bsr presskey
	clr -(sp)
	trap #1		;Pterm0

presskey:
	;lea	presskey_txt(pc),a0
	;bsr.s	_cconws
	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp
	rts


play_do:
	moveq #7,d0
	move.w #%11111000,d1	; enable sound / disable noise on all channels
	bsr ym_write_reg
	clr.w d0	; channel 0
	move.w #60,d1	; do
	move.w #15,d2	; maximum volume
	bsr setnote
	moveq #1,d0	; channel 1
	move.w #62,d1	; re
	move.w #15,d2	; maximum volume
	;bsr setnote
	moveq #2,d0	; channel 2
	move.w #64,d1	; mi
	move.w #15,d2	; maximum volume
	; bra setnote

	; input :
	; d0 : Channel 0,1,2
	; a0 : Note 0-127
	; d2 : level 0-15
setnote:
	lea ym_midi_notes(pc),a0
	add.w d1,d1
	move.w (a0,d1.w),d1
	move.w d0,-(sp)
	add.w d0,d0
	bsr ym_write_reg	; R0,R2,R4 : 8 bit fine tone adjustment
	lsr.w #8,d1
	addq #1,d0
	bsr ym_write_reg	; R1,R3,R5 : 4 bit rough tone adjustment
	move.w (sp)+,d0
	addq #8,d0
	move.w d2,d1
	; bra ym_write_reg	; R8,R9,RA : volume level

	; d0 = register #
	; d1 = data
ym_write_reg:
	move.b	d0,$ffff8800.w
	move.b	d1,$ffff8802.w
	rts

	; DATA SECTION
	data

	include "ymnotes.s"
