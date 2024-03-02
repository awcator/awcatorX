; protected mode is a 32bit  operational mode, so we can address upto 4GB of memory.
; first part before switching to portected mode, we need to define how segmentation is going to work in 32 bit after the switch
; it would have done by adjust some registers like ds,cs,ss,es with some values in 16 bit real mode,
; but in protected mode, we do segmention in a diffrent way

; each segment has set of permissions and properties, we need to set it in a datastructrure called GDT (Global Discriptor table)
;  +-----------------------------------------------+
;  |                   GDT Header                  |--> 8 bytes
;  +-----------------------------------------------+
;  |          Null Descriptor (Not used)           |--> 8 bytes
;  +-----------------------------------------------+       .
;  |              Code Segment Descriptor          |       .
;  +-----------------------------------------------+       .
;  |              Data Segment Descriptor          |       .
;  +-----------------------------------------------+       .
;  |            Stack Segment Descriptor           |       .
;  +-----------------------------------------------+       .
;  |               Additional Descriptors          |       .
;  +-----------------------------------------------+       .
;  |                   ...                         |--> 8 bytes each
;  +-----------------------------------------------+

; we need to define descriptior for each segment. descriptior=list of proprties of a segment
; GDT must contians atleast two segment: CODE segment descriptor & Data segment descriptor
; here word=2bytes, doubleword=4 bytes

; First Double Word:
; +---------------------------------------+
; |  0-15  |         Limit 0:15           | First 16 bits in the segment limiter
; +---------------------------------------+
; | 16-31  |         Base 0:15            | First 16 bits in the base address
; +---------------------------------------+

; Second Double Word:
; +---------------------------------------+
; |  0-7   |       Base 16:23             | Bits 16-23 in the base address
; +---------------------------------------+
; |  8-12  |           Type               | Segment type and attributes (A,RW,DC,E,S)
; +---------------------------------------+
; | 13-14  |   Privilege Level            | 0 = Highest privilege (OS), 3 = Lowest privilege (User applications)
; +---------------------------------------+
; |   15   |      Present flag            | Set to 1 if segment is present
; +---------------------------------------+
; |16-19   |       Limit 16:19            | Bits 16-19 in the segment limiter
; +---------------------------------------+
; |20-22   |        Attributes            | Different attributes/flags, depending on the segment type
; +---------------------------------------+
; |   23   |        Granularity           | Used together with the limiter, to determine the size of the segment
; +---------------------------------------+
; |24-31   |       Base 24:31             | The last 24-31 bits in the base address
; +---------------------------------------+

; must be at the end of real mode code
; http://web.archive.org/web/20190424213806/http://www.osdever.net/tutorials/view/the-world-of-protected-mode
; mov [BOOT_DISK], dl

CODE_SEG equ GDT_code - GDT_datastructure_start ; calculate GDT CODE SEGMENT ADDRESS
DATA_SEG equ GDT_data - GDT_datastructure_start ; calculate GDT DATA SEGMENT ADDRESS

; we want to move to protected mode or x86 mode, before doing so, disable all interupts and load the GDT using lgdt

cli
lgdt [GDT_descriptor]

mov eax, cr0 ; as per Intel Doc, we have to modify 0th bit of cr0 register before going to protected mode
or eax, 1    ; basically setting up 1 at 0th bit
mov cr0, eax

jmp CODE_SEG:start_protected_mode
jmp $

GDT_datastructure_start: ; starting of GDT data structure, we start with null dataheader
    gdt_null_descriptor:
        dq 0x0    ;  Null descriptor 8 bytes of data zeroes
    GDT_code: ; more like kernel code segment
        ; First Double Word info
        dw 0xffff  ; The first 16 bits sets the limit, We aim at a limit of 4 GB (0FFFFFh limit total, note 5 F, i have set 4fs now, one more later)
        dw 0x0     ; we set the base address to 0 (start of memory).

        ; Second Double Word
        db 0x0     ; the base address continues; we fill next 8 bits or 1 byte with zeros
        db 10011010b ; next 8 bits, type, privillage, present (read from right to left)
        ;  ||||||||-> A: First Bit of TYPE(4 bits): Accessed bit. The CPU will set it when the segment is accessed unless set to 1 in advance. This means that in case the GDT descriptor is stored in read only pages and this bit is set to 0, the CPU trying to set this bit will trigger a page fault. Best left set to 1 unless otherwise needed. We don't have any use for this, so leave it 0.
        ;  |||||||--> RW:For code segments: Readable bit, for For data segments: it acts like Writeable bit. If set (1) read access is allowed. Write access is never allowed for code segments.
        ;  ||||||---> DC: Direction bit(for data segment)/Conforming bit (for code segment), If this bit is set, then less privileged code segments is allowed to jump to or call this segment. In an OS, we don't want that, so we clear this bit to 0.
        ;  |||||----> E: Executable bit, if clear (0) the descriptor defines a data segment. If set (1) it defines a code segment which can be executed from.
        ;  ||||-----> S: It is descriptor type bit,  If clear (0) the descriptor defines a system segment (eg. a Task State Segment). If set (1) it defines a code or data segment.   1010b (binary). Readable code segment, nonconforming.
        ;  |||------> DPL: Privillage bit, ring privillages level, 0 to 3 values. 0 means kernel ring 3 means user apps
        ;  ||-------> DPL: we made it 00, which is ring 0, so it is a kernel privallged segment
        ;  |--------> P: Present bit. Allows an entry to refer to a valid segment. Must be set (1) for any valid segment.

        db 11001111b    ; The limit continuation, Atrribute, Granularity
        ;  ||||||||-----> Continuation of limit, i want to add F (4 bits of 1)
        ;  |||||||------> Continuation of limit
        ;  ||||||-------> Continuation of limit
        ;  |||||--------> Continuation of limit
        ;  ||||---------> Intel reserved bit, its 0
        ;  |||----------> L: Long-mode code flag.If set (1), the descriptor defines a 64-bit code segment, When set, DB should always be clear.
        ;  ||-----------> (DB) Size Bit, should be set in our case (this tells the CPU we have 32-bit code and not 16-bit).
        ;  |------------> (G) Granularity bit, it indiciates the size the Limit value is scaled by. If clear (0), the Limit is in 1 Byte blocks (byte granularity).If set (1), the Limit is in 4 KiB blocks (page granularity).
        ;                 (if set) limiter multiplies the segment limit by 4 KB. In our case, this is what we want. We wanted a limit of 4 GB (maximum), and the limit we set was 0FFFFFh. Now, if we multiply this by 0x1000, what do we get?  0xfffff000 or (2^20 - 1) << 12 or 4 GB
        ;                 When the granularity bit is set, the limit is indeed shifted left by 12 bits, but it's important to note that one-bits are inserted. So 0xfffff results in a limit of 0xffffffff, and 0x00000 results in a limit of 0x00000fff
        ;                 https://stackoverflow.com/questions/26577692/what-exactly-does-the-granularity-bit-of-a-gdt-change-about-addressing-memory
        ;                 https://archive.org/details/bitsavers_intel80386ammersReferenceManual1986_27457025

        db 0x0          ; filling up last 8 bits for base address

    GDT_data:
        ; First Double Word info
        dw 0xffff ; The first 16 bits sets the limit, We aim at a limit of 4 GB (0FFFFFh limit total, note 5 F, i have set 4fs now, one more later)
        dw 0x0    ; we set the base address to 0 (start of memory).

        ; Second Double Word
        db 0x0      ; the base address continues; we fill next 8 bits or 1 byte with zeros
        db 10010010b
        ;  ||||||||-----> A: First Bit of TYPE(4 bits): Accessed bit. The CPU will set it when the segment is accessed unless set to 1 in advance. This means that in case the GDT descriptor is stored in read only pages and this bit is set to 0, the CPU trying to set this bit will trigger a page fault. Best left set to 1 unless otherwise needed. We don't have any use for this, so leave it 0.
        ;  |||||||------> RW: Writeable bit. If clear (0), write access for this segment is not allowed. If set (1) write access is allowed. Read access is always allowed for data segments.
        ;  ||||||-------> Direction bit Direction bit. If clear (0) the segment grows up. If set (1) the segment grows down, ie. the Offset has to be greater than the Limit.
        ;  |||||----> E: Executable bit, if clear (0) the descriptor defines a data segment. If set (1) it defines a code segment which can be executed from.
        ;  ||||-----> S: It is descriptor type bit,  If clear (0) the descriptor defines a system segment (eg. a Task State Segment). If set (1) it defines a code or data segment.   1010b (binary). Readable code segment, nonconforming.
        ;  |||------> DPL: Privillage bit, ring privillages level, 0 to 3 values. 0 means kernel ring 3 means user apps
        ;  ||------> DPL: Privillage bit, ring privillages level, 0 to 3 values. 0 means kernel ring 3 means user apps
        ;  |--------> P: Present bit. Allows an entry to refer to a valid segment. Must be set (1) for any valid segment.

        db 11001111b ; refer gdt_code_descriptor for why this value
        db 0x0       ; filling up last 8 bits for base address
        GDT_datastructure_end:     ; Dummy symbol to the end of descriptor datastructure. We use this symbol to generate compile time (nasm compiletime) to generate size for GDT, and we load GDT using ldgt op

GDT_descriptor:
    dw GDT_datastructure_end - GDT_datastructure_start - 1
    dd GDT_datastructure_start

[bits 32]           ; we tell our assembler that, from now on we work with 32bit register
start_protected_mode:
    mov al, 'a'     ; just draw some letter x on to the screen
    mov ah, 0xac    ; color information
    mov [0xb8000], ax   ; write into the video memory
    mov al, 'w'     ; just draw some letter x on to the screen
    mov [0xb8002], ax   ; write into the video memory
    mov al, 'c'     ; just draw some letter x on to the screen
    mov [0xb8004], ax   ; write into the video memory
    mov al, 'a'     ; just draw some letter x on to the screen
    mov [0xb8006], ax   ; write into the video memory
    mov al, 't'     ; just draw some letter x on to the screen
    mov [0xb8008], ax   ; write into the video memory
    mov al, 'o'     ; just draw some letter x on to the screen
    mov [0xb800a], ax   ; write into the video memory
    mov al, 'r'     ; just draw some letter x on to the screen
    mov [0xb800c], ax   ; write into the video memory
    mov al, 'X'     ; just draw some letter x on to the screen
    mov [0xb800e], ax   ; write into the video memory
    jmp $           ; and loop it
; BOOT_DISK: db 0