TARGET	= listacsi.tos

CC	= m68k-atari-mint-gcc
AS	= m68k-atari-mint-as
STRIP	= m68k-atari-mint-strip
PRGFLAGS= m68k-atari-mint-flags 
CFLAGS	= -Os -m68000 -fomit-frame-pointer -Wall -Wno-multichar
LDFLAGS	= -Wl,--traditional-format -lgcc

HDR	= $(wildcard *.h)
CSRC	= $(wildcard *.c) 
STARTUP	= startup.o

OBJS    = $(patsubst %.c,%.o,$(CRCS))

CFLAGS	+= -nostdlib -DSLIM 

OBJS	 = $(patsubst %.c,%.o,$(CSRC))

all:	$(TARGET)

$(TARGET): $(STARTUP) $(OBJS) $(HDR)
	$(CC) $(CFLAGS) -o $@ $(STARTUP) $(OBJS) $(LDFLAGS)
	$(STRIP) -s $@
	$(PRGFLAGS) $@ --mno-fastram --mno-fastalloc --mno-fastload 

#%.o: %.c 
#	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(TARGET) *~ *.o
