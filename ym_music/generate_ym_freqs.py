#!/usr/bin/env python3
# vim: set sw=4 ts=4 expandtab:
# see https://en.wikipedia.org/wiki/MIDI_tuning_standard

# d = MIDI note number
# f = frequency in Hz
# ym_t = 12bits tone value for YM2149
# 125000 = 2MHz / 16
def ym_midi_freqs():
    for d in range(0, 128):
        f = pow(2, (d - 69) / 12) * 440
        ym_t = round(125000 / f)
        if ym_t > 4095:
            ym_t = 0
        yield (d, f, ym_t)

print("ym_midi_notes:")
for (d, f, ym_t) in ym_midi_freqs():
    print("\tdc.w\t{}\t; note #{:03} {:5}Hz".format(ym_t, d, round(f)))
