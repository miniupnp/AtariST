#include <stdio.h>
#include <tos.h>
#include "ngiflib.h"

size_t __stack = 65536; /* 64KB stack-size */

void fprintf_ts(FILE *f, ULONG ts)
{
	/* http://toshyp.atari.org/en/004009.html
	 *   Bit 	Description
	 *   0-4 	Seconds in units of 2 (0-29)
	 *  5-10 	Minutes (0-59)
	 * 11-15 	Hours (0-23)
	 * 16-20 	Day of month (1-31)
	 * 21-24 	Month (1-12)
	 * 25-31 	Year (0-119, 0 represents 1980) */
	fprintf(f, "%d-%02d-%02d %02d:%02d:%02d",
	        (int)(ts >> 25)+1980, (int)(ts >> 21) & 0xf, (int)(ts >> 16) & 0x1f,
	        (int)(ts >> 11) & 0x1f, (int)(ts >> 5) & 0x3f, ((int)ts & 0x1f) * 2);
}

/* return 200Hz System timer */
LONG get200hz(void)
{
	return *((LONG*)0x4ba);
}

UWORD to_st_palette(UBYTE r, UBYTE g, UBYTE b)
{
	/* TODO : STe Palette */
	return ((((UWORD)r & 0xe0) << 3)) | ((g & 0xe0) >> 1) | (b >> 5);
}

void c2p(UWORD * planar, UBYTE * chunky, int width, int height)
{
	int x, y, i, j;
	UWORD p[4];
	UBYTE pixel;
	for(y = height; y > 0; y--) {
		for(x = (width + 15) >> 4; x > 0; x--) {
			for(i = 16; i > 0; i--) {
				pixel = *chunky++;
				for(j = 0; j < 4; j++) {
					p[j] = (p[j] << 1) | (pixel & 1);
					pixel >>= 1;
				}
			}
			*planar++ = p[0];
			*planar++ = p[1];
			*planar++ = p[2];
			*planar++ = p[3];
		}
		if(width != 320) {
			planar += ((320 - width) >> 4) * 4;
			chunky += (width & 15) - (((width & 15)+15) & 16);
		}
	}
}

int main(int argc, char ** argv)
{
	int r, i;
	struct ngiflib_gif * gif;
	struct ngiflib_img * img;
	const char * filename;
	FILE * fgif;
	FILE * log;
	ULONG ts;
	LONG t0, t1;

	filename = "NGIFLIB\\SAMPLES\\borregas.gif";
	filename = "NGIFLIB\\SAMPLES\\cirrhose.gif";
	//filename = "amigagry.gif";
	//filename = "nomercyi.gif";
	//filename = "e7monsta.gif"
	//filename = "NGIFLIB\\SAMPLES\\far_away.gif";

	log = fopen("show_gif.log", "a");
	memset(&gif, 0, sizeof(gif));
	fgif = fopen(filename, "rb");
	if(fgif == NULL) {
		fprintf(stderr, "ERROR\n");
		return 1;
	}
	gif = malloc(sizeof(struct ngiflib_gif));
	memset(gif, 0, sizeof(struct ngiflib_gif));
	gif->input = (void *)fgif;
	gif->mode = NGIFLIB_MODE_FROM_FILE;
	gif->mode |= NGIFLIB_MODE_INDEXED;

	ts = Gettime();
	fprintf_ts(log, ts);
	fprintf(log, " %s ", filename);
	t0 = Supexec(get200hz);
	r = LoadGif(gif);
	t1 = Supexec(get200hz);
	if(r == 0) {
		fprintf(log, "failure");
	} else if(r == 1) {
		u16 palette[16];
		fprintf(log, "time=%ldms", (t1 - t0)*5);
		printf("OK\n");
		(void)Cursconf(0, 0);	/* hide cursor */
		img = gif->cur_img;
		for(i = 0; i < 16; i++) {
			palette[i] = to_st_palette(img->palette[i].r,
			                           img->palette[i].g,
			                           img->palette[i].b);
		}
		Setpalette(palette);
		t0 = Supexec(get200hz);
		c2p(Physbase(), (UBYTE *)gif->frbuff, gif->width, gif->height);
		t1 = Supexec(get200hz);
		fprintf(log, " c2p=%ldms", (t1 - t0)*5);
	}

	//GifDestroy(&gif);
	fprintf(log, "\n");
	fclose(log);
	Crawcin();
	return 0;
}
