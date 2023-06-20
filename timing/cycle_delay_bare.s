
                       .org $FEDA

FEDA:                  cpx  #0
                       bne  FEEE
                       sbc  #34
FEE0:                  lsr
                       bcs  FEE3
FEE3:                  lsr
                       bcc  FEE8
                       bcs  FEE8
FEE8:                  lsr
                       bcc  FEFE
                       nop
                       bcs  FEFE
FEEE:                  clc
                       nop
FEF0:                  sbc  #8
                       bcs  FEEE
                       dex
                       bne  FEF0
                       sbc  #40
                       bcs  FEE0
FEFB:                  sec
                       sbc  #1
FEFE:                  bne  FEFB
                       rts
