#!/bin/sh
set -x

ARCHIVES_DIR=$PWD/archives
BUILD_DIR=$PWD/build
PACKAGENAME=binutils
VERSION=-2.26
VERSIONPATCH=-mint-20160320

cd $BUILD_DIR
tar jxvf "$ARCHIVES_DIR/$PACKAGENAME$VERSION.tar.bz2"
mv $PACKAGENAME$VERSION $PACKAGENAME$VERSION$VERSIONPATCH
cd $PACKAGENAME$VERSION$VERSIONPATCH
bzcat "$ARCHIVES_DIR/$PACKAGENAME$VERSION$VERSIONPATCH.patch.bz2" |patch -p1
cd ..

mkdir $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
cd $PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN
../$PACKAGENAME$VERSION$VERSIONPATCH/configure --target=m68k-atari-mint --prefix=$INSTALL_DIR --disable-nls
make

make install DESTDIR=$PWD/binary-package
cd binary-package
rm    ${INSTALL_DIR#/}/bin/m68k-atari-mint-readelf*
rm    ${INSTALL_DIR#/}/bin/m68k-atari-mint-elfedit*
rm    ${INSTALL_DIR#/}/m68k-atari-mint/bin/readelf*
rm -r ${INSTALL_DIR#/}/share/info
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-dlltool.1
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-nlmconv.1
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-readelf.1
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-elfedit.1
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-windmc.1
rm    ${INSTALL_DIR#/}/share/man/man1/m68k-atari-mint-windres.1
strip ${INSTALL_DIR#/}/bin/*
gzip -9 ${INSTALL_DIR#/}/share/man/*/*.1

tar --owner=0 --group=0 -jcvf ../../$PACKAGENAME$VERSION$VERSIONPATCH$VERSIONBIN$VERSIONBUILD.tar.bz2 ${INSTALL_DIR#/}
