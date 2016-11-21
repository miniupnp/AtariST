/* (c) thomas BERNARD
 * https://github.com/miniupnp/AtariST
 *
 * see http://info-coach.fr/atari/software/FD-Soft.php
 */
#include <stdio.h>

#define DWORD_LE(p) (p)[0] | ((p)[1] << 8) | ((p)[2] << 16) | ((p)[3] << 24)
#define WORD_LE(p) (p)[0] | ((p)[1] << 8)

void print_string(unsigned char * string, int len)
{
	int i;
	for(i = 0; i < len; i++)
		printf("$%02x ", string[i]);
	putchar('"');
	for(i = 0; i < len; i++)
		putchar(string[i] < 32 ? '.' : string[i]);
	putchar('"');
}

void print_bootsector(unsigned char * bs)
{
	printf("$00 BRA    $%02x%02x\n", bs[0], bs[1]);
	printf("$02 OEM    "); print_string(bs+2, 6); putchar('\n');
	printf("$08 SERIAL $%06x\n", DWORD_LE(bs+8));
	/* offset 11 = $0B : start of the BPB bios param block */
	printf("$0B BPS    %d\n", WORD_LE(bs+11));
	printf("$0D SPC    %d\n", bs[13]);
	printf("$0E RESSEC %d\n", WORD_LE(bs+14));
	printf("$10 NFATS  %d\n", bs[16]);
	printf("$11 NDIRS  %d\n", WORD_LE(bs+17));
	printf("$13 NSECTS %d\n", WORD_LE(bs+19));
	printf("$15 MEDIA  $%02x\n", bs[21]);
	printf("$16 SPF    %d\n", WORD_LE(bs+22));
	printf("$18 SPT    %d\n", WORD_LE(bs+24));
	printf("$1A NHEADS %d\n", WORD_LE(bs+26));
	printf("$1C NHID   %d\n", WORD_LE(bs+28));
}

unsigned short checksum_bs(unsigned char * bs, int len)
{
	unsigned short sum = 0;
	int i;

	for(i = 0; i < len; i+=2) {
		sum += ((unsigned short)bs[i] << 8 | (unsigned short)bs[i+1]);
	}
	return sum;
}

int inject(const char * floppyfile, const char * bsfile)
{
	FILE * fbs;
	FILE * ffloppy;
	unsigned char bootsector[512];
	ssize_t n;
	unsigned short checksum;

	ffloppy = fopen(floppyfile, "rb");
	if(!ffloppy)
		return -1;
	n = fread(bootsector, 1, 512, ffloppy);
	fclose(ffloppy);
	if(n != 512)
		return -2;
	print_bootsector(bootsector);
	printf("checksum=$%04x\n", checksum_bs(bootsector, 512));
	if(bsfile == NULL)
		return 0;
	fbs = fopen(bsfile, "rb");
	if(!fbs)
		return -3;
	n = fread(bootsector + 30, 1, 512-30-2, fbs);
	fclose(fbs);
	if(n <= 0)
		return -4;
	printf("%u bytes loaded\n", (unsigned)n);
	/* put BRA */
	bootsector[0] = 0x60;
	bootsector[1] = 0x1c;
	/* calculate Checksum */
	checksum = 0x1234 - checksum_bs(bootsector, 510);
	printf("$%04x  ", checksum);
	bootsector[510] = (unsigned char)(checksum >> 8);
	bootsector[511] = (unsigned char)checksum;
	printf("checksum=$%04x\n", checksum_bs(bootsector, 512));
	fbs = fopen(floppyfile, "r+b");
	if(!fbs)
		return -5;
	n = fwrite(bootsector, 1, 512, fbs);
	fclose(fbs);
	if(n != 512)
		return -6;
	return 0;
}

int main(int argc, char * * argv)
{
	int r;
	if(argc < 2) {
		fprintf(stderr, "Usage: %s floppy.st [bootsector.bin]\n", argv[0]);
		return 2;
	}
	r = inject(argv[1], argc < 3 ? NULL : argv[2]);
	if(r != 0) {
		fprintf(stderr, "error %d\n", r);
	}
	return r;
}

