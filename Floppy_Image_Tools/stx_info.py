#!/usr/bin/env python
# vim: tabstop=2 shiftwidth=2 softtabstop=2 expandtab
#
# (c) 2018 Thomas BERNARD
# STX (Pasti) floppy image analyzer
#

from struct import *
import sys

def parse_stx(filename):
  print 'file',filename
  with open(filename, 'rb') as f:
    stxdata = f.read()
    signature = stxdata[0:4]
    version,tool,res1,trackCount,revision = unpack_from('<HHHBB', stxdata, 4)
    print len(stxdata), "bytes"
    print 'signature %s version %d rev %d tool %04X' % (signature, version, revision, tool)
    if signature != 'RSY\0':
      print "unrecognized file signature"
      return
    if version < 3:
      print 'STX version %d not supported' % (version)
      return
    tmp = ('2 sides of %d tracks each' % (trackCount / 2)) if trackCount > 85 else '1 side';
    print ' %d tracks (%s)' % (trackCount, tmp)
    offset = 16
    for track in range(0, trackCount):
      # track descriptor
      size,fuzzyCount,sectorCount,trackFlags,trackLength,trackNumber,trackType = unpack_from('<LLHHHBB', stxdata, offset)
      o = 16
      #print 'track#%d' % track, size, fuzzyCount, sectorCount, '%02X' % trackFlags
      print 'track#%d size=%d fuzzyCount=%d sectorCount=%d Flags $%02X' % (track, size, fuzzyCount, sectorCount, trackFlags)
      if (trackFlags & 1) != 0 and sectorCount > 0:
        print '    offset bitPos time  t h  n size CRC flags'
        for sector in range(0, sectorCount):
          # sector descriptor
          dataOffset, bitPosition, readTime, t,h,n,s,crc, fdcFlags, res = unpack_from('<LHHBBBBHBB', stxdata, offset + o)
          o += 16
          #print '  #%d' % sector, dataOffset, bitPosition, readTime, t, h, n, 128 << s, '$%04X' % crc, '%02X' %fdcFlags
          print '  #%d %5d %5d %5d %02d %d %2d %4d $%04X $%02X' % (sector, dataOffset, bitPosition, readTime, t, h, n, 128 << s, crc, fdcFlags)
      # Fuzzy Mask record
      o += fuzzyCount
      if (trackFlags & 0x40) != 0:
        # Track image
        if (trackFlags & 0x80) != 0:
          FirstSyncOffset, = unpack_from('<H', stxdata, offset + o)
          o += 2
        else:
          FirstSyncOffset = 0
        TrackImageSize, = unpack_from('<H', stxdata, offset + o)
        o += 2
        # TrackImageData is at offset + o
        SectorDataOffsetBase = o
        print ' $%06X TrackImageSize=%d FirstSyncOffset=%d' % (offset + o, TrackImageSize, FirstSyncOffset)
        o += TrackImageSize
      else:
        SectorDataOffsetBase = o
      print o, size - o, SectorDataOffsetBase
      offset += size

if len(sys.argv) < 2:
  print 'Usage: %s <file.stx>' % sys.argv[0]
else:
  parse_stx(sys.argv[1])
