COMMON_CFLAGS = -Ingiflib
COMMON_CFLAGS += -DNGIFLIB_INDEXED_ONLY
COMMON_CFLAGS += -DNGIFLIB_ENABLE_CALLBACKS

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

all:	show_gif.tos gshowgif.tos

clean:
	$(RM) $(OBJS) $(GCC_OBJS) show_gif.tos gshowgif.tos

show_gif.tos:	$(OBJS)
	$(CC) $(LDFLAGS) -final -o $@ $^ $(LDLIBS)

gshowgif.tos:	$(GCC_OBJS)
	$(GCC) $(GCCFLAGS) -Wl,--traditional-format -o $@ $^ $(LDLIBS)

show_gif.o:	show_gif.c ngiflib/ngiflib.h

%_gcc.o: %.c
	$(GCC) $(GCCFLAGS) -c -o $@ $<

%_gcc.o: %.s
	$(AS) $(GCC_ASFLAGS) -o $@ $<
