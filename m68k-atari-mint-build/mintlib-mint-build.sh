#!/bin/sh

# This is a semi-automatic script for building the binary packages.
# It is designed to be run on Cygwin,
# but it should run fine on Linux and other GNU environments.

set -x

ARCHIVES_DIR=$PWD/archives
BUILD_DIR=$PWD/build
PACKAGENAME=mintlib
VERSION=-CVS-20160320
VERSIONPATCH=
#VERSIONBUILD=-`date +%Y%m%d`

cd "$BUILD_DIR"
tar zxvf "$ARCHIVES_DIR/$PACKAGENAME$VERSION.tar.gz"
cd $PACKAGENAME$VERSION$VERSIONPATCH

BINARY_BASE=$PWD/binary-package$INSTALL_DIR
sed -i "s:^\( prefix=\)/usr/m68k-atari-mint.*:\1$BINARY_BASE:g" configvars
sed -i "s:^#CROSS=yes$:CROSS=yes:g" configvars

######################################
# If you are currently compiling GCC,
# and it is not installed yet:
######################################
GCC_BUILD_DIR="$BUILD_DIR/gcc-4.6.4-mint-20130415$VERSIONBIN"
sed -i "s:^CC=.*:CC=$GCC_BUILD_DIR/gcc/xgcc -B$GCC_BUILD_DIR/gcc/ -B$INSTALL_DIR/bin/ -B$INSTALL_DIR/lib/ -isystem $INSTALL_DIR/include -isystem $INSTALL_DIR/sys-include:g" configvars
echo "$GCC_BUILD_DIR/gcc/include -I$GCC_BUILD_DIR/gcc/include-fixed" >includepath
######################################

make || exit 1

mkdir -p $BINARY_BASE
make install || exit 1
cd binary-package
rm -r ${INSTALL_DIR#/}/share
find ${INSTALL_DIR#/}/lib '(' -name '*.a' -o -name '*.o' ')' -print -exec m68k-atari-mint-strip -S -x '{}' ';'

tar --owner=0 --group=0 -jcvf ../../$PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN$VERSIONBUILD.tar.bz2 ${INSTALL_DIR#/}
