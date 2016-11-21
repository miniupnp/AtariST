# 2016 Thomas BERNARD
#
# uses mtools package and hmsa tool from hatari to build floppy images
#
# $ apt-get install mtools hatari upx
#
# disasm :
#  m68k-atari-mint-objdump -b binary -m m68k -D bs1.bin
#
AS=vasmm68k_mot
ASFLAGS=-m68000 -no-fpu
CFLAGS=-Wall -O

.PHONY:	all floppy clean

all:	injectbs bs1.bin detect.bin

floppy:	bs1.msa detect.msa

%.st:	%.bin injectbs
	$(RM) $@
	hmsa $@ DS
	./injectbs $@ $<

%.msa:	%.st
	$(RM) $@
	hmsa $< || true

injectbs:	injectbs.o

clean:
	$(RM) *.ttp *.tos *.bin
	$(RM) *.o injectbs

%.ttp:	%.s
	$(AS) -Ftos $(ASFLAGS) -o $@ $<
	chmod +x $@

%.tos:	%.s
	$(AS) -Ftos $(ASFLAGS) -o $@ $<
	chmod +x $@

%.tos:	%.S
	$(AS) -Ftos $(ASFLAGS) -o $@ $<
	chmod +x $@

%.bin:	%.s
	$(AS) -Fbin $(ASFLAGS) -o $@ $<
