ORG 0x7c00          ;   Tell our bootloader code it is in this position in the ram. How? bcz BIOS loads bootloader and places it in this position. read more at documentation
BITS 16             ;   Tell assembler we want to use 16bits instructions. We want to run in real mode
start:              ;   section label, denoted by $$
    mov si, bootloader_title ;   point sourceIndex register point message address. This register will be used by lodsb
    call print_string_pointed_by_si
    jmp $
print_string_pointed_by_si:
    mov bx,0x0        ;   color background/foreground.
    for_each_letter:
        lodsb         ;   moves letter (byte) pointed by DS:SI to al
        cmp al,0x0    ;   check if letter is null character or 0
            je endof_for_each_letter ; if al==0? then ZeroFlag=1, je checks ZF is 1 or not. if 1 jumps to endforeachLetter
        call ask_bios_to_print_at_AL ; else call bios to print what AL contains
        jmp print_string_pointed_by_si ; again for next character, lodsb increments char position
    endof_for_each_letter:
        ret
ask_bios_to_print_at_AL: ; it assumes al register is already filled with a character to be displayed
    mov ah, 0x0e    ;   or make it 0eh both are same. It acts as argument for bios to do, where  0x0e=VIDEO - TELETYPE OUTPUT operation http://www.ctyme.com/intr/rb-0106.htm
    int 0x10        ;   Ask BIOS to do it by calling interrupt. Why exact value 0x10? http://www.ctyme.com/intr/rb-0106.htm
    ret
; modification of binary file
; we know our bootloader should have signature 0xAA55 so we hv to create the binary with that ending signature
; we want to put 0xAA55 in 511th byte in the binary. So we pad with zeros or anything (better zeros) from current location upto 510th byte location
; how we do is, we will calculate number of bytes to be padded. '$; gives address of instruction after int 0x10. '$$' gives  the address of 'start' section
bootloader_title: db 'Loaded AwcatorXBootLoader 0.1',0 ; A global variable like definition
times 510-($ - $$) db 0 ;   Pad zeros till 510th byte of the binary file
dw 0xAA55               ;   Intel LittleEndian format. Write 0x55AA from 511th byte of the binary file. Now bios thinks this binary as bootloader binary. DW is 2 bytes, so it will write 0x55aa in 511th byte and 512th byte