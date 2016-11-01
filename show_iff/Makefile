AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu

all:	show_iff.ttp

clean:
	$(RM) *.ttp *.tos

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $<

%.tos:	%.s
	$(AS) $(ASFLAGS) -o $@ $<

show_iff.ttp:	show_iff.s loadiff.s ../asmlib/printdec.s ../asmlib/loadfile.s
