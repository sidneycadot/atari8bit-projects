
DOSVEC          := $0A
COLBK           := $D01A
CONSOL          := $D01F
PORTA           := $D300
PACTL           := $D302
DMACTL          := $D400
WSYNC           := $D40A
VCOUNT          := $D40B
NMIEN           := $D40E

                .import cycle_delay

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   1               ; 1 sector for the bootloader.
                .word   boot_sector     ; load address.
                .word   init            ; initialization address (copied to DOSINI).

                clc
                rts

                .code

init:           lda     #0
                sta     NMIEN   ; Disable NMI interrupts (the only spontaneous interrupts on the Atari).
                sta     DMACTL  ; Disable graphics DMA.

LOOP:           sta     WSYNC
                lda     VCOUNT
