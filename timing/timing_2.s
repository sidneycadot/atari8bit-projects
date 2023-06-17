
DOSVEC          := $0A
COLBK           := $D01A
CONSOL          := $D01F
PORTA           := $D300
PACTL           := $D302
DMACTL          := $D400
NMIEN           := $D40E

                .import cycle_delay

                ; Basic screen timing of a PAL Atari 8-bit machine:
                ;   105 CPU cycles for a full line.
                ;   312 lines in screen period.
                ;   ==> 32760 cycles per screen period.

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   2               ; 1 sector for the bootloader.
                .word   boot_sector     ; load address.
                .word   init            ; initialization address (copied to DOSINI).

                lda     #<start
                sta     DOSVEC+0
                lda     #>start
                sta     DOSVEC+1

                clc
init:           rts

                .code

start:          lda #0
                sta NMIEN
                sta DMACTL

                CYCLES1 = 10000
                CYCLES2 = 32760 - CYCLES1 - 23

LOOP:           lda     #34         ; [2]
                sta     COLBK       ; [4]

                lda     #<CYCLES1   ; [2]
                ldx     #>CYCLES1   ; [2]
                jsr     cycle_delay ; [-]

                lda     #202        ; [2]
                sta     COLBK       ; [4]

                lda     #<CYCLES2   ; [2]
                ldx     #>CYCLES2   ; [2]
                jsr     cycle_delay ; [-]

                jmp     LOOP        ; [3]
