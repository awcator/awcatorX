;    +-------------------------+
    ;|    Interrupt Vector     |        // check interrupt.asm
    ;|    Table (IVT)          |
    ;|  0x00000 - 0x000FF      |
    ;|        (1KB)            |
    ;+-------------------------+
    ;|      BIOS Data Area     |
    ;|  0x00100 - 0x001FF      |
    ;|        (1KB)            |
    ;+-------------------------+
    ;|    Empty / Reserved     |
    ;|  0x00200 - 0x07BFF      |
    ;|       (29KB)            |
    ;+-------------------------+
    ;|    Bootloader Code &    |
    ;|     Data (RAM/ROM)      |
    ;|  0x07C00 - 0x07E7F      |
    ;|       (0.5KB)           |
    ;+-------------------------+
    ;|   Free Memory Area for  |
    ;|    Bootloader Usage     |
    ;|  0x07E80 - 0x09FFF      |
    ;|        (8KB)            |
    ;+-------------------------+
    ;|    Empty / Reserved     |
    ;|  0x0A000 - 0x0EFFFF     |
    ;|       (56KB)            |
    ;+-------------------------+
    ;|     Video Memory        |
    ;|   (Memory-mapped I/O)   |
    ;|  0x0F000 - 0x0FFFF      |
    ;|        (4KB)            |
    ;+-------------------------+
    ;|   Empty / Reserved      |
    ;|  0x100000 - ...         |
    ;+-------------------------+

; The code-design should be done like as if this runs in Intel 8086 processor from 1970s, it should be in 16bit instructions, also called real-mode.
; References for this code should be done by reading 8086 processor architecture but not x86_64 architecture  (x86_64/x86 instructions wont work)
; Author Awcator
; todo https://stackoverflow.com/questions/9660315/bootloader-strange-behavior?rq=3 https://wiki.osdev.org/El-Torito
; https://github.com/asido/OS/tree/master/boot
ORG 0x7C00           ;   Set the origin to 0x7C00 where the bootloader will be loaded.; comment this line to run in debug mode, to compile without symbols for prod, uncomment this
BITS 16              ;   Tell assembler we want to use 16bits instructions. We want to run in real mode
; Satisfy BIOS parameter block: read https://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29
jmp short start
nop
times 33 db 0       ; let the BIOS fill the first 33bytes after nop instruction, since bios likes to feed BIOS param block info to the bootloaders memory section. Not all BIOS fills it

start:              ;   section label, denoted by $$
    ;cli             ;   clear interrupts/Disable interrupts, since we want to  modify segment register, we dont want interrupts to happen by bios
    ;   mov ax, 0x7c0
    ;   mov ds,ax   ; Manually assigns ourself values to the data segments register, bcz we made org as 0x0
    ;   mov es,ax   ; Manually assigns ourself values to the Extra segments register
    ;   mov ax,0x0000 ; should we start ss from 0? or from 0x7c0
    ;   mov ax, 0x00 ; 0x7c0+544
    ;   mov ss,ax   ; Manually assigns Stack segments register
    ;   mov sp, 0x7c00  ; stackPointer above
    ;sti             ; enable back bios interrupts

    ;%include "./src/bootloader/custom_interrupt_vector-table.asm"
    ;mov ax, cs
    ;mov ds, ax
    ;mov word [ds:0x00], handle_zero_interrupt          ;Point 0x00 to our custom code
    ;mov word [ds:0x02], cs                             ;point our code-segment from where code should be picked-up
    ;int 0                                              ;Since we registered our code at 0x00 we will trigger it by calling 0th interrupt

    ;%include "./src/bootloader/disk-access.asm"
    ;jmp DISK_READ;

    CODE:mov si, bootloader_title ;   point sourceIndex register point message address. This register will be used by lodsb
    call print_string_pointed_by_ds_and_si ; ds*16+si

    ; GDT implementation starts here, inorder to move from 16 bit real mode to protected mode
    %include "./src/bootloader/gdt_x86.asm"
    jmp $

    ; ------------------------------------------------------------------------------------
    ; some functions
    print_string_pointed_by_ds_and_si:
        mov bh,0xa0        ;   color background/foreground.
        mov bl,0x07
        for_each_letter:
            lodsb         ;   moves letter (byte) pointed by DS:SI to al
            cmp al,0x0    ;   check if letter is null character or 0
                je endof_for_each_letter ; if al==0? then ZeroFlag=1, je checks ZF is 1 or not. if 1 jumps to endforeachLetter
            call ask_bios_to_print_at_AL ; else call bios to print what AL contains
            jmp print_string_pointed_by_ds_and_si ; again for next character, lodsb increments char position
        endof_for_each_letter:
            ret
    ask_bios_to_print_at_AL: ; it assumes al register is already filled with a character to be displayed
        mov ah, 0x0e    ;   or make it 0eh both are same. It acts as argument for bios to do, where  0x0e=VIDEO - TELETYPE OUTPUT operation http://www.ctyme.com/intr/rb-0106.htm
        int 0x10        ;   Ask BIOS to do it by calling interrupt. Why exact value 0x10? http://www.ctyme.com/intr/rb-0106.htm
        ret
; modification of binary file
; we know our bootloader should have signature 0xAA55 so we hv to create the binary with that ending signature
; we want to put 0xAA55 in 511th byte in the binary. So we pad with zeros or anything (better zeros) from current location upto 510th byte location
; how we do is, we will calculate number of bytes to be padded. '$; gives address of last instruction. '$$' gives  the address of 'start' section
disk_load_error: db 'Error loading the DISK',0x0 ; A global variable like definition
bootloader_title: db 'Loaded AwcatorXBootLoader 0.1',0x0 ; A global variable like definition
times 510-($ - $$) db 0 ;   Pad zeros till 510th byte of the binary file
dw 0xAA55               ;   Intel LittleEndian format. Write 0x55AA from 511th byte of the binary file. Now bios thinks this binary as bootloader binary. DW is 2 bytes, so it will write 0x55aa in 511th byte and 512th byte
buffer:                 ;   In case you want for extra purpose. like loading disk or kernel