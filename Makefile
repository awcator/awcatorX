BIN_LOCATION=./bin/

kernel_objects=kernel.o loader.o
mkdir_bin:
	echo "creating bin"
	mkdir ${BIN_LOCATION} | true
all: debug_bootloader
#all: append_second_sector_disk_to_bootloader_bin
boot_sector_apps: mkdir_bin
	echo "Compiling bootsector apps: bootpong"
	nasm  -f bin ./src/apps/boot_sector_apps/boot_pong.asm -o ${BIN_LOCATION}boot_pong.bin
	qemu-system-x86_64 -hda ${BIN_LOCATION}boot_pong.bin

bootloader: mkdir_bin
	echo "Compiling Bootloader"
	nasm  -f bin ./src/bootloader/bootloader.asm -o ${BIN_LOCATION}awcator_bootloader.bin
	qemu-system-x86_64 -hda ${BIN_LOCATION}awcator_bootloader.bin
debug_bootloader: mkdir_bin
	echo "Compiling Bootloader for debug purpose"
	# https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr
	nasm -f elf32 -g3 -F dwarf ./src/bootloader/bootloader.asm -o ${BIN_LOCATION}awcator_bootloader.o
	ld -Ttext=0x7c00 -melf_i386 ${BIN_LOCATION}awcator_bootloader.o -o ${BIN_LOCATION}awcator_bootloader.elf
	objcopy -O binary ${BIN_LOCATION}awcator_bootloader.elf ${BIN_LOCATION}awcator_bootloader.img
	qemu-system-i386 -hda ${BIN_LOCATION}awcator_bootloader.img -S -s &
append_second_sector_disk_to_bootloader_bin: bootloader
	dd if=./src/bootloader/hdd_raw_contents.txt >> ${BIN_LOCATION}awcator_bootloader.bin
	# append 512Bytes to the binary file just to make it above 2nd sector disk
	dd if=/dev/zero bs=512 count=1 >> ${BIN_LOCATION}awcator_bootloader.bin

clean:
	rm -f ${BIN_LOCATION}awcator_bootloader.bin ${BIN_LOCATION}awcator_bootloader.elf ${BIN_LOCATION}awcator_bootloader.img ${BIN_LOCATION}awcator_bootloader.o

# Phony targets to avoid conflicts with file names
.PHONY: all bootloader run_bootloader debug_bootloader kernel clean append_second_sector_disk_to_bootloader_bin
