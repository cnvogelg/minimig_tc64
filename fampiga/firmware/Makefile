# *nix Makefile for Minimig bootfirmware assembly
# Written by Christian Vogelgsang <chris@vogelgsang.org>

# ----- the following tools need to be installed -----
# vasm homepage http://sun.hasenbraten.de/vasm
ASM=vasmm68k_mot
HEXER=python hexer.py

# ----- rules -----
all: hostboot.hex osdload.hex

clean:
	rm -f hostboot.hex osdload.hex
	
%.hex: %.bin
	$(HEXER) -l 2048 $< $@

%.bin: %.asm
	$(ASM) -Fbin -o $@ $<
