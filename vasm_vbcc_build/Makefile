# (c) 2016 Thomas BERNARD
# https://github.com/miniupnp/AtariST
#
# vbcc targets :
#  m68k  : 32 bits
#  m68ks : 16 bits ints
#
# thanks to :
#  http://blitterstudio.com/setting-up-an-amiga-cross-compiler/
#  http://koti.kapsi.fi/~jvaltane/crosscompiler/vbcc-amiga-cross-compiler-to-linux.txt
URLGET=$(shell which wget || echo "`which curl` -O")
TAR=tar
CP=cp
INSTALL=install

VASMARCHIVE=vasm.tar.gz
VASMURL=http://sun.hasenbraten.de/vasm/release/$(VASMARCHIVE)
VASMBIN=vasmm68k_mot

# http://server.owl.de/~frank/vbcc/2016-03-23/vbcc_unix_config.tar.gz
# http://server.owl.de/~frank/vbcc/2016-03-23/vbcc_bin_tos.zip
# http://server.owl.de/~frank/vbcc/2016-03-23/vbcc_target_m68k-atari.tar.gz
# http://server.owl.de/~frank/tags/vbcc0_9e.tar.gz
# http://server.owl.de/~frank/tags/vbcc0_9fP1.tar.gz
#VBCCARCHIVE=vbcc.tar.gz
VBCCARCHIVE=vbcc0_9g.tar.gz
#VBCCURL=http://www.ibaug.de/vbcc/$(VBCCARCHIVE)
VBCCURL=http://server.owl.de/~frank/tags/$(VBCCARCHIVE)
VBCCBIN=vc
VBCCBASE=http://server.owl.de/~frank/vbcc/2019-10-04/
VBCCCONFIG=vbcc_unix_config.tar.gz
VBCCTARGET=vbcc_target_m68k-atari.tar.gz

VLINKARCHIVE=vlink.tar.gz
VLINKURL=http://sun.hasenbraten.de/vlink/release/$(VLINKARCHIVE)
VLINKBIN=vlink

.PHONY:	archives build bin all clean install

all:	vasm vlink vbcc

archives:
	mkdir -p $@

build:
	mkdir -p $@

bin:
	mkdir -p $@

clean:
	$(RM) -r archives build bin

install:	vasm vlink vbcc archives/$(VBCCCONFIG) archives/$(VBCCTARGET)
	@if [ -z "$(VBCC)" ] ; then \
		echo "Please set VBCC environment variable." ;\
		echo "for example :" ;\
		echo "$$ make install VBCC=\"/usr/local/vbcc\"" ;\
		false;\
	fi
	$(INSTALL) -d $(VBCC)/bin
	$(INSTALL) bin/* $(VBCC)/bin
	cd $(VBCC); $(TAR) xzf $(PWD)/archives/$(VBCCCONFIG)
	cd $(VBCC); $(TAR) xzf $(PWD)/archives/$(VBCCTARGET)
	@echo "Install done. Don't forget to set VBCC and PATH environment vars."

vasm:	bin/$(VASMBIN)

bin/$(VASMBIN):	build/vasm.src | bin
	$(MAKE) -C build/vasm CPU=m68k SYNTAX=mot
	$(CP) build/vasm/$(VASMBIN) $@
	$(CP) build/vasm/vobjdump bin/

build/vasm.src:	archives/$(VASMARCHIVE) | build
	cd build; $(TAR) xzf ../$<
	touch $@

archives/$(VASMARCHIVE):	| archives
	cd archives; $(URLGET) $(VASMURL)

vlink:	bin/$(VLINKBIN)

bin/$(VLINKBIN):	build/vlink.src | bin
	$(MAKE) -C build/vlink
	$(CP) build/vlink/$(VLINKBIN) $@

build/vlink.src:	archives/$(VLINKARCHIVE) | build
	cd build; $(TAR) xzf ../$<
	touch $@

archives/$(VLINKARCHIVE):	| archives
	cd archives; $(URLGET) $(VLINKURL)

vbcc:	bin/$(VBCCBIN)

bin/$(VBCCBIN):	build/vbcc.src | bin
	mkdir -p build/vbcc/bin
	$(MAKE) -C build/vbcc TARGET=m68ks
	$(CP) build/vbcc/bin/* bin/

build/vbcc.src:	archives/$(VBCCARCHIVE) | build
	cd build; $(TAR) xzf ../$<
	touch $@

archives/$(VBCCARCHIVE):	| archives
	cd archives; $(URLGET) $(VBCCURL)

archives/$(VBCCCONFIG):	| archives
	cd archives; $(URLGET) $(VBCCBASE)$(notdir $@)

archives/$(VBCCTARGET):	| archives
	cd archives; $(URLGET) $(VBCCBASE)$(notdir $@)
