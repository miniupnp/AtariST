; nanard
; https://github.com/miniupnp/AtariST
; (peudo) random number generator for Atari ST
; http://www.atari-forum.com/viewtopic.php?t=1910
	code
rand:
	move.l #$a1b2c3d4,d0

	; this one need supervisor
	;ror.l	#8,d0
	;sub.w	$466.w,d0	;vsync counter
	;add.b	$ffff8209.w,d0	; video counter

	; no supervisor mode needed
	addq.l #5,d0
	rol.l d0,d0

	move.l d0,rand+2
	rts

;bss
;randseed:
;	ds.l	1
