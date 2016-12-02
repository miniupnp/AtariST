CC = vc +tos16
CFLAGS = -O
CFLAGS += -sc
#CFLAGS += -sd
CFLAGS += -speed
CFLAGS += -maxoptpasses=20
CFLAGS += -DNGIFLIB_INDEXED_ONLY
CFLAGS += -cpp-comments
CFLAGS += -Ingiflib
#LDLIBS = -lm16 -lvc16
LDFLAGS = $(CFLAGS)
#LDFLAGS += -tos-textbased

all:	show_gif.tos

clean:
	$(RM) *.o ngiflib/ngiflib.o show_gif.tos

show_gif.tos:	show_gif.o ngiflib/ngiflib.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
