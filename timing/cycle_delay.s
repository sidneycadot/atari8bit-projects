
                ; =================================================================
                ; =                                                               =
                ; =                        cycle_delay                            =
                ; =                                                               =
                ; =================================================================
                ;
                ; On entry, A contains the low byte and X the high byte of a 16-bit
                ; unsigned cycle count.
                ;
                ; The routine (including the calling 'jsr' instruction) will
                ; consume the specified amount of CPU clock cycles.
                ;
                ; The routine preserves all registers, including processor flags.
                ;
                ; The minimum number of clock cycles that can be specified as a
                ; delay is 56. Behavior for values below 56 is undefined.
                ;
                ; Example
                ; -------
                ;
                ; Three instructions that together take precisely 10,000 cycles:
                ;
                ;           lda #<9996      ; 2 cycles.
                ;           ldx #>9996      ; 2 cycles.
                ;           jsr cycle_delay ; 9996 cycles.

                .export cycle_delay

                .code

cycle_delay:    .scope

                php                 ; [3] Save processor status flags.
                pha                 ; [3] Save A register.

                cpx     #0          ; [2] If the specified delay exceeds 255,
                bne     long_delay  ; [2]   jump to "long_delay" for further processing.

                sec                 ; [2] Handle short delay. A should be >= 56 here.
                sbc     #48         ; [2] Subtracting 48 will result in X==1 when entering the "loop8" loop below.

                lsr                 ; [2] Divide A by 2.
                bcs     s_div2done  ; [2] If bit shifted out is 1, burn an extra cycle.

s_div2done:     lsr                 ; [2] Divide A by 2.
                bcc     s_div4done  ; [C=0: 3, C=1: 2]  If bit shifted out is 1, burn two extra cycles.
                bcs     s_div4done  ; [C=0: 0, C=1: 3]

s_div4done:     lsr                 ; [2] Divide A by 2.
                bcc     s_div8done  ; [C=0: 3, C=1: 2]  If bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     s_div8done  ; [C=0: 0, C=1: 3]

s_div8done:     tax                 ; [2] Load number of 8-cycle loops to execute.
s_loop8:        dex                 ; [2] Spend 8 cycles (assuming X != 1 on entry, otherwise 6).
                bne s_burn3         ; [Z=0: 3, Z=1: 2]
s_burn3:        bne s_loop8         ; [Z=0: 3, Z=1: 2] When leaving the loop, X will be zero (as it originally was).

s_restore:      pla                 ; [4] Restore A register.
                plp                 ; [4] Restore processor status flags.
                rts                 ; [6] All done.

long_delay:     ; On entry, P and A have already been saved on the stack, and we know that X is not equal to 0.
                ; We still need to save X.

                txa                 ; [2] Save X on the stack.
                pha                 ; [3]

                ; Retrieve saved values of A and X by direct access into the stack page.

                tsx                 ; [2] Stack pointer to X register.
                inx                 ; [2] Increment X twice to point to saved A register.
                inx                 ; [2]
                lda     $100,x      ; [4] Load original value of A.
                pha                 ; [3] Push it onto the stack.
                dex                 ; [2] Decrement to point to saved X register.
                lda     $100,x      ; [4] Load original value of X.
                tax                 ; [2] X is now its original value as retrieved from the stack.
                pla                 ; [4] A is now its original value as retrieved from the stack.

                sec                 ; [2] We subtract 93 cycles of overhead.
                sbc     #93         ; [2]
                bcs     l_q1        ; [C=0: 2, C=1: 3]
l_q1:           bcs     l_bigloop   ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]

l_bigloop:      sec                 ; [2] Enter a 15-cycle loop, subtracting 15 cycles from (A, X) as we go.
                sbc     #15         ; [2]
                bcs     l_q2        ; [C=0: 2, C=1: 3]
l_q2:           bcs     l_skip_dex  ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]
l_skip_dex:     cpx     #0          ; [2] We're done if X is, or decreased to, 0.
                bne     l_bigloop   ; [Z=0: 3, Z=1: 2]

                ; Remaining cycles to burn now in A register.
                
                lsr                 ; [2] Divide A by 2.
                bcs     l_div2done  ; [C=0: 2, C=1: 3]  (2 or 3)

l_div2done:     lsr                 ; [2] Divide A by 2. 
                bcc     l_div4done  ; [C=0: 3, C=1: 2]  (3 or 5)
                bcs     l_div4done  ; [C=0: 0, C=1: 3]

l_div4done:     lsr                 ; [2] Divide A by 2.
                bcc     l_div8done  ; [C=0: 3, C=1: 2]  (3 or 7)
                nop                 ; [C=0: 0, C=1: 2]
                bcs     l_div8done  ; [C=0: 0, C=1: 3]

l_div8done:     tax                 ; [2] Load number of 8-cycle loops to execute.
l_loop8:        dex                 ; [2] Spend 8 cycles (assuming X != 1 on entry, otherwise 6).
                bne     l_burn3     ; [Z=0: 3, Z=1: 2]
l_burn3:        bne     l_loop8     ; [Z=0: 3, Z=1: 2] When leaving the loop, X will be zero.

                pla                 ; [4] Restore X register.
                tax                 ; [4] X will always be unequal to zero.
                bne     s_restore   ; [3] Restore A register and processor flags

                .endscope
