
PAL Atari, measurements
=======================

Atari 65 XE.

DMA and NMI interrupts disabled during measurements.

Total cycles per second:

    1773420.0 Hz.

Screens per second:

     49.860143 Hz.

CPU cycles per line: 105
Lines per screen period: 312


POKEY, 8-bits divider:

    f_out = (f_clk / 56) / (divider + 0)

POKEY, 16-bit divider (joint channels):

    f_out = (f_clk / 2) / (divider + 7)

NOTE: we can measure (CLK/1000) directly by setting the divider to 493,
and measuring the resulting audio frequency.
