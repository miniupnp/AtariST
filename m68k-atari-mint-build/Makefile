# see http://vincent.riviere.free.fr/soft/m68k-atari-mint/
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

GCCARCHIVE=gcc-4.6.4.tar.bz2
GCCURL=$(VRIVIEREURLBASE)$(GCCARCHIVE)
GCCPATCH=gcc-4.6.4-mint-20130415.patch.bz2
GCCPATCHURL=$(VRIVIEREURLBASE)$(GCCPATCH)
GCCPACKAGE=gcc-4.6.4-mint-20130415$(VERSIONBIN).tar.bz2

MINTLIBARCHIVE=mintlib-CVS-20160320.tar.gz
MINTLIBURL=$(VRIVIEREURLBASE)$(MINTLIBARCHIVE)
MINTLIBPACKAGE=mintlib-CVS-20160320$(VERSIONBIN).tar.bz2

PMLARCHIVE=pml-2.03.tar.bz2
PMLURL=$(VRIVIEREURLBASE)$(PMLARCHIVE)
PMLPATCH=pml-2.03-mint-20110207.patch.bz2
PMLPATCHURL=$(VRIVIEREURLBASE)$(PMLPATCH)
PMLPACKAGE=pml-2.03-min-20110207t$(VERSIONBIN).tar.bz2

all:	archives build binutils mintbin gcc mintlib pml

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

archives/$(GCCARCHIVE):
	cd archives; $(URLGET) $(GCCURL)

archives/$(GCCPATCH):
	cd archives; $(URLGET) $(GCCPATCHURL)

archives/$(MINTLIBARCHIVE):
	cd archives; $(URLGET) $(MINTLIBURL)

archives/$(PMLARCHIVE):
	cd archives; $(URLGET) $(PMLURL)

archives/$(PMLPATCH):
	cd archives; $(URLGET) $(PMLPATCHURL)

binutils:	build/$(BINUTILSPACKAGE)

build/$(BINUTILSPACKAGE):	archives/$(BINUTILSARCHIVE) archives/$(BINUTILSPATCH)
	VERSIONBIN="$(VERSIONBIN)" INSTALL_DIR="$(INSTALL_DIR)" ./binutils-mint-build.sh

mintbin:	build/$(MINTBINPACKAGE)

build/$(MINTBINPACKAGE):	archives/$(MINTBINARCHIVE)
	VERSIONBIN="$(VERSIONBIN)" INSTALL_DIR="$(INSTALL_DIR)" ./mintbin-mint-build.sh

gcc:	build/$(GCCPACKAGE)

build/$(GCCPACKAGE):	archives/$(GCCARCHIVE) archives/$(GCCPATCH) archives/$(MINTLIBARCHIVE) archives/$(PMLARCHIVE) archives/$(PMLPATCH)
	VERSIONBIN="$(VERSIONBIN)" INSTALL_DIR="$(INSTALL_DIR)" ./gcc-mint-build.sh

mintlib:	build/$(MINTLIBPACKAGE)

build/$(MINTLIBPACKAGE):
	echo "Should be built alongside GCC"
	exit 1

pml:	build/$(PMLPACKAGE) archives/$(PMLPATCH)

build/$(PMLPACKAGE):
	echo "Should be built alongside GCC"
	exit 1
