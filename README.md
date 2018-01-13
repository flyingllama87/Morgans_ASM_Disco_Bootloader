# Morgans_ASM_Disco_Bootloader
Just a fun bootsector to learn some X86 ASM.

Modern computing environments are abstracted far, far away from machine code & as a result many techs don't understand how computers work.  I decided to write something fun with X86 assembler to learn more about them.  The end result of that was....  Morgan's Disco Bootsector!

This is a bootable program on any IBM compatible PC that does the following:
- Sets the display to VGA graphics mode (320x200x256)
- Plays 'Hot Cross Buns' through the PC speaker (often routed through the soundcard on modern PCs)
- Every time the song's verse ends, fill the screen pixels with random colours.
- Repeat indefinitely!

Video of it here:
https://youtu.be/kVPWyRFjVck

This was a great learning exercise.  Here are some of the things I learned about over the course of the exercise:

- PC bootloaders & the magic bytes at 510-512.
- 16-bit 'Real-mode' X86 segmented memory model.
- int 10h BIOS interrupts to set screen modes (e.g. character & graphics modes) & writing to the video buffer at 0x0a0000.
- Configuring your PC's programmable timers (PIT) for timing in your application as well as for the PC speaker.
- Random number generation (linear congruential PRNG).
- Debugging low level code in bochs.

Install / testing:
1) You can boot it with QEMU:
qemu-system-i386 c:\asm\bootme.img -soundhw pcspk

2) You can create a bootable USB flash drive by writing the sector with 'USB image tool' (Windows).

Credit:
I based by PC speaker routines off this article so credit to him:
http://www.fysnet.net/snd.htm


