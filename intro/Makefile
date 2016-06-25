AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu

all:	hblvbl.tos

clean:
	$(RM) *.ttp *.tos

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $^

%.tos:	%.s
	$(AS) $(ASFLAGS) -o $@ $^
