
DOSVEC          := $0A
COLBK           := $D01A
CONSOL          := $D01F
DMACTL          := $D400
NMIEN           := $D40E


                .import cycle_delay

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   8               ; Number of sectors.
                .word   boot_sector     ; load address.
                .word   init            ; initialization address (copied to DOSINI).

                lda     #<start
                sta     DOSVEC+0
                lda     #>start
                sta     DOSVEC+1

                clc
init:           rts

                .code

start:          lda     #0
                sta     NMIEN   ; Disable NMI interrupts.
                sta     DMACTL  ; Disable graphics DMA.

COUNTER1:       .word 0
COUNTER2:       .word 0
COUNTER3:       .word 0

                PERIOD = 24 * 105
                OVERHEAD = 117
                CYCLE_DELAY_MINIMUM = 34
                MASK = $3ff

                lda     #<135
                ldx     #>135
                jsr     cycle_delay

LOOP:           clc                             ; COUNTER1 = (COUNTER1 + 1) & MASK
                lda     COUNTER1+0
                adc     #<1
                sta     COUNTER1+0
                lda     COUNTER1+1
                adc     #>1
                sta     COUNTER1+1

                lda     COUNTER1+0
                and     #<MASK
                sta     COUNTER1+0
                lda     COUNTER1+1
                and     #>MASK
                sta     COUNTER1+1
                
                clc                             ; COUNTER2 = COUNTER1 + CYCLE_DELAY_MINIMUM
                lda     COUNTER1+0
                adc     #<CYCLE_DELAY_MINIMUM
                sta     COUNTER2+0
                lda     COUNTER1+1
                adc     #>CYCLE_DELAY_MINIMUM
                sta     COUNTER2+1

                sec                             ; COUNTER3 = PERIOD - OVERHEAD - COUNTER2
                lda     #<(PERIOD - OVERHEAD)
                sbc     COUNTER2+0
                sta     COUNTER3+0
                lda     #>(PERIOD - OVERHEAD)
                sbc     COUNTER2+1
                sta     COUNTER3+1

                lda     #14
                sta     COLBK

                lda     COUNTER2+0
                ldx     COUNTER2+1
                jsr     cycle_delay

                lda     #0
                sta     COLBK

                lda     COUNTER3+0
                ldx     COUNTER3+1
                jsr     cycle_delay

                jmp     LOOP
