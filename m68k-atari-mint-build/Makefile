URLGET=$(shell which wget || echo "`which curl` -O")
TAR=tar
MD5SUM=md5sum

INSTALL_DIR=/tmp/cross-mint
VERSIONBIN=-bin-$(shell uname -s | tr '[A-Z]' '[a-z]')

VRIVIEREURLBASE=http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/

BINUTILSARCHIVE=binutils-2.26.tar.bz2
BINUTILSURL=ftp://ftp.gnu.org/gnu/binutils/$(BINUTILSARCHIVE)
BINUTILSPATCH=binutils-2.26-mint-20160320.patch.bz2
BINUTILSPATCHURL=$(VRIVIEREURLBASE)$(BINUTILSPATCH)
BINUTILSPACKAGE=binutils-2.26-mint-20160320$(VERSIONBIN).tar.bz2

MINTBINARCHIVE=mintbin-CVS-20110527.tar.gz
MINTBINURL=$(VRIVIEREURLBASE)$(MINTBINARCHIVE)
MINTBINPACKAGE=mintbin-CVS-20110527$(VERSIONBIN).tar.bz2


all:	archives build binutils mintbin

archives:
	mkdir -p $@

build:
	mkdir -p $@

archives/$(BINUTILSARCHIVE):
	cd archives; $(URLGET) $(BINUTILSURL)

archives/$(BINUTILSPATCH):
	cd archives; $(URLGET) $(BINUTILSPATCHURL)

archives/$(MINTBINARCHIVE):
	cd archives; $(URLGET) $(MINTBINURL)

binutils:	build/$(BINUTILSPACKAGE)

build/$(BINUTILSPACKAGE):	archives/$(BINUTILSARCHIVE) archives/$(BINUTILSPATCH)
	VERSIONBIN="$(VERSIONBIN)" INSTALL_DIR="$(INSTALL_DIR)" ./binutils-mint-build.sh

mintbin:	build/$(MINTBINPACKAGE)

build/$(MINTBINPACKAGE):	archives/$(MINTBINARCHIVE)
	VERSIONBIN="$(VERSIONBIN)" INSTALL_DIR="$(INSTALL_DIR)" ./mintbin-mint-build.sh
