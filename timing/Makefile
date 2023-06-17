
.PHONY : clean default

default : timing_1.atr timing_2.atr timing_3.atr

# ---------------------------------------------------------------

timing_1.atr : timing_1.bin
	./make_atr.py f:timing_1.bin timing_1.atr

timing_1.bin : timing_1.o
	ld65 -C timing.lnk  timing_1.o -o timing_1.bin

timing_1.o : timing_1.s
	ca65 timing_1.s

# ---------------------------------------------------------------

timing_2.atr : timing_2.bin
	./make_atr.py f:timing_2.bin timing_2.atr

timing_2.bin : timing_2.o cycle_delay.o
	ld65 -C timing.lnk  $^ -o $@

timing_2.o : timing_2.s
	ca65 timing_2.s

# ---------------------------------------------------------------

timing_3.atr : timing_3.bin
	./make_atr.py f:timing_3.bin timing_3.atr

timing_3.bin : timing_3.o cycle_delay.o
	ld65 -C timing.lnk  $^ -o $@

timing_3.o : timing_3.s
	ca65 timing_3.s

# ---------------------------------------------------------------

cycle_delay.o : cycle_delay.s
	ca65 cycle_delay.s

# ---------------------------------------------------------------

clean:
	$(RM) timing_*.o timing_*.bin timing_*.atr
