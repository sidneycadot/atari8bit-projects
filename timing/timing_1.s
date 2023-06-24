
; timing_1.s
;
; - Disable interrupts and DMA.
; - Set PORTA as digital output.
; - Cycle through PORTA values.
; - Each full cycle will either take 20 cycles (START not pressed) or 21 cycles (START pressed).
; - We can use this to measure the number of CPU cycles per second, by looking at the I/O pins.

DOSVEC          := $0A
COLBK           := $D01A
CONSOL          := $D01F
PORTA           := $D300
PACTL           := $D302
DMACTL          := $D400
NMIEN           := $D40E

                .segment "bootcode"

boot_sector:    .byte   0               ; The boot option byte is always zero.
                .byte   1               ; 1 sector for the bootloader.
                .word   boot_sector     ; load address.
                .word   init            ; initialization address (copied to DOSINI).

                lda     #<start
                sta     DOSVEC+0
                lda     #>start
                sta     DOSVEC+1

                clc
init:           rts

start:          lda     #0
                sta     NMIEN   ; Disable NMI interrupts (the only spontaneous interrupts on the Atari).
                sta     DMACTL  ; Disable graphics DMA.

                lda     PACTL   ; Set bit 2 of PACTL to zero.
                and     #$FB    ; This makes PORTA into a direction register.
                sta     PACTL

                lda     #$FF    ; Configure all PORTA lines as DIGITAL OUTPUT.
                sta     PORTA

                lda     PACTL   ; Set bit 2 of PACTL to one.
                ora     #$04    ; This makes PORTA into a DOUT register.
                sta     PACTL

                ldy     #0
loop:           sty     PORTA   ; [4]   Digital output.
                sty     COLBK   ; [4]   Background color, to see something happening.
                iny             ; [2]
                lda     CONSOL  ; [4]   Rightmost bit of CONSOL tells us if the START button is *not* pressed.
                lsr             ; [2]   Transfer this bit to the carry.
                bcc     wait    ; [2/3] If carry is clear (START pressed), this takes one more cycle
wait:           jmp     loop    ; [3]     compared to the bcc 'fallthrough' case.
