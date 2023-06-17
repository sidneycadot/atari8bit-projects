
                ; =================================================================
                ; =                                                               =
                ; =                        cycle_delay                            =
                ; =                                                               =
                ; =================================================================
                ;
                ; On entry, register A contains the low byte and register X contains
                ; the high byte of a 16-bit unsigned cycle count.
                ;
                ; The routine (including the calling 'jsr' instruction) will
                ; consume the specified number of CPU clock cycles.
                ;
                ; For the cycle count consumption to be accurate, it is of course
                ; assumed that the code is not interrupted while executing.
                ;
                ; The routine has the following nice properties:
                ;
                ;   - It preserves all registers and processor flags.
                ;   - It does not use memory outside of the 6502 stack.
                ;   - It is fully re-entrant, and is safe to use in interrupts.
                ;   - It is relocatable. All jumps are implemented as branches.
                ;
                ; The code size is currently 91 bytes.
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

                .code

cycle_delay:    .scope

                php                 ; [3] Save processor status flags.
                pha                 ; [3] Save A register.

                cpx     #0          ; [2] If the specified delay count exceeds 255,
                bne     long_delay  ; [2]   jump to "long_delay" for further processing.

short_delay:    ; This is the code path taken if a delay count of <= 255 cycles is requested.
                ;
                ; When we get here, the processor flags and the A register have already been saved on the
                ;   stack, and we know that register X is equal to 0; because of that, we do not need to
                ;   save it on the stack in this code path.
                ;
                ; This is the most critical part of the 'cycle_delay' routine in terms of efficiency, because
                ;   the clock cycles spent in this code path directly determine the minimum allowed delay count
                ;   that we will be able to handle. The challenge is to make this number as low as possible.
                ;
                ; In the current version, this code path works as advertised if the originally specified
                ;   delay count is at least 56 clock cycles.

                ; Compensate for the overhead in the 'short_delay' code path.
                ;
                ; We subtract 48 to ensure that, in case the requested number of delay cycles is 56,
                ;   register X is 1 (the minimum value that works) when entering the "s_loop8" loop below.

                sec                 ; [2] 
                sbc     #48         ; [2] 

                ; Next thing to do: burn the number of cycles currently contained in the A register.
                ; This value should be in the range 8 .. 255 at this point for the code below to work as expected.
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

s_div8done:     tax                 ; [2] Load the number of 8-cycle loops to execute.

s_loop8:        dex                 ; [2] Burn 8 cycles if X != 1 at the start of the loop, else 6 cycles.
                bne s_burn3         ; [Z=0: 3, Z=1: 2]
s_burn3:        bne s_loop8         ; [Z=0: 3, Z=1: 2] When leaving the loop, X will be zero (as it originally was).

                ; The X register is now zero, as it was when entering the 'short_delay' code path.
                ; Restore the register and processor flags, then return to the caller.

sl_restore:     pla                 ; [4] Restore the A register.
                plp                 ; [4] Restore the processor status flags.
                rts                 ; [6] All done. Return to caller.

long_delay:     ; This is the code path taken if a delay count of >= 256 cycles is requested.
                ;
                ; When we get here, the processor flags and the A register contents have already been saved on
                ;   the stack, and we know that register X is not equal to 0.
                ; We still need to save register X on the stack.
                ;
                ; This code is not highly critical in terms of efficiency, since the entire point of this code
                ; path is to burn a considerable amount of clock cycles (at least 256) anyway.

                txa                 ; [2] Save X on the stack.
                pha                 ; [3]

                ; Now that both A and X are saved, we need to get them back to their original values.
                ; This is surprisingly tricky, since normally all stack access goes via the A register.
                ; The solution is to do direct access into page one (the 6502 stack page).

                tsx                 ; [2] Stack pointer to X register.
                inx                 ; [2] Increment X twice to point to saved A register.
                inx                 ; [2]
                lda     $100,x      ; [4] Load original value of A.
                pha                 ; [3] Push it onto the stack.
                dex                 ; [2] Decrement to point to saved X register.
                lda     $100,x      ; [4] Load original value of X.
                tax                 ; [2] X is now its original value as retrieved from the stack.
                pla                 ; [4] A is now its original value as retrieved from the stack.

                ; Compensate for the overhead in the 'long_delay' code path.
                ;
                ; The value 93 ensures that the entire 'cycle_delay' routine consumes precisely
                ;   the requested number of cycles when at least 256 delay samples are requested.
                ;
                ; Note that the 16-bit subtraction is implemented in such a way that it consumes the
                ;   same number of clock cycles (8) whether a "borrow" happens or not.

                sec                 ; [2]
                sbc     #93         ; [2]
                bcs     l_q1        ; [C=0: 2, C=1: 3]
l_q1:           bcs     l_bigloop   ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]

                ; The loop that follows burns off 15 clock cycles per loop traversal.
                ; During each traversal we subtract 15 from the count of cycles remaining to be burnt.
                ; The loop ends when X (the high byte of the 16-bit delay count) is zero.
                ;
                ; Note that it is possible for register X to be already zero when we enter the loop;
                ;   in fact the combined value of (A, X) can be as low as 163 when we get here.
                ; If this happens, we still subtract 15 cycles. This is not a problem since the code
                ;   that follows will handle any value in the range 8 .. 255 just fine.

l_bigloop:      sec                 ; [2] Enter a 15-cycle loop, subtracting 15 cycles from (A, X) as we go.
                sbc     #15         ; [2]
                bcs     l_q2        ; [C=0: 2, C=1: 3]
l_q2:           bcs     l_skip_dex  ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]
l_skip_dex:     cpx     #0          ; [2] We're done if X is zero.
                bne     l_bigloop   ; [Z=0: 3, Z=1: 2]

                ; The remainder of this code is nearly identical to the code in the 'short_delay' path;
                ;   the only difference being that we need to restore the X register at the end, which
                ;   is not necessary in the 'short_delay' code path.

                ; Next thing to do: burn the number of cycles currently contained in the A register.
                ; This value should be in the range 8 .. 255 at this point for the code below to work as expected.
                ;
                ; We divide the remaining cycle count by 8 by shifting the least-significant bit out
                ;   of the A register three times. For each bit that we shift out, we will burn
                ;   more cycles if it is set to one:
                ;
                ;   - For the 1st bit shifted out, burn 1 more cycle if it is one, vs if it is zero.
                ;   - For the 2nd bit shifted out, burn 2 more cycles if it is one, vs if it is zero.
                ;   - For the 3rd bit shifted out, burn 4 more cycles if it is one, vs if it is zero.

                lsr                 ; [2] Divide A by 2.
                bcs     l_div2done  ; [C=0: 2, C=1: 3] If the bit shifted out is 1, burn an extra cycle.

l_div2done:     lsr                 ; [2] Divide A by 2. 
                bcc     l_div4done  ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn two extra cycles.
                bcs     l_div4done  ; [C=0: 0, C=1: 3]

l_div4done:     lsr                 ; [2] Divide A by 2.
                bcc     l_div8done  ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     l_div8done  ; [C=0: 0, C=1: 3]

                ; Execute a number of loops that corresponds to the remaining delay count divided by eight.
                ; Each loop traversal (except the last) takes precisely eight clock cycles.

l_div8done:     tax                 ; [2] Load the number of 8-cycle loops to execute.

l_loop8:        dex                 ; [2] Burn 8 cycles if X != 1 at the start of the loop, else 6 cycles.
                bne     l_burn3     ; [Z=0: 3, Z=1: 2]
l_burn3:        bne     l_loop8     ; [Z=0: 3, Z=1: 2]

                ; Restore the register and processor flags, then return to the caller.
                ; We join up with the 'short_delay' code path the restore the A register and processor
                ;   flags to save one byte of code.

                pla                 ; [4] Restore the X register.
                tax                 ; [4] X will always be unequal to zero, so we can use "bne" to jump.
                bne     sl_restore  ; [3] Restore the A register and processor flags.

                .endscope
