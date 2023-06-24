
.PHONY : clean default

default : timing_1.atr timing_2.atr timing_3.atr cycle_delay_test.atr

# rules

%.o : %.s
	ca65 $< -o $@

%.bin :
	ld65 -C timing.lnk  $^ -o $@

%.atr : %.bin
	./make_atr.py f:$< $@

# ---------------------------------------------------------------

cycle_delay_test.bin : cycle_delay_test.o cycle_delay.o

timing_1.bin : timing_1.o
timing_2.bin : timing_2.o cycle_delay.o
timing_3.bin : timing_3.o cycle_delay.o

# ---------------------------------------------------------------


# ---------------------------------------------------------------


# ---------------------------------------------------------------

clean:
	$(RM) timing_*.o timing_*.bin timing_*.atr
