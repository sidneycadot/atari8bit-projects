
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
                ; *** IMPORTANT *** : This routine only works correctly if it starts
                ;   on an address of the form $xxe7 .. $xxeb. This is because it
                ;   relies on the fact that the "loop8" branch crosses a page
                ;   boundary for exact timing.
                ;
                ; The routine has the following behavioral properties:
                ;
                ;   - It does not use memory outside of the 6502 stack.
                ;   - It is fully re-entrant, and is safe to use in interrupts.
                ;   - The A and X registers are both zero upon return.
                ;
                ; The code size is currently 41 bytes.
                ;
                ; The minimum number of clock cycles that can be specified as a
                ;   delay is 38. Behavior for values below 38 is not defined.
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

                .segment "page_aligned_code"

                .align 256          ; This line and the next line ensure that the code is on an allowed starting address.
                .res $e7            ; Any value from the range $e7 .. $eb will work to ensure that the final branch
                                    ;   instruction in the "s_loop8" loop crosses a page boundary.

cycle_delay:    cpx     #0          ; [2] If the specified delay count exceeds 255,
                bne     long_delay  ; [2]   jump to "long_delay" for further processing.

short_delay:    ; This is the code path taken if a delay count of <= 255 cycles is requested.
                ;
                ; This is the critical part of the 'cycle_delay' routine in terms of efficiency, because the
                ;   clock cycles spent in this code path directly determine the minimum delay count that
                ;   the 'cycle_delay' routine can handle (currently, 38).

                ; Compensate for the overhead in the 'short_delay' code path.
                ;
                ; We known that the carry is currently set, because the last instruction was a cpx #0.
                ;
                ; We subtract 30 to ensure that, in case the requested number of delay cycles is 38,
                ;   register A is 1 (the minimum value that works) when entering the "s_loop8" loop below.

                sbc     #30         ; [2] 

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

lowbits:        lsr                 ; [2] Divide A by 2.
                bcs     s_div2done  ; [C=0: 2, C=1: 3] If the bit shifted out is 1, burn an extra cycle.

s_div2done:     lsr                 ; [2] Divide A by 2.
                bcc     s_div4done  ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn two extra cycles.
                bcs     s_div4done  ; [C=0: 0, C=1: 3]

s_div4done:     lsr                 ; [2] Divide A by 2.
                bcc     s_loop8     ; [C=0: 3, C=1: 2] If the bit shifted out is 1, burn four extra cycles.
                nop                 ; [C=0: 0, C=1: 2]
                bcs     s_loop8     ; [C=0: 0, C=1: 3]

                ; Execute a number of loops that corresponds to the remaining delay count divided by eight.
                ; Each loop traversal (except the last) takes precisely eight clock cycles.

s_loop8:        sec                 ; [2] Burn 8 cycles if A != 1 at the start of the loop, else 6 cycles.
                sbc     #1          ; [2]
                bne     s_loop8     ; [Z=0: 4, Z=1: 2]  *** IT IS CRITICAL THAT THIS BRANCH CROSSES A PAGE BOUNDARY ***

                ; Return to the caller.

                rts                 ; [6] All done. Return to caller.

long_delay:     ; This is the code path taken if a delay count of >= 256 cycles is requested.
                ;
                ; This code is not highly critical in terms of efficiency, since the entire point of this code
                ;   path is to burn a considerable number of clock cycles (at least 256) anyway.

                ; The loop that follows burns off 15 clock cycles per loop traversal.
                ; During each traversal we subtract 15 from the count of cycles remaining to be burnt.
                ; The loop ends when the X register (the high byte of the 16-bit delay count) is zero.
                ;
                ; Note that it is possible for the X register to be already zero when we enter the loop;
                ;   in fact the combined value of (A, X) can be as low as 241 when we get here.
                ; If this happens, we still subtract 15 cycles. This is not a problem since the code
                ;   that follows will handle any value in the range 38 .. 255 just fine.

l_bigloop:      sec                 ; [2] Enter a 15-cycle loop, subtracting 15 cycles from (A, X) as we go.
                sbc     #15         ; [2]
                bcs     l_q2        ; [C=0: 2, C=1: 3]
l_q2:           bcs     l_skip_dex  ; [C=0: 2, C=1: 3]
                dex                 ; [C=0: 2, C=1: 0]
l_skip_dex:     cpx     #0          ; [2] We're done if the X register is zero.
                bne     l_bigloop   ; [Z=0: 3, Z=1: 2]

                ; Now X=0 and A has a number of cycles to burn.
                ; A is a "high" value (at least 256 - 15).

                ; Compensate for the overhead in the 'long_delay' code path.
                ;
                ; The subtracted value 7 ensures that the entire 'cycle_delay' routine consumes
                ;   the correct number of cycles when at least 256 delay cycles are requested.
                ;
                ; We need not set the carry, as we are sure it is already set, because the last instruction
                ;   that influences the carry was a "cpx #0".

                sbc     #7

                ; The remaining cycles will be burnt in the 'short_delay' loop.
                ; We can use a 'bcs' to jump there, since the last 'sbc' is guaranteed not
                ; to have caused a borrow.

                bcs     short_delay
