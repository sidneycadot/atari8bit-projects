
.PHONY : clean

boot_sequence.atr : boot_sequence.bin
	./make_atr.py f:boot_sequence.bin boot_sequence.atr

boot_sequence.bin : boot_sequence.o
	ld65 -C boot_sequence.lnk  boot_sequence.o -o boot_sequence.bin

boot_sequence.o : boot_sequence.s
	ca65 boot_sequence.s


clean:
	$(RM) boot_sequence.o boot_sequence.bin boot_sequence.atr
