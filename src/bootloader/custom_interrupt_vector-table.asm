    ;      +-----------------+
    ;      |      IVT        |
    ;      | (Interrupt      |
    ;      |  Vector Table)  |
    ;      +-----------------+
    ;      |      ...        |   <- Lower Memory Addresses
    ;      +-----------------+
    ;      |   IVT Entry 0   |   <- 0x0000:0000 (Size: 4 bytes). 2Bytes points the offset, next 2Bytes points the data segment
    ;      +-----------------+
    ;      |   IVT Entry 1   |   <- 0x0000:0004 (Size: 4 bytes)
    ;      +-----------------+
    ;      |      ...        |
    ;      +-----------------+
    ;      |   IVT Entry 255 |   <- 0x0000:03FC (Size: 4 bytes)
    ;      +-----------------+
    ;      |      ...        |
    ;      +-----------------+
    ; We have total 256 IVT entries, each IVT entries of 4B, 256*4=1KB memory is reserved for IVT

; Define Interrupt. Simple Interrupt that prints 'Z'
handle_zero_interrupt:
    mov ah, 0eh
    mov al, 'Z'
    mov bx, 0x00
    int 0x10
    retf