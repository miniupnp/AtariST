AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu
PACKER=upx

all:	the_80s.tos PLAY_VBL.tos

clean:
	$(RM) *.ttp *.tos

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $<

%.tos:	%.s
	$(AS) $(ASFLAGS) -o $@ $<
	$(PACKER) $@
	chmod +x $@

%.tos:	%.S
	$(AS) $(ASFLAGS) -o $@ $<
	$(PACKER) $@
	chmod +x $@

the_80s.tos:	the_80s.s ../show_iff/loadiff.s ../asmlib/loadfile.s
