
PAL Atari, measurements
=======================

Atari 65 XE.

DMA and NMI interrupts disabled during measurements.

Total cycles per second:

    1773420.0 Hz.
    1773423.0 Hz.

Screen frames per second:

     49.860143 Hz.

CPU cycles per line: 105
Lines per frame: 312


POKEY, 8-bits divider:

    f_out = (f_clk / 56) / (divider + 0)

POKEY, 16-bit divider (joint channels):

    f_out = (f_clk / 2) / (divider + 7)

NOTE: we can measure (CLK/1000) directly by joining two POKEY channels,
      setting the divider to 493, and measuring the resulting audio frequency:

10 POKE 53768,80
20 POKE 53763,175
30 POKE 53760,237
40 POKE 53762,1
50 STOP
