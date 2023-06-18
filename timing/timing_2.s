
                ; timing_2.s
                ;
                ; Test our understanding of the Atari clock-cycle usage while generating the screen,
                ; as well as our nifty 'cycle_delay' implementation.

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

                ; Basic screen timing of a PAL Atari 8-bit machine:
                ;   105 CPU cycles for a full line.
                ;   312 lines in screen period.
                ;   ==> 32760 cycles per screen period.

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   64              ; Number of sectors.
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
                sta     NMIEN
                sta     DMACTL

                lda     PACTL       ; Set bit 2 of PACTL to zero.
                and     #$FB        ; This makes PORTA into a direction register.
                sta     PACTL

                lda     #$FF        ; Configure all PORTA lines as DIGITAL OUTPUT.
                sta     PORTA

                lda     PACTL       ; Set bit 2 of PACTL to one.
                ora     #$04        ; This makes PORTA into a DOUT register.
                sta     PACTL

HORIZONTAL:     .scope

                CYCLES1 = 156 * 105 - 16
                CYCLES2 = 156 * 105 - 25

                jsr     SYNC

RED:            lda     #34         ; [2]
                sta     COLBK       ; [4]
                lda     #255        ; [2]
                sta     PORTA       ; [4]

                lda     #<CYCLES1   ; [2]
                ldx     #>CYCLES1   ; [2]
                jsr     cycle_delay ; [-]

YELLOW:         lda     #202        ; [2]
                sta     COLBK       ; [4]
                lda     #0          ; [2]
                sta     PORTA       ; [4]

                lda     #<CYCLES2   ; [2]
                ldx     #>CYCLES2   ; [2]
                jsr     cycle_delay ; [-]

                lda     CONSOL      ; [3]
                and     #1          ; [2]
                bne     RED         ; [3]

                .endscope

VERTICAL:      .scope

                CYCLES1 = 1 * 105 - 16
                CYCLES2 = 1 * 105 - 25

                jsr SYNC

RED:            lda     #34         ; [2]
                sta     COLBK       ; [4]
                lda     #255        ; [2]
                sta     PORTA       ; [4]

                lda     #<CYCLES1   ; [2]
                ldx     #>CYCLES1   ; [2]
                jsr     cycle_delay ; [-]

YELLOW:         lda     #202        ; [2]
                sta     COLBK       ; [4]
                lda     #0          ; [2]
                sta     PORTA       ; [4]

                lda     #<CYCLES2   ; [2]
                ldx     #>CYCLES2   ; [2]
                jsr     cycle_delay ; [-]

                lda     CONSOL      ; [3]
                and     #2          ; [2]
                bne     RED         ; [3]
                beq     HORIZONTAL

                .endscope

SYNC:           .scope

L1:             lda     VCOUNT
                cmp     #10
                bne     L1
                sta     WSYNC

L2:             lda     VCOUNT
                cmp     #20
                bne     L2
                sta     WSYNC

L3:             lda     VCOUNT
                cmp     #30
                bne     L3
                sta     WSYNC

                rts

                .endscope
