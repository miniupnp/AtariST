/* TOS .prg/.tos/.ttp/etc. Executable display
 * (c) 2016 Thomas Bernard
 *
 * References :
 * http://cd.textfiles.com/ataricompendium/BOOK/HTML/CHAP2.HTM#processes
 */
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

/* read integers from a big endian buffer */
#define READWORD(p)	((p)[0] << 8 | (p)[1])
#define READLONG(p)	((p)[0] << 24 | (p)[1] << 16 | (p)[2] << 8 | (p)[3])

#define BYTE	uint8_t
#define WORD	uint16_t
#define LONG	uint32_t

#ifndef MIN
#define MIN(a,b) ((a)>(b)?(b):(a))
#endif

void printhexdump(const BYTE * data, unsigned long offset, unsigned long len)
{
	unsigned int i;
	while(len > 0) {
		printf("%06lx", offset & ~15);
		for(i = offset & 15; i > 0; i--) printf("   ");
		i = 0;
		do {
			printf(" %02x", data[offset+i]);
			i++;
		} while(((i + offset) & 15) && (i<len));
		while((i + offset) & 15) {
			printf("   ");
			i++;
		}
		printf(" | ");
		for(i = offset & 15; i > 0; i--) putchar(' ');
		do {
			putchar(data[offset+i] < 32 || data[offset+i] >= 127 ? '.' : data[offset+i]);
			i++;
		} while(((i + offset) & 15) && (i < len));
		putchar('\n');
		offset += i;
		len -= i;
	}
}

int parse_symbols(const BYTE * symbols, unsigned long symbolsize)
{
	printhexdump(symbols, 0, symbolsize);
	return 0;
}

int parse_fixups(const BYTE * fixups, unsigned long fixupsize,
                 const BYTE * text, unsigned long textsize)
{
	unsigned long o;	/* offset in fixup stream */
	LONG text_offset;

	if(fixupsize < 5) {
		fprintf(stderr, "Fixup list too short\n");
		return -1;
	}
	text_offset = READLONG(fixups);
	for(o = 4; o < fixupsize; o++) {
		if(fixups[o] == 0) {	/* end of list */
			if(o != fixupsize - 1)
				fprintf(stderr, "WARNING %ld extra bytes after fixup list\n",
			            fixupsize - o - 1);
			break;
		}
		if(fixups[o] == 1)
			text_offset += 254;
		else {
			if(fixups[o] & 1)
				fprintf(stderr, "WARNING odd number $%02x in fixup list !\n", fixups[o]);
			text_offset += fixups[o];
			if(text_offset < textsize)
				printf("Fixup at address $%06x : value $%08x\n",
				       text_offset, READLONG(text + text_offset));
			else
				fprintf(stderr, "overflow in fixup address $%06x\n", text_offset);
		}
	}
	return 0;
}

int parse_prg(const uint8_t * buffer, unsigned long size)
{
	WORD magic;	/* 0x601A = bra $1c */
	LONG tsize;	/* size of the TEXT segment */
	LONG dsize;	/* size of the DATA segment */
	LONG bsize;	/* size of the BSS segment */
	LONG ssize;	/* size of the symbol table */
	LONG res1;	/* reserved */
	LONG prgflags;	/* progam flags */
	WORD absflags;	/* non-zero to indicate that the program has no fixups */
	const void * text;
	const void * data;
	const void * symb;
	const BYTE * fixups;
	long fixupsize;

	if(size < 0x20) {
		fprintf(stderr, "PRG too small (%lu bytes)\n", size);
		return -1;
	}

	magic = READWORD(buffer);
	tsize = READLONG(buffer + 0x02);
	dsize = READLONG(buffer + 0x06);
	bsize = READLONG(buffer + 0x0a);
	ssize = READLONG(buffer + 0x0e);
	res1 = READLONG(buffer + 0x12);
	prgflags = READLONG(buffer + 0x16);
	absflags = READWORD(buffer + 0x1a);
	text = buffer + 0x1c;
	data = (const uint8_t *)text + tsize;
	symb = (const uint8_t *)data + dsize;
	fixups = (const uint8_t *)symb + ssize;

	if(magic != 0x601a) fprintf(stderr, "MAGIC is not $601a !\n");
	printf("magic :     $%04x\n", magic);
	printf("text size : $%08x = %6u bytes\n", tsize, tsize);
	printf("data size : $%08x = %6u bytes\n", dsize, dsize);
	printf("bss size :  $%08x = %6u bytes\n", bsize, bsize);
	printf("symb size : $%08x = %6u bytes\n", ssize, ssize);
	printf("reserved :  $%08x\n", res1);
	printf("prgflags :  $%08x\n", prgflags);
	printf("absflags :  $%04x\n", absflags);

	fixupsize = (long)size - (long)(fixups - buffer);
	if(fixupsize < 0) {
		fprintf(stderr, "inconstitancies with sizes (total size = %lu).\n", size);
		return -2;
	}
	printf("fixup size: %5ld bytes\n", fixupsize);
	if(absflags == 0) {
		parse_fixups(fixups, fixupsize, text, tsize);
	}
	if(ssize > 0) {
		parse_symbols(symb, ssize);
	}
	return 0;
}

int main(int argc, char * * argv)
{
	FILE * f;
	long filesize;
	void * buffer;
	int r;

	if(argc < 2) {
		printf("TOS executable display (c) 2016 Thomas Bernard\n");
		printf("usage : %s <file.prg>\n", argv[0]);
		return 1;
	}
	f = fopen(argv[1], "rb");
	if(!f) {
		fprintf(stderr, "Cannot open file %s : %s\n", argv[1], strerror(errno));
		return 2;
	}
	if(fseek(f, 0, SEEK_END) < 0) {
		perror("fseek");
		return 3;
	}
	filesize = ftell(f);
	if(filesize < 0) {
		perror("ftell");
		return 4;
	}
	if(fseek(f, 0, SEEK_SET) < 0) {
		perror("fseek");
		return 5;
	}
	buffer = malloc(filesize);
	if(buffer == NULL) {
		fprintf(stderr, "Allocation of %ld bytes failed : %s\n", filesize, strerror(errno));
		return 6;
	}
	if(fread(buffer, 1, filesize, f) != (unsigned long)filesize) {
		fprintf(stderr, "Failed to read %ld bytes from file.\n", filesize);
		return 7;
	}
	fclose(f);
	r = parse_prg(buffer, filesize);
	free(buffer);
	return r;
}
