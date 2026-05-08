!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!

! NOTE! These had better be the same as in bootsect.s!

INITSEG  = 0x9000	! we move boot here - out of the way
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020	! this is the current segment

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
start:
	mov	ax,#SETUPSEG		! set segment registers
	mov	ds,ax
	mov	es,ax
	 
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#23
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10


! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.
! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Get video-card data:

	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

! check for EGA/VGA and some config parameters

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx

! Get hd0 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4 * 0x41]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080
	mov	cx,#0x10
	rep
	movsb

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4 * 0x46]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	rep
	movsb

! Check that there IS a hd1 :-)

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1
	cmp	ah,#3
	je	is_disk1
no_disk1:
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb
is_disk1:

! hardware parameter printing section
! Set segment registers for printing
	mov	ax,#SETUPSEG
	mov	es,ax
	mov	ax,#INITSEG
	mov	ss,ax
	sub	sp,sp

! Print separator
	call	print_setup
	mov	bp,#msgSeparator
	mov	cx,#15
	call	print_str
	mov	ax,#0xe0d
	int	0x10
	mov	al,#0xa
	int	0x10

! Print cursor position
	call	print_setup
	mov	bp,#msgCursor
	call	print_str
	mov	bp,#0x00
	call	print_hex

! Print extended memory size
	call	print_setup
	mov	bp,#msgMemory
	call	print_str
	mov	bp,#0x02
	call	print_hex

! Print display page
	call	print_setup
	mov	bp,#msgDisplayPage
	call	print_str
	mov	bp,#0x05		! bh display page in high byte of [4]
	call	print_hex_byte

! Print video mode
	call	print_setup
	mov	bp,#msgVideoMode
	call	print_str
	mov	bp,#0x06		! al video mode in low byte of [6]
	call	print_hex_byte

! Print window width
	call	print_setup
	mov	bp,#msgWindowWidth
	call	print_str
	mov	bp,#0x07		! ah window width in high byte of [6]
	call	print_hex_byte

! Print EGA/VGA parameter 1
	call	print_setup
	mov	bp,#msgEGA1
	call	print_str
	mov	bp,#0x08
	call	print_hex

! Print EGA/VGA parameter 2
	call	print_setup
	mov	bp,#msgEGA2
	call	print_str
	mov	bp,#0x0A
	call	print_hex

! Print EGA/VGA parameter 3
	call	print_setup
	mov	bp,#msgEGA3
	call	print_str
	mov	bp,#0x0C
	call	print_hex

! Print hd0 cylinder count
	call	print_setup
	mov	bp,#msgCyls0
	call	print_str
	mov	bp,#0x80
	call	print_hex

! Print hd0 head count
	call	print_setup
	mov	bp,#msgHeads0
	call	print_str
	mov	bp,#0x82
	call	print_hex_byte

! Print hd0 sector count
	call	print_setup
	mov	bp,#msgSectors0
	call	print_str
	mov	bp,#0x8E
	call	print_hex_byte

! Check if HD1 exists
	mov	ax,#INITSEG
	mov	ds,ax
	mov	si,#0x0090
	mov	cx,#0x10
check_disk1_loop:
	lodsb	
	or	al,al
	jnz	has_disk1
	loop	check_disk1_loop
	
! No HD1
	call	print_setup
	mov	bp,#msgNoDisk1
	call	print_str
	jmp	print_final_separator

has_disk1:
! Print hd1 cylinder count
	call	print_setup
	mov	bp,#msgCyls1
	call	print_str
	mov	bp,#0x90		! Second hard disk parameter table
	call	print_hex

! Print hd1 head count
	call	print_setup
	mov	bp,#msgHeads1
	call	print_str
	mov	bp,#0x92		! Head count offset 2 bytes
	call	print_hex_byte

! Print hd1 sector count
	call	print_setup
	mov	bp,#msgSectors1
	call	print_str
	mov	bp,#0x9E		! Sector count offset 14 bytes
	call	print_hex_byte

print_final_separator:
	mov	ax,#0xe0d	! Carriage return
	int	0x10
	mov	al,#0xa		! Line feed
	int	0x10
	
	call	print_setup
	mov	bp,#msgSeparator
	call	print_str
	mov	ax,#0xe0d	! Carriage return
	int	0x10
	mov	al,#0xa		! Line feed
	int	0x10

! Print multiple newlines
	mov	cx,#3		! Number of newlines to print
print_newlines:
	mov	ax,#0xe0d	! Carriage return (CR)
	int	0x10
	mov	al,#0xa		! Line feed (LF)
	int	0x10
	loop	print_newlines

! Move cursor to specified position
	mov	ah,#0x02		! BIOS function: set cursor position
	xor	bh,bh		! Display page 0
	mov	dh,#25		! Row number
	mov	dl,#0		! Column number
	int	0x10

! Jump to protected mode setup code
	jmp	after_print

! Simple print functions
! Set cursor position and attributes
print_setup:
	mov	ah,#0x03	! Read cursor position
	xor	bh,bh
	int	0x10
	mov	cx,#16		! String length (general value, no impact on core logic)
	mov	bx,#0x0007	! Attribute: normal
	ret

! Print string
print_str:
	mov	ax,#0x1301	! Write string, move cursor
	int	0x10
	ret

! Print 16-bit hexadecimal number
print_hex:
	push	cx
	push	dx
	mov	dx,(bp)		! Read value
	mov	cx,#4		! 4 hexadecimal digits
print_hex_loop:
	rol	dx,#4		! Rotate left 4 bits
	mov	ax,#0xe0f	! ah=0xe (print char), al=mask
	and	al,dl		! Get lower 4 bits
	add	al,#0x30	! Convert to ASCII
	cmp	al,#0x3a	! Compare if greater than '9'
	jl	print_hex_out	! Jump if less
	add	al,#0x07	! Add 7 to get A-F if greater
print_hex_out:
	int	0x10		! Call BIOS to display character
	loop	print_hex_loop
	
	mov	ax,#0xe0d	! Carriage return
	int	0x10
	mov	al,#0xa		! Line feed
	int	0x10
	pop	dx
	pop	cx
	ret

! Print 8-bit hexadecimal number
print_hex_byte:
	push	cx
	push	dx
	mov	dx,(bp)		! Read byte
	and	dx,#0x00ff	! Only take lower byte
	mov	cx,#2		! 2 hexadecimal digits
print_hex_byte_loop:
	rol	dx,#4		! Rotate left 4 bits
	mov	ax,#0xe0f	! ah=0xe(print char), al=mask
	and	al,dl		! Get lower 4 bits
	add	al,#0x30	! Convert to ASCII
	cmp	al,#0x3a	! Compare if greater than '9'
	jl	print_hex_byte_out	! Jump if less
	add	al,#0x07	! Add 7 to get A-F if greater
print_hex_byte_out:
	int	0x10		! Call BIOS to display character
	loop	print_hex_byte_loop
	
	mov	ax,#0xe0d	! Carriage return
	int	0x10
	mov	al,#0xa		! Line feed
	int	0x10
	pop	dx
	pop	cx
	ret

after_print:

! now we want to move to protected mode ...

	cli			! no interrupts allowed !

! first we move the system to it's rightful place

	mov	ax,#0x0000
	cld			! 'direction'=0, movs moves forward
do_move:
	mov	es,ax		! destination segment
	add	ax,#0x1000
	cmp	ax,#0x9000
	jz	end_move
	mov	ds,ax		! source segment
	sub	di,di
	sub	si,si
	mov 	cx,#0x8000
	rep
	movsw
	jmp	do_move

! then we load the segment descriptors

end_move:
	mov	ax,#SETUPSEG	! right, forgot this at first. didn't work :-)
	mov	ds,ax
	lidt	idt_48		! load idt with 0,0
	lgdt	gdt_48		! load gdt with whatever appropriate

! that was painless, now we enable A20

	call	empty_8042
	mov	al,#0xD1		! command write
	out	#0x64,al
	call	empty_8042
	mov	al,#0xDF		! A20 on
	out	#0x60,al
	call	empty_8042

! well, that went ok, I hope. Now we have to reprogram the interrupts :-(
! we put them right after the intel-reserved hardware interrupts, at
! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
! messed this up with the original PC, and they haven't been able to
! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
! which is used for the internal hardware interrupts as well. We just
! have to reprogram the 8259's, and it isn't fun.

	mov	al,#0x11		! initialization sequence
	out	#0x20,al		! send it to 8259A-1
	.word	0x00eb,0x00eb		! jmp $+2, jmp $+2
	out	#0xA0,al		! and to 8259A-2
	.word	0x00eb,0x00eb
	mov	al,#0x20		! start of hardware int's (0x20)
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x28		! start of hardware int's 2 (0x28)
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x04		! 8259-1 is master
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x02		! 8259-2 is slave
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x01		! 8086 mode for both
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0xFF		! mask off all interrupts for now
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al

! well, that certainly wasn't fun :-(. Hopefully it works, and we don't
! need no steenking BIOS anyway (except for the initial loading :-).
! The BIOS-routine wants lots of unnecessary data, and it's less
! "interesting" anyway. This is how REAL programmers do it.
!
! Well, now's the time to actually move into protected mode. To make
! things as simple as possible, we do no register set-up or anything,
! we let the gnu-compiled 32-bit programs do that. We just jump to
! absolute address 0x00000, in 32-bit protected mode.
	mov	ax,#0x0001	! protected mode (PE) bit
	lmsw	ax		! This is it!
	jmpi	0,8		! jmp offset 0 of segment 8 (cs)

! This routine checks that the keyboard command queue is empty
! No timeout is used - if this hangs there is something wrong with
! the machine, and we probably couldn't proceed anyway.
empty_8042:
	.word	0x00eb,0x00eb
	in	al,#0x64	! 8042 status port
	test	al,#2		! is input buffer full?
	jnz	empty_8042	! yes - loop
	ret

gdt:
	.word	0,0,0,0		! dummy

	.word	0x07FF		! 8Mb - limit=2047 (2048 * 4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9A00		! code read/exec
	.word	0x00C0		! granularity=4096, 386

	.word	0x07FF		! 8Mb - limit=2047 (2048 * 4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9200		! data read/write
	.word	0x00C0		! granularity=4096, 386

idt_48:
	.word	0			! idt limit=0
	.word	0,0			! idt base=0L

gdt_48:
	.word	0x800		! gdt limit=2048, 256 GDT entries
	.word	512+gdt,0x9	! gdt base = 0X9xxxx
	
msg1:
	.ascii "Now we are in SETUP"
	.byte 13,10,13,10

! Added print messages
msgSeparator:
	.ascii "***************"
msgCursor:
	.ascii "* Cursor Pos:  "
msgMemory:
	.ascii "* Memory(kB):  "
msgDisplayPage:
	.ascii "* Display Page:"
msgVideoMode:
	.ascii "* Video Mode:  "
msgWindowWidth:
	.ascii "* Win Width:   "
msgEGA1:
	.ascii "* EGA/VGA 1:   "
msgEGA2:
	.ascii "* EGA/VGA 2:   "
msgEGA3:
	.ascii "* EGA/VGA 3:   "
msgCyls0:
	.ascii "* HD0 Cyls:    "
msgHeads0:
	.ascii "* HD0 Heads:   "
msgSectors0:
	.ascii "* HD0 Sectors: "
msgCyls1:
	.ascii "* HD1 Cyls:    "
msgHeads1:
	.ascii "* HD1 Heads:   "
msgSectors1:
	.ascii "* HD1 Sectors: "
msgNoDisk1:
	.ascii "* No HardDisk1 "

.text
endtext:
.data
enddata:
.bss
endbss:

