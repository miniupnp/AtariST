STratosphere presents
                  THE 80's SlideShow

Code  : Nanard
GfX   : Jojo073
Music : Karsten Obarski (YM2149F conversion by Estrayk)

Should run on any Atari ST / STe / Mega STe

A Party version has been released for the Cookie demoparty held in Paris
December 3rd 2016 - http://cookie.paris/
This Party version has glitches on STe machines.
Developped using VASM and Hatari.
Music composed in maxYMiser.

This is an open source production :
https://github.com/miniupnp/AtariST/tree/master/the_80s

Tested on : Mega STe (TOS x)
            2080 STe (TOS 1.06)
            1040 STf (TOS 1.00)
            1040 STfm (TOS 1.04)

TODO :
 run OK on 60HZ machines ?
 test with EMUTOS
 fade out between VT52 part and slideshow
 proper ASCII logo

Programming notes :
Contrary to most demoscene production, I've tried to be as "OS friendly" as
possible. Everything that can run in usermode does run in usermode, TOS
interrupt routines are still running.
GEMDOS functions are used to load files, etc.
That's because we wanted to be compatible with many machines and load files
from hard disk (Ultra Satan / CosmosEx)



                                                                         nanard
