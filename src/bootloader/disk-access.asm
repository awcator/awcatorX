; Two ways to Read, LBA(logical block address) and CHS (cylinder head sector)  way

; In LBA if u want to read at 58376 byte
; LBA= 58376/512  ==114where 512 is the sector size of the disks. HDD usually 512, DVD/CD above 2048b or 2KB
; then from block, we need to get the offset to reach the data pointer
; offset= 58376    %   512=8
; 512*114+8=58376

; CHS way
; BIOS provider 13h to read from disk in realMode https://www.ctyme.com/intr/int.htm
; http://www.ctyme.com/intr/rb-0607.htm
DISK_READ:
    mov ah, 0x2 ;DISK - READ SECTOR(S) INTO MEMORY operator
    mov al, 0x1 ;number of sectors to read
    mov ch, 0x0 ;our cylinder number
    mov cl, 0x2 ; sector number to read
    mov dh, 0x0 ; head number
    ;mov dl, someDriveNumber, when I boot from qemu as single disk, bios automatically loads up my drive number at dl. ill just make use of the same. 0x80 was my DL.
    ;  (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2)
    ;   eg. qemu -fda boot_sect_main.bin. read from floppy-disk
    mov bx,buffer; output is stored at ES:BX -> data buffer. So we bring our memory space address into bx
    int 0x13    ; call the interrupt to read the DISK
    jc error    ; if any error while reading disk it will put carry flag set to 1, if carry=1?jump to error. else print out disk contents
    mov si, buffer
    call print_string_pointed_by_ds_and_si
    jmp CODE    ; we dont want execute next line. so go back to where it was called

; say error if error occurred while reading
error:
    mov si, disk_load_error
    call print_string_pointed_by_ds_and_si ; from bootloader.asm