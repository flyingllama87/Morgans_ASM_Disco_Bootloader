; Morgan's Disco PC Bootsector
; This is a bootable program on any IBM compatible PC that does the following:
; - Sets the display to VGA graphics mode
; - Plays 'Hot Cross Buns' through the PC speaker (often routed through the soundcard on modern PCs)
; - Every time the song's verse ends, fill the screen pixels with random colours.
; - Repeat indefinitely!

org 7C00h    ; load code at 0x7C00 address; which is where the BIOS passes control to when it's ready to boot.


music_to_play   dw  2420,255  ; data used for song 'Hot Cross Buns'.  Values are the frequency divider used by the PIT followed by how many PIT ticks have to occur before moving on to the next note
                dw  23863, 01
                dw  2711,255
                dw  23863, 01
                dw  3043,511
                dw  23863,01
                dw  2420,255
                dw  23863, 01
                dw  2711,255
                dw  23863, 01
                dw  3043,511
                dw  23863,01
                dw  3043,07
                dw  23863,01
                dw  3043,07
                dw  23863,01
                dw  3043,07
                dw  23863, 01
                dw  3043,07
                dw  23863,01
                dw  2711,07
                dw  23863,01
                dw  2711,07
                dw  23863,01
                dw  2711,07
                dw  23863,01
                dw  2711,07
                dw  23863,01
                dw  00h,00h

start:
           ; configure seed number for RNG
           mov ax, 07E00h 			; point ds:di to free area in memory to store data in ram
           mov di, ax     			; set data pointer to 7E00
           mov ax, 0 				; set segment 0
           mov ds, ax  				; use data segment register
           mov word [ds:di], 7634  	; configure seed number for pseudo random number generator

.set_gfx_mode:     
		   ; set vga graphics mode
           mov ah, 0 				; select video mode function
           mov al, 13h				; mode 13 / graphics / 320x200x256
           int 10h 					; call interrupt 10h
           jmp draw_disco_start 	; first time we run, fill screen with random pixel data first


play_music_again:
           ; set ss:si to base of system memory... used by the music subroutines. This could be based elsewhere so I don't have to set this everytime the music plays
           mov dx, 00h 				; set base of memory
           mov ss, dx 				; move address into memory segment register
           mov si, 0h				; set stream index to base of memory location.

           mov  si, music_to_play ; move the data from the music to the memory location.

           mov  dx,61h 				; turn speaker on
           in   al,dx  				; read 61h I/O byte
           or   al,03h   			; bit mask used to ensure only the least significant 2 bits of 61h is turned ON
           out  dx,al    			; write 61h I/O byte

           mov  dx,43h  			; get the timer ready
           mov  al,0B6h  			; magic number used to configure the timer
           out  dx,al   			; write byte to 43h (PIT command IO port)

loop_it:   lodsw     				; load desired frequency (si is automatically incremented)
           or   ax,ax   			; if freq. = 0 then the loop is done
           jz   short loop_done 
           mov  dx,42h 				; I/O port to output to, 42h is the PIT io port for the PC speaker (timer 2)
           out  dx,al  				; output low order byte
           xchg ah,al
           out  dx,al      			; output high order byte
           lodsw           			; get duration of note
           mov  cx,ax       		; put note time data in cx (16 = 1 second) - MR edit: didn't find this the case at all
           call pause_it     		; goto 'PauseIt' routine which is used to wait for PIT timer 1 before continuing)
           jmp  short loop_it   	; Load next note

loop_done: mov  dx,61h  			; turn speaker off
           in   al,dx
           and  al,0FCh  			; 0FC = bit mask to turn speaker off (last 2 bits set to 0)
           out  dx,al
           jmp draw_disco_start  	; goto the disco drawing routine!


; This routine waits for a specified amount of milliseconds (within 50ms)
; Since I want to keep it simple, I am going to use the BIOS timer tick
; at 0040:006Ch. It increments 18.2 times a second (1000 milliseconds divided by 18.2 = ~55ms)
; This is not a very good delay.  Depending on when it is called,
; it could delay up to 110ms.  However it will always delay at least 55ms
; See here for more: http://www.fysnet.net/snd.htm
; MR note:  Works on real hardware and QEMU but had trouble on bochs.  This memory location is never incremented.



pause_it:
           mov  ax,0040h  			; set base of es segmentation register
           mov  es,ax

           ; wait for it to change the first time
           mov  al,[es:006Ch]
@@:        cmp  al,[es:006Ch] 		; bochs will indefinitely loop here as 0040:006C is never incremented.
           je   short @b   			; short jump to previous line

           ; wait for it to change again.  This is to ensure at least 55ms has passed (in crease we jmped here towards the end of a PIT tick update.
.loop_it:   mov  al,[es:006Ch]
@@:        cmp  al,[es:006Ch]
           je   short @b  			; jump to previous line until value at above memory address updates.

           sub  cx,55
           jns  short .loop_it  	; JMP if not signed... Perhaps JMP if the result of the above command is less than 0 (i.e. at least 55ms has been

           ret  					; return to caller


draw_disco_start:

           ; .framebuffer_init: set ss:si to base of frame buffer memory
           mov dx, 0A000h 			;set base of framebuffer
           mov ss, dx 				; move address into memory segment register
           mov si, 0h 				; select memory location 5 (pixel 5?)

           ; set data pointer to 0000:7E00, a safe place for data to go
           mov ax, 07E00h 			; point ds:di to free area in memory to store data in ram
           mov di, ax 				; set data pointer to 0000:7E00, a safe place for data to go
           mov ax, 0 
           mov ds, ax  				; use data segment register
           jmp .fill_screen 		; jump to routine to fill screen with random pixel data
.draw_disco_step_1:
           jmp play_music_again 	; Go near the start of the program and replay music! I.E. repeat forever!

.fill_screen:
           inc di 					; increment di so it's pointing at a new memory location that we will use to store the loop counter
           inc di 					; need to do it a second time as it's a word and not a byte we are skipping over

           mov word [ds:di], 64000 	; loop 64,000 times! Enough for 320x200
.fill_screen_pixel_loop:
           dec word [ds:di] 		; lower loop value
           cmp word [ds:di], 0 		; have we reached 0?
           jne .draw_pixel  		; if not, draw a random pixel (goto draw_pixel)
           jmp .draw_disco_step_1  	;if we've reached 0, Go to next stage of disco process (which is to restart)


.RNG:  ;linear congruential PRNG ; random integer stored in dx after execution
           dec di 					; point at the data used by the RNG for seed value
           dec di 					; dec second time as it's a word of memory we are skipping over; not a byte

           mov cx, [ds:di]
           mov ax, 8121 ; 16807 	; configure LC PRNG start value (mul)
           mul cx
           mov cx, 1 ; 12345  		; configure LC PRNG start value (add)
           add ax, cx
           mov cx, 8191 ; 8191  	; configure LC PRNG start value  (mod)
           div cx
           mov [ds:di], dx 			; store result for later use by PRNG in memory

           inc di					; point back at the memory with values used by the loop
           inc di

           jmp .draw_pixel_return  	; new random number ready to go... time to write it to the video buffer!


.draw_pixel:
            jmp .RNG  				; call RNG for each pixel
.draw_pixel_return:
            mov byte [ss:si], dl 	; write color (pixel) to specified memory address (a byte in the video buffer)
            inc si 					; move along to next pixel

            jmp .fill_screen_pixel_loop ; finish drawing random pixel, returning to fill pixels function / loop

;.end


times 510-($-$$) db 0  				; fill rest of 512 byte sector with NUL bytes
dw 0xAA55   						; boot loader magic byte