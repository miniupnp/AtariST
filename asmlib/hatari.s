; from http://dhs.nu/hatari/files/hatari.s
		section	text

;--- Hatari macros -------------------------------------

HatariDebuggerEnable	MACRO			; in: none
		move.w	#3,-(sp)
		move.w	#255,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM

HatariDebuggerDisable	MACRO			; in: none
		move.w	#4,-(sp)
		move.w	#255,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM

HatariMax	MACRO				; in: none
		move.w	#2,-(sp)
		move.w	#255,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM

HatariMin	MACRO				; in: none
		move.w	#1,-(sp)
		move.w	#255,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM
	
HatariDebug	MACRO				; in: memptr (.l) , length (.l)
		move.l	\2,-(sp)
		move.l	\1,-(sp)
		move.w	#254,-(sp)
		trap	#14
		add.l	#10,sp
		ENDM
	
HatariCyclesStart	MACRO			; in: cycle counter # (.w)
		move.w	\1,-(sp)
		move.w	#253,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM

HatariCyclesRead	MACRO			; in: cycle counter # (.w)
		move.w	\1,-(sp)
		move.w	#252,-(sp)
		trap	#14
		addq.l	#4,sp
		ENDM

HatariDebugUI	MACRO				; in: none
		move.w	#251,-(sp)
		trap	#14
		add.l	#2,sp
		ENDM

HatariRegisters	MACRO				; in: none
		move.w	#250,-(sp)
		trap	#14
		add.l	#2,sp
		ENDM
