# 2016 Thomas BERNARD
#
# uses mtools package and hmsa tool from hatari to build floppy images
# uses upx to pack ATARI TOS executables
#
# $ apt-get install mtools hatari upx
#
AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu
PACKER=upx

.PHONY:	all floppy clean

all:	the_80s.tos PLAY_VBL.tos

floppy:	the_80s.msa

the_80s.st:	the_80s.tos FILE_ID.DIZ knight6.iff \
			../bootsector/detect.bin
	$(RM) $@
	hmsa $@ DS
	MTOOLS_NO_VFAT=1 mmd -i $@ ::AUTO
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v $< ::/AUTO/THE_80S.PRG
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v pictures/*.iff ::
	MTOOLS_NO_VFAT=1 mcopy -i $@ -v $^ ::
	../bootsector/injectbs $@ ../bootsector/detect.bin

../bootsector/detect.bin:	../bootsector/detect.s
	$(MAKE) -C ../bootsector detect.bin injectbs

%.msa:	%.st
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

the_80s.tos:	the_80s.s ../show_iff/loadiff.s \
	../asmlib/loadfile.s \
	../asmlib/getcooki.s
