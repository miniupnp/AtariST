CFLAGS=-Wall
LDLIBS=-lm

AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu

all:	generate_levels stauplay.ttp

clean:
	$(RM) *.o *.ttp generate_levels

generate_levels:	generate_levels.o

ymtable.s:	generate_levels
	./$< $@

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $<

stauplay.ttp:	stauplay.s ymtable.s
