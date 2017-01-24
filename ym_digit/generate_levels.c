/* PCM => YM2149 volume generator
 * (c) 2016 Thomas Bernard
 *
 * according to this document : http://www.ym2149.com/ym2149.pdf
 * the YM 2149 volumes are logarithmic, with a sqrt(2) base,
 * meaning that voltage is doubled when level +2
 *
 * This program find an optimal table for the 3 channels values,
 * minimizing the error.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <errno.h>

/* Taken from Hatari - Paulo Simoes' YM output measurements */
/* Table of unsigned 4 bit D/A output level for 3 channels as measured on a real ST */
static unsigned int volumetable_original[16][16][16] =
#include "ym2149_fixed_vol.h"

static double
generate_levels(int bits, int a1, int b1, int c1,
                int silent, int signed_pcm, unsigned char * results)
{
	/* 3 YM levels from 3 to 3.a^15
	 * with a = sqrt(2) */
	double sqrt2, lnsqrt2;
	double amplitude, ratio;
	int maxval;
	int level;
	int a, b, c;
	int besta, bestb, bestc;
	double l, error;
	double bestl, besterror;
	double errsum = 0.0;
	unsigned int offset;

	maxval = (1 << bits) - 1;
	sqrt2 = sqrt(2.0);
	lnsqrt2 = log(sqrt2);

	//amplitude = 3.0*(exp(lnsqrt2*15.0)-1.0);
	amplitude =   exp(lnsqrt2*(double)a1)
	            + exp(lnsqrt2*(double)b1)
	            + exp(lnsqrt2*(double)c1) - 3.0;
	ratio = (double)maxval / amplitude;
	if(!silent) printf("amplitude=%g   ratio=%g\n", amplitude, ratio);

	for(level = 0; level <= maxval; level++) {
		if(!silent) printf("level %3d :\n", level);
		besta = bestb = bestc = -1;
		besterror = (double)maxval;
		for(a = 15; a >= 0; a--) {
			for (b = 0; b <= a; b++) {
				for (c = 0; c <= b; c++) {
					l = exp(lnsqrt2*a)+exp(lnsqrt2*b)+exp(lnsqrt2*c)-3.0;
					l *= ratio;
					error = fabs(l-(double)level);
					// erreur relative
					//error /= (1.0+(double)level);
					if(error < besterror) {
						besterror = error;
						besta = a;
						bestb = b;
						bestc = c;
						bestl = l;
					}
				}
			}
		}
		if(!silent) {
			printf("  a=%2d b=%2d c=%2d", besta, bestb, bestc);
			printf(" => %g (error=%g)\n", bestl, besterror);
		}
		errsum += besterror;
		if(results) {
			offset = level;
			if(signed_pcm)
				offset ^= (1 << (bits - 1));
			offset *= 3;
			results[offset+0] = besta;
			results[offset+1] = bestb;
			results[offset+2] = bestc;
		}
	}
	/*if(!silent)*/ printf("** errsum = %g\n", errsum);
	return errsum;
}

static int
write_values(int bits, const unsigned char * values, const char * filename)
{
	FILE *f;
	int i, max;

	f = fopen(filename, "w");
	if(f == NULL) {
		fprintf(stderr, "Cannot open '%s' : %s\n", filename, strerror(errno));
		return -1;
	}
	max = 1 << bits;
	for(i = 0; i < max; i++) {
		fprintf(f, "    dc.w $8%02x,$9%02x,$a%02x,0 ; %3d\n",
		       values[0], values[1], values[2], i);
		values += 3;
	}
	fclose(f);
	return 0;
}

int bits = 8;
int signed_pcm = 1;
const char * filename = NULL;

static int
calc(){
	int a, b, c;
	int besta, bestb, bestc;
	double err;
	double besterr = 1000000000000.0;
	unsigned char * values;

	values = malloc(3*(1 << bits));
	if(values == NULL) {
		perror("malloc");
		return 1;
	}
	besta = bestb = bestc = -1;
	for(a = 15; a > 10; a--) {
		for (b = 0; b <= a; b++) {
			for (c = 0; c <= b; c++) {
				err = generate_levels(bits, a, b, c, 1, signed_pcm, NULL);
				if(err < besterr) {
					besterr = err;
					besta = a;
					bestb = b;
					bestc = c;
				}
			}
		}
	}
	printf("best :\n");
	generate_levels(bits, besta, bestb, bestc, 0, signed_pcm, values);
	if(filename != NULL) write_values(bits, values, filename);
	free(values);
	return 0;
}


static int
search_bruteforce_simoes_window(int maxlevel, unsigned char * values){
	unsigned int minerr, allerr=0;
	unsigned int err=0;
	unsigned int l,a,b,c,level,offset;
	double f=(double)maxlevel/(double)(1 << bits);

	for( l=0; l<1<<bits; l++){
		level=(unsigned int)(f*(float)l);
		minerr=1<<bits;
//		printf("amplitude=%02x ", level);
		for( a=0; a<16; a++){
			for( b=0; b<16; b++){
				for( c=0; c<16; c++){
					err = abs(volumetable_original[a][b][c]-(int)level);
					if( err<minerr ){
						minerr = err;
						if( values ){
							offset = l;
							if(signed_pcm){
								offset ^= (1 << (bits - 1));
							}
							offset *= 3;
							values[offset]=a;
							values[offset+1]=b;
							values[offset+2]=c;
						}
					}
				}
			}
		}
		allerr+=minerr;
//		printf("err=%d ", lasterr);
//		printf("\n");
	}
	return allerr;
}

static int
search_bruteforce_simoes(){
	unsigned int l, bestamplitude=0;
	double allerr, minerr;
	unsigned char * values;
	minerr=0xFFFFFF;

	for( l=0x10000; l>256 ; l--){
		allerr=(double)search_bruteforce_simoes_window(l,NULL)/(double)l;
//		printf("l:%d\n", l);
		if( allerr < minerr ){
			minerr=allerr;
			bestamplitude=l;
			printf("err(w:%d):%f\n", l, allerr);
		}
	}
	printf("minerr:%f\n", minerr);

	if(filename != NULL){
		values = malloc(3*(1 << bits));
		search_bruteforce_simoes_window(bestamplitude,values);
/*
		filename="l33121.s";
		search_bruteforce_simoes_window(33121);
*/
		write_values(bits, values, filename);
		free(values);
	}
	return 0;
}

int main(int argc, char * * argv)
{
	int i;
	int mode=0;
	for(i = 1; i < argc; i++) {
		if(strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
			printf("Usage : %s [options] [filename]\n", argv[0]);
			printf("     --bits <n> : set n bits samples (default is 8)\n");
			printf("     --unsigned : unsigned PCM samples (default is signed)\n");
			return 0;
		} else if(strcmp(argv[i], "--bits") == 0) {
			if(++i >= argc) {
				fprintf(stderr, "--bits options need an argument\n");
				return 1;
			}
			bits = atoi(argv[i]);
			if(bits <= 0 || bits > 31) {
				fprintf(stderr, "invalid value %s for option --bits\n", argv[i]);
				return 1;
			}
		} else if(strcmp(argv[i], "--unsigned") == 0) {
			signed_pcm = 0;
		} else if(strcmp(argv[i], "--math") == 0) {
			mode = 1;
		} else {
			filename = argv[i];
		}
	}

	switch( mode ){
		default:
		case 0:		//bruteforce search
			return search_bruteforce_simoes();
		case 1: 	//math
			return calc();
	}
}
