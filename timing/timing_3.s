
DOSVEC          := $0A
COLBK           := $D01A
CONSOL          := $D01F
IRQEN           := $D20E
PORTA           := $D300
PORTB           := $D301
PACTL           := $D302
DMACTL          := $D400
WSYNC           := $D40A
VCOUNT          := $D40B
NMIEN           := $D40E

                .import cycle_delay

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   8               ; Number of sectors.
                .word   boot_sector     ; load address.
                .word   init            ; initialization address (copied to DOSINI).

                clc
                rts

                .code

init:           lda     #0
                sta     NMIEN   ; Disable NMI interrupts.
                sta     IRQEN   ; Disable IRQ interrupts.
                sta     DMACTL  ; Disable graphics DMA.

                ; Turn ROM into RAM.

                lda     PORTB
                and     #$FE
                sta     PORTB

                ; Set NMI vector.

                lda     #<NMI_ISR
                sta     $FFFA
                lda     #>NMI_ISR
                sta     $FFFB
                
                ; Re-enable VBLANK NMI.

                lda     #64
                sta     NMIEN

HALT:           pha
                pla
                jmp     HALT

COUNTER1:       .word 0
COUNTER2:       .word 0
COUNTER3:       .word 0

                CYCLE_DELAY_MINIMUM = 33

NMI_ISR:        pha
                txa
                pha

                sta     WSYNC

                lda     #14
                sta     COLBK

                clc                     ; COUNTER1 = (COUNTER1 + 1) % 0x400
                lda     COUNTER1+0
                adc     #<1
                sta     COUNTER1+0
                lda     COUNTER1+1
                adc     #>1
                and     #3
                sta     COUNTER1+1

                clc                     ; COUNTER2 = COUNTER1 + CYCLE_DELAY_MINIMUM
                lda     COUNTER1+0
                adc     #<CYCLE_DELAY_MINIMUM
                sta     COUNTER2+0
                lda     COUNTER1+1
                adc     #>CYCLE_DELAY_MINIMUM
                sta     COUNTER2+1

                sec                     ; COUNTER3 = 12000 - COUNTER2
                lda     #<12000
                sbc     COUNTER2+0
                sta     COUNTER3+0
                lda     #>12000
                sbc     COUNTER2+1
                sta     COUNTER3+1

                lda     #202
                sta     COLBK

                lda     #<10030
                ldx     #>10030
                jsr     cycle_delay

                lda     #14
                sta     COLBK

                lda     COUNTER2+0
                ldx     COUNTER2+1
                jsr     cycle_delay

                lda     #34
                sta     COLBK

                lda     COUNTER3+0
                ldx     COUNTER3+1
                jsr     cycle_delay

                lda     #0
                sta     COLBK

                pla
                tax
                pla
                rti
