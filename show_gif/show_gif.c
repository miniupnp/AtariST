#include <stdio.h>
#ifdef __VBCC__
#include <tos.h>
#else
#include <mint/osbind.h>
#define LONG long
#define WORD short
#define ULONG unsigned long
#define UWORD unsigned short
#define UBYTE unsigned char
#endif
#ifndef E_OK
#define E_OK 0
#endif /* E_OK */

#include "ngiflib.h"

#ifdef __VBCC__
size_t __stack = 65536; /* 64KB stack-size */
#endif /* __VBCC__ */

struct animgif_image {
	struct animgif_image * next;
	int delay_time;
	UWORD pixel_data[1];
};

#define ASM_C2P_LINE

#ifdef ASM_C2P_LINE
extern void c2p_line(UWORD * planar, UBYTE * chunky, int count);
#endif

#define ABS(i) my_abs(i)

#if !defined(NGIFLIB_PALETTE_USE_BYTES)
#define COLOR_DIFF(A,B) (  ABS(((int)((A).r) - (int)(B).r) & ~31) \
                         + ABS(((int)((A).g) - (int)(B).g) & ~31) \
                         + ABS(((int)((A).b) - (int)(B).b) & ~31) )
#else
#define COLOR_DIFF(A,B) (  ABS(((int)((A)[0]) - (int)(B)[0]) & ~31) \
                         + ABS(((int)((A)[1]) - (int)(B)[1]) & ~31) \
                         + ABS(((int)((A)[2]) - (int)(B)[2]) & ~31) )
#endif

static int my_abs(int i)
{
	if(i > 0) return i;
	if(i == 0x8000) return 0x7fff;
	return (-i);
}

#ifdef SHOW_GIF_LOG
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
#endif

/* return 200Hz System timer */
LONG get200hz(void)
{
	return *((LONG*)0x4ba);
}

#if 0
UWORD to_st_palette(UBYTE r, UBYTE g, UBYTE b)
{
	return ((((UWORD)r & 0xe0) << 3)) | ((g & 0xe0) >> 1) | (b >> 5);
}
#endif

UWORD to_ste_palette(UBYTE r, UBYTE g, UBYTE b)
{
	WORD w;	/* STe Palette entry : 0000rRRRgGGGbBBB */
	/* r/g/b is LSB of 4 bit color value, RRR/GGG/BBB are MSB */
	w = (((UWORD)r & 0xe0) << 3) | (((UWORD)r & 0x10) << 7);
	w |= ((g & 0xe0) >> 1) | ((g & 0x10) << 3);
	w |= (b >> 5) | ((b & 0x10) >> 1);
	return w;
}

#ifndef ASM_C2P_LINE
void c2p_line(UWORD * planar, UBYTE * chunky, int count)
{
	int i, j;
	UWORD p[4];
	UBYTE pixel;

	for(; count > 0; count--) {
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
}
#endif

void c2p(UWORD * planar, UBYTE * chunky, int width, int height)
{
	int count;
	count = (width + 15) >> 4;	/* word per plane / line count */
	for(; height > 0; height--) {
		c2p_line(planar, chunky, count);
		planar += 80;	/* line of ST frame buffer is 320 pixels = 80 words */
		chunky += width;
	}
}

#ifdef NGIFLIB_ENABLE_CALLBACKS
#ifdef NGIFLIB_PALETTE_USE_BYTES
static void set_palette(struct ngiflib_gif * gif, const u8 * pal, int ncolors)
#else
static void set_palette(struct ngiflib_gif * gif, struct ngiflib_rgb * pal, int ncolors)
#endif
{
	int i;
	static u16 palette[16];

	printf("set_palette(.. %d)\n", ncolors);
	for(i = 0; i < 16 && i < ncolors; i++) {
		/*printf("%2d: %02x %02x %02x\n", i, (int)pal[i].r, (int)pal[i].g, (int)pal[i].b);*/
#ifdef NGIFLIB_PALETTE_USE_BYTES
		palette[i] = to_ste_palette(pal[0],
		                            pal[1],
		                            pal[2]);
		pal += 3;
#else
		palette[i] = to_ste_palette(pal[i].r,
		                            pal[i].g,
		                            pal[i].b);
#endif
	}
	Setpalette(palette);
}

static void draw_line(struct ngiflib_gif * gif, union ngiflib_pixpointer line, int Y)
{
	UWORD * dest;
	if(Y < 200) {
		dest = (UWORD *)Physbase() + Y * 80;
		c2p_line(dest, line.p8, (gif->width + 15) >> 4);
	}
}
#endif /* NGIFLIB_ENABLE_CALLBACKS */

int show_gif(const char * filename)
{
	int image_count = 0;
	int r, i;
	struct ngiflib_gif * gif;
	struct ngiflib_img * img;
	FILE * fgif;
#ifdef SHOW_GIF_LOG
	FILE * log;
	ULONG ts;
#endif
	LONG t0, t1;
	struct animgif_image * anim = NULL;
	struct animgif_image * tmp_image;
	struct animgif_image * new_image;
	unsigned int line_word_count = 0;

#ifdef SHOW_GIF_LOG
	log = fopen("show_gif.log", "a");
#endif
	memset(&gif, 0, sizeof(gif));
	fgif = fopen(filename, "rb");
	if(fgif == NULL) {
		fprintf(stderr, "ERROR\n");
		return 1;
	}

	gif = malloc(sizeof(struct ngiflib_gif));
	memset(gif, 0, sizeof(struct ngiflib_gif));
	gif->input.file = fgif;
	gif->mode = NGIFLIB_MODE_FROM_FILE;
	gif->mode |= NGIFLIB_MODE_INDEXED;

#ifdef NGIFLIB_ENABLE_CALLBACKS
	gif->palette_cb = set_palette;
	gif->line_cb = draw_line;
#endif

	(void)Cursconf(0, 0);	/* hide cursor */
#ifdef SHOW_GIF_LOG
	ts = Gettime();
	fprintf_ts(log, ts);
	fprintf(log, " %s ", filename);
#endif
	for(;;) {
		u16 palette[16];
		t0 = Supexec(get200hz);
		r = LoadGif(gif);
		t1 = Supexec(get200hz);
		if(r < 0) {
#ifdef SHOW_GIF_LOG
			fprintf(log, "failure");
#endif
			break;
		} else if(r == 0) {
			break;
		}
		/* (r == 1) */
		image_count++;
#ifdef SHOW_GIF_LOG
		fprintf(log, "time=%ldms", (t1 - t0)*5);
#endif
		img = gif->cur_img;
#ifndef NGIFLIB_ENABLE_CALLBACKS
		for(i = 0; i < 16 && i < gif->ncolors; i++) {
#if !defined(NGIFLIB_PALETTE_USE_BYTES)
			palette[i] = to_ste_palette(img->palette[i].r,
			                            img->palette[i].g,
			                            img->palette[i].b);
#else
			palette[i] = to_ste_palette(img->palette[i*3+0],
			                            img->palette[i*3+1],
			                            img->palette[i*3+2]);
#endif
		}
		Setpalette(palette);
		/*for(i = 0; i < 16; i++) gif->frbuff.p8[i] = i;*/
		t0 = Supexec(get200hz);
		c2p(Physbase(), gif->frbuff.p8, gif->width, gif->height);
		t1 = Supexec(get200hz);
#ifdef SHOW_GIF_LOG
		fprintf(log, " c2p=%ldms", (t1 - t0)*5);
#endif
#endif /* NGIFLIB_ENABLE_CALLBACKS */
#ifdef SHOW_GIF_LOG
		fprintf(log, " %dc", (int)gif->ncolors);
#endif
		if(gif->ncolors > 16) {
			unsigned long l;
			unsigned int freq[256];
			unsigned int min_freq;
			unsigned int used_colors;
			UBYTE trans_tab[256];
			UBYTE * p;

			memset(freq, 0, sizeof(freq));
			min_freq = 0xffff;
			/* count frequency of pixel values */
			for(p = gif->frbuff.p8, l = (unsigned long)gif->width*gif->height; l > 0; l--, p++) {
				freq[*p]++;
			}
			/* count # used colors */
			for(used_colors = 0, i = 0; i < 256; i++) {
				if(freq[i] != 0) {
					used_colors++;
					if(freq[i] < min_freq) min_freq = freq[i];
				}
				trans_tab[i] = (UBYTE)i;	/* and init trans_tab */
				/*if(freq[i] != 0) printf("%d %4d  #%02x%02x%02x\n", i, freq[i],
				img->palette[i].r, img->palette[i].g, img->palette[i].b);*/
			}
#ifdef SHOW_GIF_LOG
			fprintf(log, " %uused", used_colors);
#endif
			while(used_colors > 16) {
				int to_kick = 0;
				int close_color = 0;
				int min_diff = 0x7fff;
				while(to_kick < gif->ncolors && (freq[to_kick] == 0 || freq[to_kick] > min_freq))
					to_kick++;
				/*printf("min_freq=%d to_kick = %d\n", min_freq, to_kick);*/
				for(i = 0; i < gif->ncolors; i++) {
					int diff;
					if(i == to_kick) continue;
					if(freq[i] == 0) continue;
#if !defined(NGIFLIB_PALETTE_USE_BYTES)
					diff = COLOR_DIFF(img->palette[to_kick], img->palette[i]);
#else
					diff = COLOR_DIFF(img->palette+to_kick*3, img->palette+i*3);
#endif
					if(diff < min_diff) {
						min_diff = diff;
						close_color = i;
					}
				}
				freq[close_color] += freq[to_kick];
				freq[to_kick] = 0;
				min_freq = 0xffff;
				for(i = 0; i < gif->ncolors; i++) {
					if(trans_tab[i] == to_kick) {
						trans_tab[i] = close_color;
					}
					if(freq[i] != 0 && freq[i] < min_freq) min_freq = freq[i];
				}
				used_colors--;
			}
			if(used_colors <= 16) {
				UBYTE c = 0;
				for(i = 0; i < 256; i++) {
					if(freq[i] != 0) {
						trans_tab[i] = c;
#if !defined(NGIFLIB_PALETTE_USE_BYTES)
						palette[c] = to_ste_palette(img->palette[i].r,
						                            img->palette[i].g,
						                            img->palette[i].b);
#else
						palette[c] = to_ste_palette(img->palette[i*3+0],
						                            img->palette[i*3+1],
						                            img->palette[i*3+2]);
#endif
						c++;
					}
				}
				for(i = 0; i < 256; i++) {
					if(freq[i] == 0 && trans_tab[i] != i) {
						trans_tab[i] = trans_tab[trans_tab[i]];
					}
				}
				Setpalette(palette);
				for(p = gif->frbuff.p8, l = (unsigned long)gif->width*gif->height; l > 0; l--, p++) {
					*p = trans_tab[*p];
				}
				c2p((UWORD *)Physbase(), gif->frbuff.p8, gif->width, gif->height);
			} else {
				/* TODO : some color reduction ! */
			}
		}
		if(line_word_count == 0) {
			line_word_count = ((gif->width + 15) >> 2) & ~3;
		}
		new_image = malloc(sizeof(struct animgif_image) + sizeof(UWORD) * line_word_count * gif->height);
		if(new_image) {
			new_image->next = NULL;
			new_image->delay_time = gif->delay_time;
			for(i = 0; i < gif->height; i++) {
				memcpy(new_image->pixel_data + i * line_word_count,
				       (UWORD *)Physbase() + 80 * i,
				       sizeof(UWORD) * line_word_count);
			}
			if(anim == NULL) {
				anim = new_image;
			} else {
				tmp_image = anim;
				while(tmp_image->next != NULL)
					tmp_image = tmp_image->next;
				tmp_image->next = new_image;
			}
		}
	}

	GifDestroy(gif);
#ifdef SHOW_GIF_LOG
#ifdef __VBCC__
	fprintf(log, " VBCC");
#elif defined(__GNUC__)
	fprintf(log, " GCC %d.%d.%d", __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#endif
	fprintf(log, "\n");
	fclose(log);
#endif /* SHOW_GIF_LOG */

	if(image_count > 1) {
		tmp_image = anim;
		while(Cconis() == 0) {
			Vsync();
			t1 = Supexec(get200hz);
			t1 += tmp_image->delay_time * 2;
			for(i = 0; i < gif->height; i++) {
				memcpy((UWORD *)Physbase() + 80 * i,
				       tmp_image->pixel_data + i * line_word_count,
				       sizeof(UWORD) * line_word_count);
			}
			do {
				if(Cconis() != 0)
					break;
			} while(Supexec(get200hz) < t1);
			tmp_image = tmp_image->next;
			if(tmp_image == NULL) tmp_image = anim;
		}
	}
	Crawcin();
	/* free memory */
	while(anim != NULL) {
		tmp_image = anim->next;
		free(anim);
		anim = tmp_image;
	}
	return 0;
}

int main(int argc, char ** argv)
{
	int i;
	WORD old_mode;
	WORD palette_backup[16];
	char * filename = NULL;
	short attr;

	old_mode = Getrez();
	if(old_mode != ST_LOW)
		Setscreen((void *)-1, (void *)-1, ST_LOW);
	for(i = 0; i < 16; i++) {
		palette_backup[i] = Setcolor(i, -1);
	}

	/*filename = "NGIFLIB\\SAMPLES\\borregas.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\cirrhose.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\the_den.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\amigagry.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\nomercyi.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\exo7-monsta32.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\far_away.gif";*/
	/*filename = "NGIFLIB\\SAMPLES\\mr_boomi.gif";*/

	if(argc > 1) filename = argv[1];
	if(filename != NULL) {
		attr = Fattrib(filename, 0, 0);
		if(attr < 0) {
			fprintf(stderr, "file or directory %s not found.\n", filename);
			Crawcin();
			goto error;
		} else {
			if((attr & FA_DIR) != 0) {
				/* directory */
				char path[256];
				char * p;
				Dgetpath(path, 0);
				printf("PATH=%s\n", path);
				p = path + strlen(path);
				*p++ = '\\';
				strcpy(p, filename);
				printf("PATH=%s\n", path);
				Dsetpath(path);
				Dgetpath(path, 0);
				printf("PATH=%s\n", path);
				Crawcin();
				filename = NULL;
			}
		}
	}
	if(filename == NULL) {
#ifdef __VBCC__
		DTA dta;
#else
		_DTA dta;
#endif
		short r;

		Fsetdta(&dta);
#ifdef FA_READONLY
		r = Fsfirst("*.GIF", FA_READONLY | FA_HIDDEN | FA_SYSTEM | FA_ARCHIVE);
#else
		r = Fsfirst("*.GIF", FA_RDONLY | FA_HIDDEN | FA_SYSTEM | FA_CHANGED);
#endif
		while(r == E_OK) {
#ifdef __VBCC__
			filename = dta.d_fname;
#else
			filename = dta.dta_name;
#endif
			show_gif(filename);
			r = Fsnext();
		}
	} else {
		/* regular file */
		show_gif(filename);
	}

error:
	/*Setpalette(palette_backup);*/
	for(i = 0; i < 16; i++) {
		(void)Setcolor(i, palette_backup[i]);
	}
	if(old_mode != ST_LOW)
		Setscreen((void *)-1, (void *)-1, old_mode);
	return 0;
}
