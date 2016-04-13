AS=vasmm68k_mot
ASFLAGS=-Ftos -m68000 -no-fpu

all:	steauply.ttp

clean:
	$(RM) *.ttp

%.ttp:	%.s
	$(AS) $(ASFLAGS) -o $@ $^

