
                ; =================================================================
                ; =                                                               =
                ; =                        cycle_delay                            =
                ; =                                                               =
                ; =================================================================
                ;
                ; On entry, the A register contains the low byte and the X register
                ;   contains the high byte of a 16-bit unsigned cycle count. In the
                ;   following, we will refer to this as the "AX" pseudo-register.
                ;
                ; The routine (including the calling 'jsr' instruction) will
                ;   consume the number of CPU clock cycles specified in AX.
                ;
                ; The minimum number of clock cycles that can be specified as a
                ;   delay is 34. Behavior for values below 34 is not defined.
                ;
                ; For the cycle count consumption to be accurate, it is assumed
                ;   that the code is not interrupted while executing.
                ;
                ; *** IMPORTANT *** : This routine only works correctly if it
                ;   starts on an address of the form $xxd7 or $xxd8. This is
                ;   because it relies on the "loop8" branch crossing a page
                ;   boundary, thus taking 4 clock cycles, and the branches
                ;   to "enter8" not crossing a page boundary, thus taking
                ;   3 clock cycles, to get the required timing behavior.
                ;
                ; The routine has the following behavioral properties:
                ;
                ;   - It can be run from RAM or ROM.
                ;   - It does not use memory or stack space.
                ;   - It is fully re-entrant and safe to use in interrupts.
                ;   - The A and X registers are both zero upon return.
                ;
                ; The code size is a modest 39 bytes.
                ;
                ; Example
                ; -------
                ;
                ; Three instructions that together take precisely 10,000 cycles:
                ;
                ;           lda     #<9996      ; [2 cycles] -- load low byte
                ;           ldx     #>9996      ; [2 cycles] -- load high byte
                ;           jsr     cycle_delay ; [9996 cycles]

                .export cycle_delay

                .segment "page_aligned_code"

                ; The next two directives ensure that the code is on an allowed starting address.

                .align  256         
                .res    $da         ; Must be $da or $db.

                ; Code starts here.

cycle_delay:    cpx     #0          ; [2]    If the delay count specified in AX exceeds 255,
                bne     long_delay  ; [2/3]    jump to "long_delay" for further processing.
                                    ;        If taken, the branch takes 4 cycles as it crosses
                                    ;          a page boundary.

short_delay:    ; This is the code path taken for delay counts in the range [38 .. 255].
                ;
                ; This is the critical part of the 'cycle_delay' routine in terms of efficiency,
                ;   because the clock cycles spent in this code path directly determine the minimum
                ;   delay count that the 'cycle_delay' routine can handle (currently, 38).

                ; Compensate for the fixed cycle cost of the short delay path, by subtracting
                ; a constant from the current value of the A register.
                ;
                ; So far, we've spent 6 cycles on the calling 'jsr' instruction, plus 4 cycles to
                ; get to this point. The 'sbc' instruction about to be executed will add another
                ; 2 cycles. After that, the 'delay_a_reg' part of the routine will consume
                ; (22 + A) clock cycles, given the value of the A register at that point.
                ;
                ; To determine the number of cycles we need to subtract, consider the following:
                ;
                ;   6 + 4 + 2 + (22 + A_after_sbc) == A_before_sbc          (1)
                ;
                ;   A_after_sbc == A_before_sbc - subtract_constant         (2)
                ;
                ; Combining these leads to:
                ;
                ;   subtract_constant == 30                                 (3)
                ;
                ; So to make everything work as intended, we need to subtract 30 from A here.
                ;
                ; We known that the carry is currently set, because the last instruction affecting
                ;   the carry was the "cpx #0" above.

                sbc     #34         ; [2]

delay_a_reg:    ; Burn the number of cycles currently specified in the A register, plus 22 cycles.
                ;
                ; We divide the cycle count in A by 8, by shifting the least-significant bit out
                ;   of the A register three times. For each bit that we shift out, we will burn
                ;   more cycles if it is set to one:
                ;
                ;   - For the 1st bit shifted out, burn 1 more cycle  if it is one, vs if it is zero.
                ;   - For the 2nd bit shifted out, burn 2 more cycles if it is one, vs if it is zero.
                ;   - For the 3rd bit shifted out, burn 4 more cycles if it is one, vs if it is zero.
                ;
                ; At the end of this, we branch to "enter_loop8" to burn the remaining 8 + 8 * A cycles.

                lsr                 ; [2] Divide A by 2.
                bcs     div2done    ; [C=0: 2, C=1: 3] If the bit shifted out is 1, burn an extra cycle.

div2done:       lsr                 ; [2] Divide A by 2.
                bcc     div4done    ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn two extra cycles.
                bcs     div4done    ; [C=0: 0, C=1: 3]

div4done:       lsr                 ; [2] Divide A by 2.
                bcc     enter_loop8 ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     enter_loop8 ; [C=0: 0, C=1: 3]

long_delay:     ; This is the code path taken for delay counts in the range [256 .. 65535].
                ;
                ; The number of delay cycles in AX is decreased by 9 in a loop that takes precisely 9 cycles,
                ;   until AX becomes less than 256.
                ; As soon as that happens, we rejoin the 'short_delay' code path to burn the remaining cycles.

                ; The period-9 cycle-burning loop is written in a somewhat convoluted way to ensure that the
                ;   loop takes exactly 9 cycles both in case a borrow happens, and when it doesn't.
                ;
                ; The loop ends when the X register (the high byte of the 16-bit delay count) becomes zero.
                ;
                ; With M being the number of "loop9" loop traversals (M >= 1), the total number of cycles
                ;   taken is equal to 3 + 9 * M.
                ;
                ; We also want to guarantee that the carry flag is predicatable after execution of the loop.
                ; The implementation below guarantees that the carry flag is 0 when exiting the loop.

loop9_long:     clc                 ; [2]
                nop                 ; [2]
loop9_short:    sbc     #(9 - 1)    ; [2]   Subtract 9 from the cycle count. (carry is 0, here).
                bcs     loop9_long  ; [2/3] No borrow: make a long loop to burn 4 cycles and set the carry to 0.
                dex                 ; [2]   Borrow occurred; we need to decrement X.
                bne     loop9_short ; [2/3] If X has become zero, we're done with this loop.

                ; Now the X register is 0 and the A register holds a remaining number of cycles to burn.
                ; The value of A is at least 256 - 9 = 247.

                ; Compensate for the fixed cycle cost of the long delay path, by subtracting
                ; a constant from the current value of the A register.
                ;
                ; In the following, let M be the number of traversals of the "loop9" loop that was
                ;   just executed (M >= 1).
                ;
                ; We can then write three equations to relate the desired execution time of the
                ;   routine, including the calling 'jsr', to the actual execution time:
                ;
                ;   6 + 2 + 3 + (9 * M + 3) + 2 + 3 + (22 + A_after_sbc) == cycles_requested    (4)
                ;
                ;   A_before_sbc == cycles_requested - 9 * M                                    (5)
                ;
                ;   A_after_sbc == A_before_sbc - subtract_constant                             (6)
                ;
                ; Combining these leads to:
                ;
                ;   subtract_constant == 41                                                     (7)
                ;
                ; So to make everything work as intended, we need to subtract 39 from A here.
                ;
                ; Note that the carry flag is 0 when we get here, so we'll be subtracting 1
                ;   more than the specified immediate argument.

                sbc     #(41 - 1)   ; [2]

                ; The remaining cycles will be burnt in the 'short_delay' code path.
                ;
                ; We can use a 'bcs' to jump there, since the last 'sbc' is guaranteed not
                ;   to have caused a borrow.

                bcs     delay_a_reg ; [3]

                ; "enter_loop8" burns 8 + 8 * A clock cycles, including the final 'rts' instruction.

loop8:          sec                 ; [2] Burn 8 cycles if A != 1 at the start of the loop, else 6 cycles.
                sbc     #1          ; [2]
enter_loop8:    bne     loop8       ; [Z=0: 4, Z=1: 2] *** CRITICAL: THIS BRANCH MUST CROSS A PAGE BOUNDARY ***

                ; Return to the caller.

                rts                 ; [6] All done.
