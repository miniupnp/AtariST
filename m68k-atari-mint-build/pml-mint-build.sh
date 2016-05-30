#!/bin/sh
# This is a semi-automatic script for building the binary packages.
# It is designed to be run on Cygwin,
# but it should run fine on Linux and other GNU environments.

set -x

ARCHIVES_DIR=$PWD/archives
BUILD_DIR=$PWD/build
PACKAGENAME=pml
VERSION=-2.03
VERSIONPATCH=-mint-20110207
#VERSIONBUILD=-`date +%Y%m%d`

cd $BUILD_DIR
if [ ! -d $PACKAGENAME$VERSION$VERSIONPATCH ] ; then
	tar jxvf "$ARCHIVES_DIR/$PACKAGENAME$VERSION.tar.bz2" || exit 1
	mv $PACKAGENAME$VERSION $PACKAGENAME$VERSION$VERSIONPATCH
fi
cd $PACKAGENAME$VERSION$VERSIONPATCH
if [ ! -f pmlsrc/Makefile ] ; then
	bzcat "$ARCHIVES_DIR/$PACKAGENAME$VERSION$VERSIONPATCH.patch.bz2" |patch -p1
fi
cd pmlsrc

sed -i "s:^\(CROSSDIR =\).*:\1 $INSTALL_DIR:g" Makefile Makefile.32 Makefile.16
sed -i "s:^\(CC =\).*:\1 m68k-atari-mint-gcc:g" Makefile Makefile.32 Makefile.16
sed -i "s:^\(AR =\).*:\1 m68k-atari-mint-ar:g" Makefile Makefile.32 Makefile.16

######################################
# If you are currently compiling GCC,
# and it is not installed yet:
######################################
GCC_BUILD_DIR="$BUILD_DIR/gcc-4.6.4-mint-20130415$VERSIONBIN"
#sed -i "s:^CC = .*:CC = $GCC_BUILD_DIR/gcc/xgcc -B$GCC_BUILD_DIR/gcc/ -B$INSTALL_DIR/bin/ -B$INSTALL_DIR/lib/ -isystem $INSTALL_DIR/include -isystem $INSTALL_DIR/sys-include:g" Makefile.32 Makefile.16
sed -i "s:^CC = .*:CC = $GCC_BUILD_DIR/gcc/xgcc -B$GCC_BUILD_DIR/gcc/ -B$INSTALL_DIR/bin/ -B$INSTALL_DIR/lib/ -isystem $BUILD_DIR/mintlib-CVS-20160320/binary-package/$INSTALL_DIR/include -isystem $INSTALL_DIR/sys-include:g" Makefile.32 Makefile.16
######################################

for f in Makefile Makefile.16 Makefile.32; do
	if [ -f "$f.bak" ] ; then
		cp "$f.bak" "$f"
	fi
done
# 1st pass for compiling m68000 libraries
make || exit 1
make install CROSSDIR=$PWD/binary-package$INSTALL_DIR || exit 1

# 2nd pass for compiling m68020-60 libraries
make clean || exit 1
for f in Makefile Makefile.16 Makefile.32; do
	cp "$f" "$f.bak"
done
sed -i "s:^\(CFLAGS =.*\):\1 -m68020-60:g" Makefile.32 Makefile.16
sed -i "s:^\(CROSSLIB =.*\):\1/m68020-60:g" Makefile
make || exit 1
make install CROSSDIR=$PWD/binary-package$INSTALL_DIR || exit 1

# 3rd pass for compiling ColdFire V4e libraries
make clean || exit 1
sed -i "s:-m68020-60:-mcpu=5475:g" Makefile.32 Makefile.16
sed -i "s:m68020-60:m5475:g" Makefile
make || exit 1
make install CROSSDIR=$PWD/binary-package$INSTALL_DIR || exit 1

cd binary-package
find ${INSTALL_DIR#/}/lib -name '*.a' -print -exec m68k-atari-mint-strip -S -x '{}' ';'

tar --owner=0 --group=0 -jcvf ../../../$PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN$VERSIONBUILD.tar.bz2 ${INSTALL_DIR#/}
