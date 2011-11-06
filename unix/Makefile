# unix Makefile for building minimig chameleon controller code
# with the DICE cross compiler
#
# written by Christian Vogelgsang <chris@vogelgsang.org>

# location of DICE compiler
DHOME=/opt/dice
export DHOME

DBIN=$(DHOME)/ubin
PATH:=$(DBIN):$(PATH)
export PATH
DINCLUDE=$(DHOME)/include
export DINCLUDE
DLIB=$(DHOME)/dlib
export DLIB

DCC=$(DBIN)/dcc
DCCOPTS=-// -D ROM
DCCLINK=-rom -l rom.lib
ROMABLE=$(DBIN)/romable
ROM_ADDR=0x2000

C_SRC=main.c fdd.c fat.c osd.c hardware.c fpga.c mmc.c hdd.c menu.c
C_ASM=start.asm
C_HDR=config.h errors.h fat.h fdd.h firmware.h fpga.h hardware.h hdd.h menu.h mmc.h osd.h
ALL_SRC=$(patsubst %,src/%,$(C_SRC) $(C_ASM))
ALL_HDR=$(patsubst %,src/%,$(C_HDR))

REL_BIN=menu
ABS_BIN=OSD_CA01.sys

all: $(ABS_BIN)

clean:
	rm -f $(REL_BIN) $(ABS_BIN)

$(REL_BIN): $(ALL_SRC) $(ALL_HDR)
	$(DCC) $(DCCOPTS) $(ALL_SRC) -o $(REL_BIN) $(DCCLINK)

$(ABS_BIN): $(REL_BIN)
	$(ROMABLE) $(REL_BIN) -o $(ABS_BIN) -DC -C $(ROM_ADDR)