; Incomplete just tried to do it. game size exceeded 512Bytes. so parked for now. At least basic graphics works
ORG 0x7C00          ;   Set the origin to 0x7C00 where the bootloader will be loaded.
BITS 16             ;   Tell assembler we want to use 16bits instructions. We want to run in real mode
;   Some Global Constants
VIDEO_MEMORY equ 0xb800     ;   VGA color memory starting address
ROW_LENGTH_BYTES equ   160  ;   80 characters*2Bytes=160bytes for each line
PLAYER_X_AXIS equ 4         ;   Draw player at 2nd letter of a line. why not 1? sometimes not visible to eye due to the edge of screen. so move to 2nd letter(*2 bytes for color+letter).
CPU_X_AXIS equ 154          ;   160-2char space*2 byte size

;   Setup video mode
mov ax,0x03         ;   a text mode with 80x25 chars and 16 colors VGA, 0x01 is a monochrome
int 10h             ;   setup video-mode. Now screen blackout

;   Point es to videoMemory
mov ax,VIDEO_MEMORY       ;   if it is a monochrome, memory starts from 0xb000
mov es,ax                 ;   es:di =0xb800:0x0000

game_loop:
    ;   clear screen every cycle. or repaint whole screen with black     https://wiki.osdev.org/Text_UI
    xor ax,ax       ;   set color and text to print as empty. Black pixels(letter)
    xor di,di       ;   reset di to 0 and increment all the way till cx
    mov cx, 80*25   ;   total number of times to draw color (80 rows*25 col) pixel screen
    rep stosw       ;   same as mov [es:di],ax; inc di. replaced by 1 byte instruction. Basically it writes into video memory with black

    xor di,di
    mov ax,0xDE41   ;   write letter A (0x41) in 0xDE color
    stosw           ;   put ax contents to es:di position. that is indirectly writing into video memory results in drawing a letter


    ;   Draw middle line/separator
    xor al,al        ;   clear up al (the letter). otherwise it will print letter with along the line
    mov ah, [drawColor]     ;   white bg, black fg
    mov di, 78       ;   80 columns we hv . 80/2=40. index start from 0. so 40-1=39. we will draw line at 39th colum. since each character takes 2 bytes, 39*2=78. so plot at address 78
    mov cx, 13       ;   draw dash every line by line, giving one space line gap. we hv 25 rows. so 13 times
    .draw_middle_LineLoop:
        stosw
        ;   di is portioned at 78, which is middle of first line, we want to jump to next line everytime to draw line on next line. each line has 80letters, each letters has 2b (letter+color info) and we want to jump every two lines. so its
        ;   so di should be incremented by 80box*2Bytes/box*2 (twice)=320. but stosw by default increment by 1 word that is 2byte, we subtract it.
        add di,ROW_LENGTH_BYTES*2-2
        loop .draw_middle_LineLoop ; until cx times

    ;Draw Player
    imul di,[PLAYER_Y_AXIS],ROW_LENGTH_BYTES    ; position the di to draw player to his y-axis line(row)
    add di,PLAYER_X_AXIS                        ; adjust his x-axis
    mov cl,5
    .drawPlayer_loop:
        stosw                   ; loops until cx
        add di,ROW_LENGTH_BYTES-2
        loop .drawPlayer_loop

    ;Draw CPU:
    imul di,[PLAYER_Y_AXIS],ROW_LENGTH_BYTES    ; position the di to draw player to his y-axis line(row)
    mov cl,5
    .drawCPU_loop:
        mov [es:di+CPU_X_AXIS],ax  ; same as player code, just eliminated stosw. just to show it works same
        add di,ROW_LENGTH_BYTES
        loop .drawCPU_loop

    ;Draw Ball:
    imul di,[BALL_Y_AXIS],ROW_LENGTH_BYTES    ; position the di to draw player to his y-axis line(row)
    add di, [BALL_X_AXIS]
    mov word [es:di], 0x2000 ;   no character with green color



    ;   Cause a simple delay
    ;   https://wiki.osdev.org/Memory_Map_(x86)#:~:text=Note%3A%20the%20EBDA%20is%20a,be%20found%20using%20significantly%20more.
    mov bx,[0x046C] ; get the value of IRQ0 timer ticks since boot, increment twice, wait till it reaches same, that way we cause delay
    inc bx
    inc bx
    .delay_loop:
        cmp [0x046C],bx
            jl .delay_loop  ; jump if less than to back to loop

jmp game_loop
drawColor: db 0xf0
PLAYER_Y_AXIS: dw 10    ; start from 10th line
CPU_Y_AXIS: dw 10    ; start from 10th line
BALL_X_AXIS: dw 66   ; middle character position is 78(the center line), just place few space before it. like 6 space? 6*2=12. 78-12=66
BALL_Y_AXIS: dw 7    ;  little above the user
; boot-sector padding
times 510-($ - $$) db 0 ;   Pad zeros till 510th byte of the binary file
dw 0xAA55               ;   Intel LittleEndian format. Write 0x55AA from 511th byte of the binary file. Now bios thinks this binary as bootloader binary. DW is 2 bytes, so it will write 0x55aa in 511th byte and 512th byte
