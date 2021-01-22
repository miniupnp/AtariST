CFLAGS=-Wall
LDLIBS=-lm

AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu

all:	stmusic.ttp

clean:
	$(RM) *.o *.ttp

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $<
