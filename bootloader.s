.FILE	"bootloader.s"

	.TEXT

		.GLOBL	_start
		.TYPE	_start, @function

		.GLOBL	_print16
		.TYPE	_print16, @function

		.GLOBL	_clear16
		.TYPE	_clear16, @function

		.GLOBL	_readDisk16
		.TYPE	_readDisk16, @function

		.GLOBL	_goToPM16
		.TYPE	_goToP16, @function

		.GLOBL	_print32
		.TYPE	_print32, @function

		.GLOBL	_loadKernel32
		.TYPE	_loadKernel32, @function

		.EXTERN	_kernel
		.TYPE	_kernel, @function

			_start:
				.CODE16

					XORW	%AX, %AX
					MOVW	%AX, %ES	# SET EXTRA SEGMENT DATA 0x00.
					MOVW	%AX, %DS	#	SET SEGMENT DATA 0x00.
					MOVW	%AX, %SS	#	SET SEGMENT STACK 0x00.

					PUSHW	$.VIDEOMODE
					CALLW	_clear16

					PUSHW	$.LC10
					CALLW	_print16

					PUSHW	$.LC20
					CALLW	_print16

					PUSHW	$.KERNEL
					PUSHW	$.DISK
					PUSHW	$.SECTORS
					PUSHW	$.CYLINDER
					PUSHW	$.SECTOR
					PUSHW	$.HEAD
					CALLW	_readDisk16

					CMPW	$1, %AX
					JE	.LC07

					PUSHW	$.LC30
					CALLW	_print16

					JMP	.LC08

					.LC07:
						PUSHW	$.LC40
						CALLW	_print16

						PUSHW	$.LC50
						CALLW	_print16

						JMP	.LC01

					.LC08:
						PUSHW	$.LC60
						CALLW	_print16

						CALLW	_goToPM16

						PUSHW	$.LC70
						PUSHW	$0x01
						PUSHW	$480
						CALLW	_print32

						PUSHW	$.LC80
						PUSHW	$0x01
						PUSHW	$640
						CALLW	_print32

						JMPW	$.KERNELCODESEGMENT, $_loadKernel32

					.LC01:
						HLT

						JMP	.LC01

					#IN	--	String
					_print16:
						.CODE16

							PUSHW	%BP
							MOVW	%SP, %BP

							PUSHW	%CX
							PUSHW	%DX
							PUSHW	%BX
							PUSHW	%SI
							PUSHW	%DI

							MOVW	4(%BP), %SI

							MOVB	$0x0E, %AH	#MODE: WRITE CHARACTER ON SCREEN. EMULATE TELETYPE.

							.LC02:

								LODSB	#LOAD CHARACTER AT THE ADDRESS SPECIFIED IN SI AND INCREMENT IT

								CMPB	$0, %AL
								JE	.LC03

								INT	$0x10	#INTERRUPT: VIDEO SERVICE

								JMP	.LC02

						.LC03:

								POPW	%DI
								POPW	%SI
								POPW	%BX
								POPW	%DX
								POPW	%CX

								MOVW	%BP, %SP
								POPW	%BP

								RETW	$2

					#IN	--	Video Mode
					_clear16:
						.CODE16

							PUSHW	%BP
							MOVW	%SP, %BP

							PUSHW	%CX
							PUSHW	%DX
							PUSHW	%BX
							PUSHW	%SI
							PUSHW	%DI

							MOVW	4(%BP), %AX

							MOVB	$0x00, %AH	#MODE: SET VIDEO MODE. CLEAR SCREEN. SET MODE. SET VARIABLE BIOS

							INT	$0x10	#INTERRUPT:	VIDEO SERVICE

							POPW	%DI
							POPW	%SI
							POPW	%BX
							POPW	%DX
							POPW	%CX

							MOVW	%BP, %SP
							POPW	%BP

							RETW	$2

					#IN	--	Bufer
					#IN	--	Disk
					#IN	--	Sectors
					#IN	--	Cylinder
					#IN	--	Sector
					#IN	--	Head
					#OUT	--	Status Task
					_readDisk16:
						.CODE16

							PUSHW	%BP
							MOVW	%SP, %BP

							PUSHW	%CX
							PUSHW	%DX
							PUSHW	%BX
							PUSHW	%SI
							PUSHW	%DI

							MOVW	$0, %BX
							MOVW	%BX, %ES
							MOVW	14(%BP), %BX

							MOVB	$0x02, %AH	#MODE: READING SECTORS
							MOVB	10(%BP), %AL
							MOVB	8(%BP), %CH
							MOVB	6(%BP), %CL
							MOVB	4(%BP), %DH
							MOVB	12(%BP), %DL

							INT	$0x13	#INTERRUPT: DRIVE IO
							JC	.LC05	#CARRY IS 1 IF ERROR

							.LC04:

								MOVW	$0, %AX

								JMP	.LC06

							.LC05:

								MOVW	$1, %AX

							.LC06:

								POPW	%DI
								POPW	%SI
								POPW	%BX
								POPW	%DX
								POPW	%CX

								MOVW	%BP, %SP
								POPW	%BP

								RETW	$12

					_goToPM16:
						.CODE16

							CLI

							LGDTL	.GDTDESCRIPTION

							MOVL	%CR0, %EAX
							ORL	$0x01, %EAX
							MOVL	%EAX, %CR0

							RETW

					_loadKernel32:
						.CODE32

							MOVW	$.KERNELDATASEGMENT, %AX
							MOVW	%AX, %DS	#	SET DATA SEGMENT
							MOVW	%AX, %SS	#	SET STACK SEGMENT
							MOVW	%AX, %ES	#	SET EXTRA SEGMENT

							JMPW	$.KERNELCODESEGMENT, $_kernel

					#IN	--	String
					#IN	--	Color
					#IN	--	Offset
					_print32:
						.CODE16

							PUSHW	%BP
							MOVW	%SP, %BP

							PUSHW	%CX
							PUSHW	%DX
							PUSHW	%BX
							PUSHW	%SI
							PUSHW	%DI

							MOVW	8(%BP), %SI
							MOVW	4(%BP), %CX
							MOVW	6(%BP), %AX

							MOVB	%AL, %AH

							MOVL	$.VIDEOMEMORY, %EBX
							MOVSX	%CX, %ECX
							ADDL	%ECX, %EBX

							.LC09:
								LODSB

								CMP	$0x00, %AL
								JE	.LC010

								MOVW	%AX, (%EBX)
								ADDL	$0x02, %EBX

								JMP	.LC09

							.LC010:

							POPW	%DI
							POPW	%SI
							POPW	%BX
							POPW	%DX
							POPW	%CX

							MOVW	%BP, %SP
							POPW	%BP

							RETW	$6

					.LC10:	.ASCIZ	"REAL MODE!\n\r"
					.LC20:	.ASCIZ	"READING DISK..."
					.LC30:	.ASCIZ	"[OK]!\n\r"
					.LC40:	.ASCIZ	"[FAIL]!\n\r"
					.LC50:	.ASCIZ	"ERROR CODE: "
					.LC60:	.ASCIZ	"GO TO PROTECTED MODE...\n\r"
					.LC70:	.ASCIZ	"PROTECTED MODE!"
					.LC80:	.ASCIZ	"LOADING KERNEL..."

					.GDT:
						.GDTNULL:
						#Null Description
							.WORD	0x0000#	16
							.WORD	0x0000#	32
							.WORD	0x0000#	48
							.WORD	0x0000#	64
						.GDTKERNELCODE:
						#Kernel Code Description
							.WORD	0xFFFF#	16
							.WORD	0x0000#	32
							.BYTE	0x00#	40
							#1 00 1 110 0 -- 9C +
							#1 00 1 101 0 -- 9A
							.BYTE	0x9A#	48
							#1 0 0 0 1 1 1 1 -- 8F +
							#1 1 0 0 1 1 1 1 -- CF
							.BYTE	0xCF#	56
							.BYTE	0x00#	64
						.GDTKERNELDATA:
						#Kernel Data Description
							.WORD	0xFFFF#	16
							.WORD	0x0000#	32
							.BYTE	0x00#	40
							#1 00 1 010 0 -- 96 +
							#1 00 1 001 0 -- 92
							.BYTE	0x92#	48
							#1 0 0 0 1 1 1 1 -- 8F +
							#1 1 0 0 1 1 1 1 -- CF
							.BYTE	0xCF#	56
							.BYTE	0x00#	64
						.GDTUSERCODE:
						#User Code Description
							.WORD	0xFFFF#	16
							.WORD	0x0000#	32
							.BYTE	0x00#	40
							#1 11 1 110 0 -- FC +
							#1 00 1 111 0 -- 9F +
							#1 11 1 101 0 -- FA
							.BYTE	0xFA#	48
							#1 0 0 0 1 1 1 1 -- 8F +
							#0 0 0 0 0 0 0 0 -- 0 +
							#1 1 0 0 1 1 1 1 -- CF
							.BYTE	0xCF#	56
							.BYTE	0x00#	64
						.GDTUSERDATA:
						#User Data Description
							.WORD	0xFFFF#	16
							.WORD	0x0000#	32 
							.BYTE	0x0000#	40
							#1 11 1 011 0 -- F6 +
							#1 00 1 001 0 -- 92 +
							#1 11 1 001 0 -- F2
							.BYTE	0xF2#	48
							#1 0 0 0 1 1 1 1 -- 8F +
							#0 0 0 0 0 0 0 0 -- 0 +
							#1 1 0 0 1 1 1 1 -- CF
							.BYTE 0xCF#	56
							.BYTE	0x00#	64
						.GDTEND:

						.GDTDESCRIPTION:
							.WORD .GDTEND - .GDTNULL - 1#2
							.LONG	.GDTNULL#	6

						.EQU	.VIDEOMODE, 0x03	#TEXT 80X25 16/8 CGA, EGA B800 COMP, RGB, ENHANCED
						.EQU	.KERNEL, 0x1000
						.EQU	.VIDEOMEMORY, 0xB8000

						.EQU	.SECTORS, 0x20	#NUMBERS OF SECTORS: 32
						.EQU	.CYLINDER, 0x00	#CYLINDER: 0
						.EQU	.SECTOR, 0x02	#SECTOR: 2
						.EQU	.HEAD, 0x00	#HEAD: 0
						.EQU	.DISK, 0x80	#DRIVE: 0x80 DISK 1

						.EQU	.KERNELCODESEGMENT, .GDTKERNELCODE - .GDTNULL
						.EQU	.KERNELDATASEGMENT, .GDTKERNELDATA - .GDTNULL

					.	=	_start + 0x1FE

					.BYTE	0x55
					.BYTE	0xAA
