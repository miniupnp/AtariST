COMMON_CFLAGS = -Ingiflib
COMMON_CFLAGS += -DNGIFLIB_INDEXED_ONLY
COMMON_CFLAGS += -DNGIFLIB_ENABLE_CALLBACKS
#COMMON_CFLAGS += -DSHOW_GIF_LOG

CC = vc +tos16
CFLAGS = -O1
CFLAGS += -sc
#CFLAGS += -sd
CFLAGS += -speed
CFLAGS += -maxoptpasses=20
#CFLAGS += -cpp-comments
CFLAGS += $(COMMON_CFLAGS)
CFLAGS += -k

GCC = m68k-atari-mint-gcc
GCCFLAGS = -O3
GCCFLAGS += -m68000
#GCCFLAGS += -mshort
GCCFLAGS += -Wall
GCCFLAGS += -fomit-frame-pointer
GCCFLAGS += $(COMMON_CFLAGS)

AS = vasmm68k_mot
ASFLAGS = -Fvobj
ASFLAGS += -m68000 -no-fpu

GCC_ASFLAGS = -Faout -m68000 -no-fpu -DLONGINTABI

#LDLIBS = -lm16 -lvc16
LDFLAGS = $(CFLAGS)
#LDFLAGS += -tos-textbased

OBJS = show_gif.o ngiflib/ngiflib.o c2p_4bit2.o
GCC_OBJS = $(subst .o,_gcc.o,$(OBJS))

BINS = show_gif.ttp gshowgif.tos

all:	$(BINS) floppy

floppy:	show_gif.st

clean:
	$(RM) $(OBJS) $(GCC_OBJS) $(BINS)

show_gif.st:	show_gif.ttp DESKTOP.INF.in *.gif
	$(RM) $@
	hmsa $@ DS
	for s in $^ ; do d=`echo $$s | sed 's/\.in$$//'` ; MTOOLS_NO_VFAT=1 mcopy -i $@ -v $$s ::$$d ; done

show_gif.tos:	$(OBJS)
	$(CC) $(LDFLAGS) -final -o $@ $^ $(LDLIBS)
	if which upx ; then upx --best $@ ; fi

show_gif.ttp:	$(OBJS)
	$(CC) $(LDFLAGS) -final -o $@ $^ $(LDLIBS)
	if which upx ; then upx --best $@ ; fi

gshowgif.tos:	$(GCC_OBJS)
	$(GCC) $(GCCFLAGS) -Wl,--traditional-format -o $@ $^ $(LDLIBS)

show_gif.o:	show_gif.c ngiflib/ngiflib.h

%_gcc.o: %.c
	$(GCC) $(GCCFLAGS) -c -o $@ $<

%_gcc.o: %.s
	$(AS) $(GCC_ASFLAGS) -o $@ $<
