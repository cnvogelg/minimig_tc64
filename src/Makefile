C_SRC=fat.c fdd.c fpga.c hardware.c  hdd.c main.c menu.c mmc.c osd.c printf.c swap.c config.c rafile.c
KLIBC_SRC=vsnprintf.c sprintf.c memcpy.c memcmp.c strcpy.c strcat.c strncat.c strncmp.c strlen.c memset.c strncpy.c strchr.c
A_SRC=startup.s

BUILD_DIR=BUILD
C_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SRC))
LIBC_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(KLIBC_SRC))
A_OBJ=$(patsubst %.s,$(BUILD_DIR)/%.o,$(A_SRC))
OBJ=$(C_OBJ) $(A_OBJ)

ARCH=68000
CC=m68k-elf-gcc
AR=m68k-elf-ar
OBJCOPY=m68k-elf-objcopy
CFLAGS+=-m$(ARCH) -Wall -Wno-char-subscripts -Os -fno-common -fomit-frame-pointer -I./include
LDFLAGS+=-m$(ARCH) -Xlinker -Map=menu.map -nostartfiles -L.

ELF=menu.elf
OUTPUT=OSD_CA01.sys
LINK_SCRIPT=osdcpu.ld
LIBC_TARGET=libc.a

all: $(BUILD_DIR) $(LIBC_TARGET) $(OUTPUT)

clean:
	rm -rf $(BUILD_DIR) $(LIBC_TARGET) $(ELF) $(OUTPUT)

$(LIBC_TARGET): $(LIBC_OBJ)
	$(AR) -r $(LIBC_TARGET) $(LIBC_OBJ)

$(OUTPUT): $(ELF)
	$(OBJCOPY) -O binary $(ELF) -j .code $(OUTPUT)

$(ELF): $(OBJ) $(LINK_SCRIPT)
	$(CC) $(LDFLAGS) -o $@ -T $(LINK_SCRIPT) $(OBJ) $(NEWLIB)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
	
$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: klibc/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<
