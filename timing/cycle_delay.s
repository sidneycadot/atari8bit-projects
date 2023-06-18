
                ; =================================================================
                ; =                                                               =
                ; =                        cycle_delay                            =
                ; =                                                               =
                ; =================================================================
                ;
                ; On entry, the A register contains the low byte and the X register
                ;   contains the high byte of a 16-bit unsigned cycle count.
                ;
                ; The routine (including the calling 'jsr' instruction) will
                ;   consume the specified number of CPU clock cycles.
                ;
                ; For the cycle count consumption to be accurate, it is of course
                ;   assumed that the code is not interrupted while executing.
                ;
                ; IMPORTANT: This routine only works correctly if it is fully
                ;   contained in a single 6502 page of memory. This is necessary so
                ;   we can assume that a branch-taken always takes three clock cycles;
                ;   they take four cycles when jumping across a page boundary.
                ;
                ; The routine has the following nice properties:
                ;
                ;   - It preserves all registers and processor flags.
                ;   - It does not use memory outside of the 6502 stack.
                ;   - It is fully re-entrant, and is safe to use in interrupts.
                ;
                ; The code size is currently 74 bytes.
                ;
                ; The minimum number of clock cycles that can be specified as a
                ; delay is 56. Behavior for values below 56 is undefined.
                ;
                ; Example
                ; -------
                ;
                ; Three instructions that together take precisely 10,000 cycles:
                ;
                ;           lda  #<9996       ; [2 cycles]
                ;           ldx  #>9996       ; [2 cycles]
                ;           jsr  cycle_delay  ; [9996 cycles]

                .export cycle_delay

                .segment "aligned_code"

                .align 128          ; This ensures that the code does not cross page boundaries.

cycle_delay:    php                 ; [3] Save the processor status flags.
                pha                 ; [3] Save the A register.

                cpx     #0          ; [2] If the specified delay count exceeds 255,
                bne     long_delay  ; [2]   jump to "long_delay" for further processing.

short_delay:    ; This is the code path taken if a delay count of <= 255 cycles is requested.
                ;
                ; When we get here, the processor flags and the A register have already been saved on the
                ;   stack, and we know that the X register is equal to 0; because of that, we do not need to
                ;   save it on the stack in this code path.
                ;
                ; This is the critical part of the 'cycle_delay' routine in terms of efficiency, because the
                ;   clock cycles spent in this code path directly determine the minimum delay count that
                ;   the 'cycle_delay' routine can handle (currently, 56).

                ; Compensate for the overhead in the 'short_delay' code path.
                ;
                ; We subtract 48 to ensure that, in case the requested number of delay cycles is 56,
                ;   register X is 1 (the minimum value that works) when entering the "s_loop8" loop below.

                sec                 ; [2] 
                sbc     #48         ; [2] 

                ; Next thing to do: burn the number of cycles currently contained in the A register.
                ; This value should be in the range 8 .. 255 for the code below to work as intended.
                ;
                ; We divide the remaining cycle count by 8 by shifting the least-significant bit out
                ;   of the A register three times. For each bit that we shift out, we will burn
                ;   more cycles if it is set to one:
                ;
                ;   - For the 1st bit shifted out, burn 1 more cycle if it is one, vs if it is zero.
                ;   - For the 2nd bit shifted out, burn 2 more cycles if it is one, vs if it is zero.
                ;   - For the 3rd bit shifted out, burn 4 more cycles if it is one, vs if it is zero.

                lsr                 ; [2] Divide A by 2.
                bcs     s_div2done  ; [C=0: 2, C=1: 3] If the bit shifted out is 1, burn an extra cycle.

s_div2done:     lsr                 ; [2] Divide A by 2.
                bcc     s_div4done  ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn two extra cycles.
                bcs     s_div4done  ; [C=0: 0, C=1: 3]

s_div4done:     lsr                 ; [2] Divide A by 2.
                bcc     s_div8done  ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     s_div8done  ; [C=0: 0, C=1: 3]

                ; Execute a number of loops that corresponds to the remaining delay count divided by eight.
                ; Each loop traversal (except the last) takes precisely eight clock cycles.

s_div8done:     tax                 ; [2] Load the number of 8-cycle loops to execute into the X register.

s_loop8:        dex                 ; [2] Burn 8 cycles if X != 1 at the start of the loop, else 6 cycles.
                bne s_burn3         ; [Z=0: 3, Z=1: 2]
s_burn3:        bne s_loop8         ; [Z=0: 3, Z=1: 2]

                ; The X register is now zero, just as it was when entering the 'short_delay' code path.
                ; Restore the A register and the processor flags, then return to the caller.

sl_restore:     pla                 ; [4] Restore the A register.
                plp                 ; [4] Restore the processor status flags.
                rts                 ; [6] All done. Return to caller.

long_delay:     ; This is the code path taken if a delay count of >= 256 cycles is requested.
                ;
                ; When we get here, the processor flags and the A register value have already been saved on
                ;   the stack, and we know that the X register is not equal to 0.
                ; We still need to save the X register on the stack.
                ;
                ; This code is not highly critical in terms of efficiency, since the entire point of this code
                ; path is to burn a considerable number of clock cycles (at least 256) anyway.

                txa                 ; [2] Save the X register on the stack.
                pha                 ; [3]

                ; Now that both A and X are saved, we need to get them back to their original values.
                ; This is surprisingly tricky, since normally all stack access goes via the A register.
                ; The solution is to do direct access into page one (the 6502 stack page).

                tsx                 ; [2] Copy the stack pointer to the X register.
                inx                 ; [2] Increment X twice to point to the saved A register value.
                inx                 ; [2]
                lda     $100,x      ; [4] Load original value of the A register.
                pha                 ; [3] Push it onto the stack.
                dex                 ; [2] Decrement to point to the saved X register value.
                lda     $100,x      ; [4] Load original value of the X register.
                tax                 ; [2] X is now its original value as retrieved from the stack.
                pla                 ; [4] A is now its original value as retrieved from the stack.

                ; Compensate for the overhead in the 'long_delay' code path.
                ;
                ; The subtracted value 79 ensures that the entire 'cycle_delay' routine consumes exactly
                ;   the requested number of cycles when at least 256 delay samples are requested.
                ;
                ; Note that the 16-bit subtraction is implemented in such a way that it consumes the
                ;   same number of clock cycles (8) whether a "borrow" happens or not.

                sec                 ; [2]
                sbc     #79         ; [2]
                bcs     l_q1        ; [C=0: 2, C=1: 3]
l_q1:           bcs     l_bigloop   ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]

                ; The loop that follows burns off 15 clock cycles per loop traversal.
                ; During each traversal we subtract 15 from the count of cycles remaining to be burnt.
                ; The loop ends when the X register (the high byte of the 16-bit delay count) is zero.
                ;
                ; Note that it is possible for the X register to be already zero when we enter the loop;
                ;   in fact the combined value of (A, X) can be as low as 163 when we get here.
                ; If this happens, we still subtract 15 cycles. This is not a problem since the code
                ;   that follows will handle any value in the range 56 .. 255 just fine.

l_bigloop:      sec                 ; [2] Enter a 15-cycle loop, subtracting 15 cycles from (A, X) as we go.
                sbc     #15         ; [2]
                bcs     l_q2        ; [C=0: 2, C=1: 3]
l_q2:           bcs     l_skip_dex  ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]
l_skip_dex:     cpx     #0          ; [2] We're done if the X register is zero.
                bne     l_bigloop   ; [Z=0: 3, Z=1: 2]

                ; Now we call 'cycle_delay' recursively to burn the remaining cycles.
                ; Since the X register is now 0, this will take the 'short_delay' code path.

                jsr     cycle_delay ; [# of cycles == A register value]

                ; Restore the register and processor flags, then return to the caller.
                ; We join up with the 'short_delay' code path the restore the A register and processor
                ;   flags to save one byte of code.

                pla                 ; [4] Restore the X register.
                tax                 ; [4] X will always be unequal to zero, so we can use "bne" to jump.
                bne     sl_restore  ; [3] Restore the A register and processor flags.

                ; End of 'cycle_delay'.
