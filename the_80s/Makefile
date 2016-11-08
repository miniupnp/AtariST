AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu
PACKER=upx

.PHONY:	all floppy clean

all:	the_80s.tos PLAY_VBL.tos

floppy:	the_80s.msa

the_80s.st:	the_80s.tos FILE_ID.DIZ knight6.iff
	$(RM) $@
	hmsa $@ DS
	MTOOLS_NO_VFAT=1 mmd -i $@ ::AUTO
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v $< ::/AUTO/THE_80S.PRG
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v $^ ::
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v pictures/*.iff ::

the_80s.msa:	the_80s.st
	$(RM) $@
	hmsa $< || true

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
