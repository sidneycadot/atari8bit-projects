
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
                sta     NMIEN   ; Disable NMI interrupts (the only spontaneous interrupts on the Atari).
                sta     IRQEN   ; Disable IRQ interrupts..
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

                ; Enable VBLANK NMI.

                lda     #64
                sta     NMIEN

HALT:           pha
                pla
                jmp HALT

COUNTER1:       .res 1
COUNTER2:       .res 1

NMI_ISR:        pha
                txa
                pha

                sta     WSYNC
                
                inc     COUNTER1
                lda     COUNTER1
                sta     COUNTER2

L1:             lda     VCOUNT
                cmp     #5
                bne     L1

                lda     #34
                sta     COLBK

                lda     #<1050
                ldx     #>1050

                jsr     cycle_delay

                .repeat 20
                sta     WSYNC
                lda     #12
                sta     COLBK

                sta     WSYNC
                lda     #14
                sta     COLBK
                .endrep

                sta     WSYNC
                lda     #202
                sta     COLBK

                pla
                tax
                pla
                rti
