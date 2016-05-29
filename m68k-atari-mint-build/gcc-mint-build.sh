#!/bin/sh
# This is a semi-automatic script for building the binary packages.
# It is designed to be run on Cygwin,
# but it should run fine on Linux and other GNU environments.

set -x

ARCHIVES_DIR=$PWD/archives
BUILD_DIR=$PWD/build
PACKAGENAME=gcc
VERSION=-4.6.4
VERSIONPATCH=-mint-20130415
#VERSIONBUILD=-`date +%Y%m%d`

cd $BUILD_DIR
if [ ! -d $PACKAGENAME$VERSION$VERSIONPATCH ]; then
	tar jxvf "$ARCHIVES_DIR/$PACKAGENAME$VERSION.tar.bz2" || exit 1
	mv $PACKAGENAME$VERSION $PACKAGENAME$VERSION$VERSIONPATCH
fi
cd $PACKAGENAME$VERSION$VERSIONPATCH
bzcat "$ARCHIVES_DIR/$PACKAGENAME$VERSION$VERSIONPATCH.patch.bz2" |patch -p1
cd ..

mkdir $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
cd $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
if [ ! -f Makefile ]; then
../$PACKAGENAME$VERSION$VERSIONPATCH/configure --target=m68k-atari-mint --prefix=$INSTALL_DIR --enable-languages="c,c++" --disable-nls --disable-libstdcxx-pch CFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer" CXXFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer"
fi

make all-gcc || exit 1

# The temporary compiler is very slow on Cygwin (it will be fast when fully installed)
# The following hack can sometimes increase the compilation speed
# by avoiding a shell wrapper for "as".
#rm gcc/as && ln -s $INSTALL_DIR/bin/m68k-atari-mint-as gcc/as

make all-target-libgcc || exit 1

######################################
# Now, open another terminal window, and compile and install the MiNTlib from there.
# Do the same with PML.
# Then go back here.
######################################
echo "TODO !!!"
exit 1

# Dirty hack to fix the PATH_MAX issue.
# The good solution would be to configure gcc using --with-headers
cat ../$PACKAGENAME$VERSION$VERSIONPATCH/gcc/limitx.h ../$PACKAGENAME$VERSION$VERSIONPATCH/gcc/glimits.h ../$PACKAGENAME$VERSION$VERSIONPATCH/gcc/limity.h >gcc/include-fixed/limits.h

make || exit 1
make install DESTDIR=$PWD/binary-package

cd binary-package
rm -vr ${INSTALL_DIR#/}/include
rm -v   ${INSTALL_DIR#/}/lib/*.a
rm -vr ${INSTALL_DIR#/}/share/info
rm -vr ${INSTALL_DIR#/}/share/man/man7
strip ${INSTALL_DIR#/}/bin/*
strip ${INSTALL_DIR#/}/libexec/gcc/m68k-atari-mint/${VERSION#-}/*
strip ${INSTALL_DIR#/}/libexec/gcc/m68k-atari-mint/${VERSION#-}/install-tools/*
find ${INSTALL_DIR#/}/m68k-atari-mint/lib -name '*.a' -print -exec m68k-atari-mint-strip -S -x '{}' ';'
find ${INSTALL_DIR#/}/lib/gcc/m68k-atari-mint/* -name '*.a' -print -exec m68k-atari-mint-strip -S -x '{}' ';'
gzip -9 ${INSTALL_DIR#/}/share/man/*/*.1

tar --owner=0 --group=0 -jcvf ../../$PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN$VERSIONBUILD.tar.bz2 ${INSTALL_DIR#/}
