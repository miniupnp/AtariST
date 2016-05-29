#!/bin/sh
# This is a semi-automatic script for building the binary packages.
# It is designed to be run on Cygwin,
# but it should run fine on Linux and other GNU environments.

set -x

ARCHIVES_DIR=$PWD/archives
BUILD_DIR=$PWD/build
PACKAGENAME=mintbin
VERSION=-CVS-20110527
VERSIONPATCH=

cd $BUILD_DIR
tar zxvf "$ARCHIVES_DIR/$PACKAGENAME$VERSION.tar.gz" || exit 1

mkdir $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
cd $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
../$PACKAGENAME$VERSION$VERSIONPATCH/configure --target=m68k-atari-mint --prefix=$INSTALL_DIR --disable-nls
make

make install DESTDIR=$PWD/binary-package
cd binary-package
rm m68k-atari-mint-*
rm -r ${INSTALL_DIR#/}/info
mkdir ${INSTALL_DIR#/}/bin
mv ${INSTALL_DIR#/}/m68k-atari-mint/bin/* ${INSTALL_DIR#/}/bin
rmdir ${INSTALL_DIR#/}/m68k-atari-mint/bin
rm -r ${INSTALL_DIR#/}/m68k-atari-mint
strip ${INSTALL_DIR#/}/bin/*

tar --owner=0 --group=0 -jcvf ../../$PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN$VERSIONBUILD.tar.bz2 ${INSTALL_DIR#/}
