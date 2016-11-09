; https://github.com/miniupnp/AtariST

	code

	; parameter is in d6 (cookie name)
get_cookie
	move.l	$5a0.w,d0	; _p_cookies
	beq.s	.notfound
	move.l	d0,a0
.next
	move.l	(a0)+,d1	; cookie name
	beq.s	.notfound
	move.l	(a0)+,d0	; cookie value
	cmp.l	d6,d1
	bne.s	.next
	rts
.notfound
	moveq.l	#-1,d0
	rts
