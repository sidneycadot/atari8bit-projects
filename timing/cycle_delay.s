
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
                ; For the cycle count consumption to be accurate, it is assumed
                ;   that the code is not interrupted while executing.
                ;
                ; *** IMPORTANT *** : This routine only works correctly if it starts
                ;   on an address of the form $xxe7 .. $xxeb. This is because it
                ;   relies on the fact that the "loop8" branch crosses a page
                ;   boundary, thus taking 4 clock cycles, for its timing.
                ;
                ; The routine has the following behavioral properties:
                ;
                ;   - It does not use memory outside of the 6502 stack.
                ;   - It is fully re-entrant and safe to use in interrupts.
                ;   - The A and X registers are both zero upon return.
                ;
                ; The code size is a modest 38 bytes.
                ;
                ; The minimum number of clock cycles that can be specified as a
                ;   delay is 38. Behavior for values below 38 is not defined.
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

                ; This next two directives ensure that the code is on an allowed starting address.

                .align  256         
                .res    $e7         ; Must be $e7 .. $eb.

                ; Code starts here.

cycle_delay:    cpx     #0          ; [2] If the delay count specified in AX exceeds 255,
                bne     long_delay  ; [2]   jump to "long_delay" for further processing.

short_delay:    ; This is the code path taken if a delay count of 38 <= AX <= 255 cycles is desired.
                ;
                ; This is the critical part of the 'cycle_delay' routine in terms of efficiency, because
                ;   the clock cycles spent in this code path directly determine the minimum delay count
                ;   that the 'cycle_delay' routine can handle (currently, 38).

                ; Compensate for the overhead in the 'short_delay' code path.
                ;
                ; We known that the carry is currently set, because the last instruction influencing
                ;   the carry was the "cpx #0" above.
                ;
                ; We subtract 30 to ensure that, in case the requested number of delay cycles is 38,
                ;   register A is 1 (the minimum value that works) when entering the "loop8" loop below.

                sbc     #30         ; [2]

delay_a_reg:    ; Burn the number of cycles currently specified in the A register, plus 18 cycles.
                ; The value in register A should be in the range 8 .. 255 here for the code below
                ;   to work as intended.
                ;
                ; We divide the remaining cycle count in A by 8, by shifting the least-significant bit
                ;   out of the A register three times. For each bit that we shift out, we will burn
                ;   more cycles if it is set to one:
                ;
                ;   - For the 1st bit shifted out, burn 1 more cycle  if it is one, vs if it is zero.
                ;   - For the 2nd bit shifted out, burn 2 more cycles if it is one, vs if it is zero.
                ;   - For the 3rd bit shifted out, burn 4 more cycles if it is one, vs if it is zero.

                lsr                 ; [2] Divide A by 2.
                bcs     div2done    ; [C=0: 2, C=1: 3] If the bit shifted out is 1, burn an extra cycle.

div2done:       lsr                 ; [2] Divide A by 2.
                bcc     div4done    ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn two extra cycles.
                bcs     div4done    ; [C=0: 0, C=1: 3]

div4done:       lsr                 ; [2] Divide A by 2.
                bcc     loop8       ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     loop8       ; [C=0: 0, C=1: 3]

                ; Execute a number of loops that corresponds to the remaining delay count divided by eight.
                ; Each loop traversal (except the last) takes precisely eight clock cycles.

loop8:          sec                 ; [2] Burn 8 cycles if A != 1 at the start of the loop, else 6 cycles.
                sbc     #1          ; [2]
                bne     loop8       ; [Z=0: 4, Z=1: 2] *** CRITICAL: THIS BRANCH MUST CROSS A PAGE BOUNDARY ***

                ; Return to the caller.

                rts                 ; [6] All done.

long_delay:     ; This is the code path taken if a delay count AX >= 256 cycles is requested.
                ;
                ; To accomplish the desired behavior is the number of delay cycles in AX is decreased
                ;   by 9 in a loop that takes precisely 9 cycles, until AX becomes less than 256.
                ; As soon as that happens, we rejoin the 'short_delay' code path to burn the remaining cycles.

                ; The period-9 cycle-burning loop is written in a somehwt convoluted way to ensure that the
                ;   loop takes exactly 9 cycles both in case a borrow happens, and when it doesn't.
                ;
                ; We also want to guarantee that the carry flag is predicatable after execution of the loop.
                ; The implementation below guarantees that the carry flag is 0 when exiting the loop.
                ;
                ; The loop ends when the X register (the high byte of the 16-bit delay count) becomes zero.

loop9_long:     clc                 ; [2]
                nop                 ; [2]
loop9_short:    sbc     #(9 - 1)    ; [2]   Subtract 9 from the cycle count. (carry is 0, here).
                bcs     loop9_long  ; [2/3] No borrow: make a long loop to burn 4 cycles and set the carry to 0.
                dex                 ; [2]   Borrow occurred; we need to decrement X.
                bne     loop9_short ; [2/3] If X has become zero, we're done with this loop.

                ; Now X=0 and the A register holds a number of cycles to burn.
                ; The value of A is at least 256 - 9 = 247.

                ; Compensate for the overhead in the 'long_delay' code path.
                ;
                ; Subtract 39 from the A register to ensure that the entire 'cycle_delay' routine consumes
                ;   the correct number of cycles when at least 256 delay cycles are requested.
                ;
                ; The carry is guaranteed to be 0 here, so we're actually subtracting 39 from the A register.

                sbc     #(39 - 1)   ; [2]

                ; The remaining cycles will be burnt in the 'short_delay' code path.
                ;
                ; We can use a 'bcs' to jump there, since the last 'sbc' is guaranteed not
                ;   to have caused a borrow.

                bcs     delay_a_reg ; [4] This branch takes 4 cycles as it crosses a page boundary.
