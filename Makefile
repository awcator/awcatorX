BIN_LOCATION=./bin/
all: debug_bootloader

bootloader:
	echo "Compiling Bootloader"
	nasm  -f bin ./src/bootloader/bootloader.asm -o ${BIN_LOCATION}awcator_bootloader.bin
	qemu-system-x86_64 -hda ${BIN_LOCATION}awcator_bootloader.bin
debug_bootloader:
	echo "Compiling Bootloader for debug purpose"
	# https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr
	nasm -f elf32 -g3 -F dwarf ./src/bootloader/bootloader.asm -o ${BIN_LOCATION}awcator_bootloader.o
	ld -Ttext=0x7c00 -melf_i386 ${BIN_LOCATION}awcator_bootloader.o -o ${BIN_LOCATION}awcator_bootloader.elf
	objcopy -O binary ${BIN_LOCATION}awcator_bootloader.elf ${BIN_LOCATION}awcator_bootloader.img
	qemu-system-i386 -hda ${BIN_LOCATION}awcator_bootloader.img -S -s

clean:
	rm -f ${BIN_LOCATION}awcator_bootloader.bin ${BIN_LOCATION}awcator_bootloader.elf ${BIN_LOCATION}awcator_bootloader.img ${BIN_LOCATION}awcator_bootloader.o

# Phony targets to avoid conflicts with file names
.PHONY: all bootloader run_bootloader debug_bootloader kernel clean