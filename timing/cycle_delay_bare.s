
                .org $F0E7

LF0E7:          cpx  #0
                bne  LF101
                sbc  #30
LF0ED:          lsr
                bcs  LF0F0
LF0F0:          lsr
                bcs  LF0F5
                bcs  LF0F5
LF0F5:          lsr
                bcc  LF0FB
                nop
                bcs  LF0FB
LF0FB:          sec
                sbc  #1
                bne  LF0FB
                rts
LF101:          clc
                nop
LF103:          sbc  #8
                bcs  LF101
                dex
                bne  LF103
                sbc  #39
                bcs  LF0ED
