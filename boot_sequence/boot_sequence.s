
        ; The first disk sector has a six-byte header.

        .import __program_RUN__
        .import __program_LOAD__
        .import __program_SIZE__

        DOSVEC  := $0A
        DOSINI  := $0C

        .segment "boot_sector"

boot_sector:    .byte   0               ; BFLAG -- unused
                .byte   1               ; BRCNT -- number of sectors to be read
                .word   boot_sector     ; Boot sector load address.
                .word   dosini_address  ; Initialization address

                ; This code is only executed right after the initial load.
                ; It is *not* executed on a warm restart.
                ; So, this is a very good place to move the program memory to the right place.

                lda     #34
                sta     712
                jsr     lo_wait

                ; Copy the main program to its destination address.

                ldx     #<__program_SIZE__
@copy:          lda    __program_LOAD__-1,x
                sta    __program_RUN__-1,x
                dex
                bne    @copy

                ; Initialize DOSVEC.

                lda     #<program
                sta     DOSVEC+0
                lda     #>program
                sta     DOSVEC+1

                clc             ; We should end with the carry clear, otherwise we get a boot error, and a new attempt to boot will be made.
                rts

lo_wait:        lda     #4
                ldx     #0
                ldy     #0
@loop:          iny
                bne     @loop
                inx
                bne     @loop
                sec
                sbc     #1
                bne     @loop
                rts

                .segment "program"

dosini_address: lda     #108
                sta     712
                jsr     hi_wait
                rts

program:        ; This is executed second.

                lda     #202
                sta     712
                jsr     hi_wait                
@loop:          lda     53770
                sta     53272
                
                lda     53279
                lsr
                bcs     @loop

                ; In case we've been started from BASIC ("DOS" command) we can
                ; go back by executing an rts. However, if we've been started from
                ; the OS during boot, we cannot -- there is no return address on the stack.

                tsx
                cpx     #$ff    ; stack empty?
                beq     stack_empty
                rts

stack_empty:    lda     #14
                sta     53272
                lda     #34
                sta     53272
                jmp     stack_empty

hi_wait:        lda     #4
                ldx     #0
                ldy     #0
@loop:          iny
                bne     @loop
                inx
                bne     @loop
                sec
                sbc     #1
                bne     @loop
                rts
