ORG 0x7c00          ;   Tell our bootloader code it is in this position in the ram. How? bcz BIOS loads bootloader and places it in this position. read more at documentation
BITS 16             ;   Tell assembler we want to use 16bits instructions. We want to run in real mode
start:              ;   section label, denoted by $$
    mov al, 'A'     ;   letter you want to print on screen or use ascii integers
    mov ah, 0x0e    ;   or make it 0eh both are same. It acts as argument for bios to do, where  0x0e=VIDEO - TELETYPE OUTPUT operation http://www.ctyme.com/intr/rb-0106.htm
    mov bx,0        ;   color background/foreground.
    int 0x10        ;   Ask BIOS to do it by calling interrupt. Why exact value 0x10? http://www.ctyme.com/intr/rb-0106.htm
    jmp $           ;   Jump itself, we dont want other code to be executed. (next lines)
; modification of binary file
; we know our bootloader should have signature 0xAA55 so we hv to create the binary with that ending signature
; we want to put 0xAA55 in 511th byte in the binary. So we pad with zeros or anything (better zeros) from current location upto 510th byte location
; how we do is, we will calculate number of bytes to be padded. '$; gives address of instruction after int 0x10. '$$' gives  the address of 'start' section
times 510-($ - $$) db 0 ;   Pad zeros till 510th byte of the binary file
dw 0xAA55               ;   Intel LittleEndian format. Write 0x55AA from 511th byte of the binary file. Now bios thinks this binary as bootloader binary. DW is 2 bytes, so it will write 0x55aa in 511th byte and 512th byte