;;@ --------------------------- Defines ----------------------------
     cpucontext .req r6
     z80sppc_pointer=            0                  ;;@  0
     z80hlfa_pointer=            z80sppc_pointer+4     ;;@  4
     z80debc_pointer=            z80hlfa_pointer+4     ;;@  8
     z80iyix_pointer=            z80debc_pointer+4     ;;@  12
     z80hlfa2_pointer=           z80iyix_pointer+4     ;;@  16
     z80debc2_pointer=           z80hlfa2_pointer+4    ;;@  20
     z80cyclesleft_pointer=      z80debc2_pointer+4    ;;@  24
     z80flagsir_pointer=         z80cyclesleft_pointer+4   ;;@  28
     z80irqcallback=          z80flagsir_pointer+4
     z80_write8=              z80irqcallback+4
     z80_write16=             z80_write8+4
     z80_in=                  z80_write16+4
     z80_out=                 z80_in+4
     z80_read8=               z80_out+4
     z80_read16=              z80_read8+4
     z80_rebaseSP=            z80_read16+4
     z80_rebasePC=            z80_rebaseSP+4
     ppMemFetch=			  z80_rebasePC+4
     ppMemFetchData=		  ppMemFetch+4
     ppMemRead=				  ppMemFetchData+4
     ppMemWrite=			  ppMemRead+4
     debugCallback=			  ppMemWrite+4

.align 4
            .ltorg

            .data
            mpointer:	.word 0
            rpointer:	.word 0
            rompointer:	.word 0
            IFF1:	.word 0
            IFF2:	.word 0


            .align 4

.text
;@ ***** EnterCPU *****
.align 4
.global _DaveZ80EnterCPU
.type _DaveZ80EnterCPU,function
.code 32
	;@FlagC=1,
	;@FlagN=2,
	;@FlagP=4,
	;@Flag3=8,
	;@FlagH=16,
	;@Flag5=32,
	;@FlagZ=64,
	;@FlagS=128


	;@** Following ARM registers are reserved To match Z80 registers
	;@** R5 - Bit 31=IFF2, 30=IFF1,29&28=Int Mode, 27-Page Enable, 26-Model, 25-Current Rom, 24-128K Screen, 23-Tape Load, 22,21=Beeper, 20-18=Border, 17=Halt status, 16=Debug flag, 15-8=I, 7-0=R
	;@** R6 - cpu context
	;@** R7 - SP  PC
	;@** R8 - H L F A
	;@** R9 - D E B C
	;@** R10 - IX IY
	;@** R11 - Cycles
	;@** R12 - 16 bit mask 0000FFFF


_DaveZ80EnterCPU:

	stmfd r13!,{r3-r12,lr}
			ldr r4,=mpointer
			str r0,[r4]

			ldr r4,=rpointer
			str r1,[r4]
			mov r6,r1
			mov r0,r1		;@Load address For external register storage

			ldr r7,[r0],#4 ;@Start reloading registers -  SP PC
			ldr r8,[r0],#4 ;@H L F A
			ldr r9,[r0],#4 ;@D E B C
			ldr r10,[r0],#4 ;@IY IX
			ldr r2,[r0],#4 ;@H' L' F' A'
			ldr r3,[r0],#4 ;@D' E' B' C'
			ldr r11,[r0],#4 ;@Cycles
			ldr r5,[r0] ;@user flags			;@ IFF2 IFF1 (14 spare bits) I R
			mov r12,#0xFF00 ;@16 bit mask
			add r12,r12,#0x00FF ;@16 bit mask
			ldr r4,=ExReg
			str r2,[r4,#4]
			str r3,[r4,#8]





CPU_LOOP:
			add r0,r5,#1
			and r0,r0,#127
			bic r5,r5,#127
			orr r5,r5,r0				;@ 4 Lines to increase r register!
			tst r5,#0x20000				;@ Test for HALT flag
			movne r2,#4					;@ Move 4 cycles into R2
			bne	ENDOPCODES				;@ Jump past opcodes
OPCODES:
			and r1,r7,r12				;@Mask the 16 bits that relate to the PC
			bl MEMFETCH

			add r1,r1,#1				;@Increment PC
			and r1,r1,r12				;@Mask the 16 bits that relate to the PC
			bic r7,r7,r12				;@Clear the old PC value
			orr r7,r7,r1				;@Store the new PC value
;@			ldr r3,=rpointer
;@			ldr r2,[r3]   				;@These three lines store the opcode For debugging
;@			str r0,[r2,#36]
			add r15,r15,r0, lsl #2 		;@Multipy opcode by 4 To get value To add To PC


			nop

			b OPCODE_00
			b OPCODE_01
			b OPCODE_02
			b OPCODE_03
			b OPCODE_04
			b OPCODE_05
			b OPCODE_06
			b OPCODE_07
			b OPCODE_08
			b OPCODE_09
			b OPCODE_0A
			b OPCODE_0B
			b OPCODE_0C
			b OPCODE_0D
			b OPCODE_0E
			b OPCODE_0F
			b OPCODE_10
			b OPCODE_11
			b OPCODE_12
			b OPCODE_13
			b OPCODE_14
			b OPCODE_15
			b OPCODE_16
			b OPCODE_17
			b OPCODE_18
			b OPCODE_19
			b OPCODE_1A
			b OPCODE_1B
			b OPCODE_1C
			b OPCODE_1D
			b OPCODE_1E
			b OPCODE_1F
			b OPCODE_20
			b OPCODE_21
			b OPCODE_22
			b OPCODE_23
			b OPCODE_24
			b OPCODE_25
			b OPCODE_26
			b OPCODE_27
			b OPCODE_28
			b OPCODE_29
			b OPCODE_2A
			b OPCODE_2B
			b OPCODE_2C
			b OPCODE_2D
			b OPCODE_2E
			b OPCODE_2F
			b OPCODE_30
			b OPCODE_31
			b OPCODE_32
			b OPCODE_33
			b OPCODE_34
			b OPCODE_35
			b OPCODE_36
			b OPCODE_37
			b OPCODE_38
			b OPCODE_39
			b OPCODE_3A
			b OPCODE_3B
			b OPCODE_3C
			b OPCODE_3D
			b OPCODE_3E
			b OPCODE_3F
			b OPCODE_40
			b OPCODE_41
			b OPCODE_42
			b OPCODE_43
			b OPCODE_44
			b OPCODE_45
			b OPCODE_46
			b OPCODE_47
			b OPCODE_48
			b OPCODE_49
			b OPCODE_4A
			b OPCODE_4B
			b OPCODE_4C
			b OPCODE_4D
			b OPCODE_4E
			b OPCODE_4F
			b OPCODE_50
			b OPCODE_51
			b OPCODE_52
			b OPCODE_53
			b OPCODE_54
			b OPCODE_55
			b OPCODE_56
			b OPCODE_57
			b OPCODE_58
			b OPCODE_59
			b OPCODE_5A
			b OPCODE_5B
			b OPCODE_5C
			b OPCODE_5D
			b OPCODE_5E
			b OPCODE_5F
			b OPCODE_60
			b OPCODE_61
			b OPCODE_62
			b OPCODE_63
			b OPCODE_64
			b OPCODE_65
			b OPCODE_66
			b OPCODE_67
			b OPCODE_68
			b OPCODE_69
			b OPCODE_6A
			b OPCODE_6B
			b OPCODE_6C
			b OPCODE_6D
			b OPCODE_6E
			b OPCODE_6F
			b OPCODE_70
			b OPCODE_71
			b OPCODE_72
			b OPCODE_73
			b OPCODE_74
			b OPCODE_75
			b OPCODE_76
			b OPCODE_77
			b OPCODE_78
			b OPCODE_79
			b OPCODE_7A
			b OPCODE_7B
			b OPCODE_7C
			b OPCODE_7D
			b OPCODE_7E
			b OPCODE_7F
			b OPCODE_80
			b OPCODE_81
			b OPCODE_82
			b OPCODE_83
			b OPCODE_84
			b OPCODE_85
			b OPCODE_86
			b OPCODE_87
			b OPCODE_88
			b OPCODE_89
			b OPCODE_8A
			b OPCODE_8B
			b OPCODE_8C
			b OPCODE_8D
			b OPCODE_8E
			b OPCODE_8F
			b OPCODE_90
			b OPCODE_91
			b OPCODE_92
			b OPCODE_93
			b OPCODE_94
			b OPCODE_95
			b OPCODE_96
			b OPCODE_97
			b OPCODE_98
			b OPCODE_99
			b OPCODE_9A
			b OPCODE_9B
			b OPCODE_9C
			b OPCODE_9D
			b OPCODE_9E
			b OPCODE_9F
			b OPCODE_A0
			b OPCODE_A1
			b OPCODE_A2
			b OPCODE_A3
			b OPCODE_A4
			b OPCODE_A5
			b OPCODE_A6
			b OPCODE_A7
			b OPCODE_A8
			b OPCODE_A9
			b OPCODE_AA
			b OPCODE_AB
			b OPCODE_AC
			b OPCODE_AD
			b OPCODE_AE
			b OPCODE_AF
			b OPCODE_B0
			b OPCODE_B1
			b OPCODE_B2
			b OPCODE_B3
			b OPCODE_B4
			b OPCODE_B5
			b OPCODE_B6
			b OPCODE_B7
			b OPCODE_B8
			b OPCODE_B9
			b OPCODE_BA
			b OPCODE_BB
			b OPCODE_BC
			b OPCODE_BD
			b OPCODE_BE
			b OPCODE_BF
			b OPCODE_C0
			b OPCODE_C1
			b OPCODE_C2
			b OPCODE_C3
			b OPCODE_C4
			b OPCODE_C5
			b OPCODE_C6
			b OPCODE_C7
			b OPCODE_C8
			b OPCODE_C9
			b OPCODE_CA
			b OPCODE_CB
			b OPCODE_CC
			b OPCODE_CD
			b OPCODE_CE
			b OPCODE_CF
			b OPCODE_D0
			b OPCODE_D1
			b OPCODE_D2
			b OPCODE_D3
			b OPCODE_D4
			b OPCODE_D5
			b OPCODE_D6
			b OPCODE_D7
			b OPCODE_D8
			b OPCODE_D9
			b OPCODE_DA
			b OPCODE_DB
			b OPCODE_DC
			b OPCODE_DD
			b OPCODE_DE
			b OPCODE_DF
			b OPCODE_E0
			b OPCODE_E1
			b OPCODE_E2
			b OPCODE_E3
			b OPCODE_E4
			b OPCODE_E5
			b OPCODE_E6
			b OPCODE_E7
			b OPCODE_E8
			b OPCODE_E9
			b OPCODE_EA
			b OPCODE_EB
			b OPCODE_EC
			b OPCODE_ED
			b OPCODE_EE
			b OPCODE_EF
			b OPCODE_F0
			b OPCODE_F1
			b OPCODE_F2
			b OPCODE_F3
			b OPCODE_F4
			b OPCODE_F5
			b OPCODE_F6
			b OPCODE_F7
			b OPCODE_F8
			b OPCODE_F9
			b OPCODE_FA
			b OPCODE_FB
			b OPCODE_FC
			b OPCODE_FD
			b OPCODE_FE
			b OPCODE_FF

OPCODE_00:	;@ NOP
	;@ We do nothing!
	mov r2,#4
b ENDOPCODES

OPCODE_01:	;@ LD BC,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r9,r9,r12			;@ Clear target byte To 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_02:	;@ LD (BC),A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	and r1,r9,r12			;@ Mask register value to a short (16 bit) value
	bl MEMSTORE 			;@ Store value memory
	mov r2,#7
b ENDOPCODES

OPCODE_03:	;@ INC BC
	mov r0,r9			;@ Get source value
	add r0,r0,#1			;@ Increase by 1
	and r0,r0,r12			;@ Mask to 16 bits
	bic r9,r9,r12			;@ Clear target byte To 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_04:	;@ INC B
	mov r0,r9,lsr #8		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibble
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_05:	;@ DEC B
	mov r0,r9,lsr #8		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_06:	;@ LD B,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_07:	;@ RLCA
	and r0,r8,#0xFF			;@ Move accumulator into R0
	bic r8,r8,#0xFF			;@ Clear old accumulator value
	bic r8,r8,#0x3B00		;@ Clear 3,5,H,N,C flags
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set bit 0 of accumulator if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r8,r8,r0			;@ Store new value
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#4
b ENDOPCODES

OPCODE_08:	;@ EX AF,AF
	ldr r2,=ExReg			;@ Get base of EXX register storage
	ldr r0,[r2,#4]			;@ Load HLFA at offset 4
	mov r1,r8			;@ Move FA to low short
	strb r1,[r2,#4]			;@ Store low byte
	mov r1,r1,lsr #8		;@ Move FA to low short
	strb r1,[r2,#5]			;@ Store low byte
	bic r8,r8,r12			;@ Mask of old HL value
	and r0,r0,r12			;@ Clear HL segment
	orr r8,r8,r0			;@ Clear flags
	mov r2,#4
b ENDOPCODES


OPCODE_D9:	;@ EXX
	ldr r2,=ExReg			;@ Get base of EXX register storage
	ldr r0,[r2,#4]			;@ Load HLFA at offset 4

	ldr r1,[r2,#8]			;@ Load DEBC at offset 8
	str r9,[r2,#8]			;@ Store current DEBC back to offset 8 and decrease r2 to offset 4
	mov r9,r1			;@ Move loaded DEBC to R9
	mov r1,r8,lsr #16		;@ Move HL to low short
	strb r1,[r2,#6]			;@ Store low byte
	mov r1,r1,lsr #8		;@ Shift HL 8 bits to right
	strb r1,[r2,#7]			;@ Store high byte
	and r8,r8,r12			;@ Mask off old HL value
	bic r0,r0,r12			;@ Clear flags and accumulator from loaded value
	orr r8,r8,r0			;@ Set new HL value
	mov r2,#4
b ENDOPCODES

.ltorg
.data
ExReg:
.word 0,0,0

.text

OPCODE_09:	;@ ADD HL,BC
	and r0,r9,r12			;@ Mask to 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	and r2,r2,r12			;@ Mask off to 16 bits
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
;@	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

OPCODE_0A:	;@ LD A,(BC)
	and r1,r9,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_0B:	;@ DEC BC
	mov r0,r9			;@ Get source value
	sub r0,r0,#1			;@ Decrease by 1
	and r0,r0,r12			;@ Mask to 16 bits
	bic r9,r9,r12			;@ Clear target byte To 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_0C:	;@ INC C
	mov r0,r9			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibble
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_0D:	;@ DEC C
	mov r0,r9			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_0E:	;@ LD C,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_0F:	;@ RRCA
	and r0,r8,#0xFF			;@ Move accumulator into R0
	bic r8,r8,#0x3B00		;@ Clear 3,5,H,N,C flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0xFF			;@ Mask back to byte
	bic r8,r8,#0xFF			;@ Clear old accumulator value
	orr r8,r8,r0			;@ Store new value
	orrcs r8,r8,#0x180		;@ Set bit 7 and Z80 carry flag if shift cause ARM carry
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#4
b ENDOPCODES

;@OPCODE_10:	;@ DJNZ (PC+e)
;@	and r1,r7,r12			;@ Move PC into R2 and mask to 16 bits
;@	bl MEMFETCH
;@	add r1,r1,#1			;@ Increase PC to compensate for byte just loaded
;@	mov r3,#0			;@ This is for cycle count
;@	mov r2,r9,lsr #8		;@ Move B register into R0
;@	sub r2,r2,#1			;@ Decrease by 1
;@	ands r2,r2,#0xFF		;@ Mask back to byte
;@	bic r9,r9,#0xFF00		;@ Clear old B reg value
;@	orr r9,r9,r2,lsl #8		;@ Store new b value
;@	addne r3,r3,#5			;@ Add 5 tstates
;@	addne r1,r1,r0			;@ Add to PC
;@	tstne r0,#128			;@ Check sign for 2's displacemen
;@	subne r1,r1,#256 		;@ Make amount negative if above 127
;@	and r1,r1,r12			;@ Mask to 16 bits
;@	bic r7,r7,r12			;@ Clear old PC
;@	orr r7,r7,r1			;@ Add new PC
;@	add r2,r3,#8			;@ Add standard tstates
;@b ENDOPCODES


OPCODE_10:	;@ DJNZ (PC+e)
	mov r2,r9,lsr #8		;@ Move B register into R2
	sub r2,r2,#1			;@ Decrease by 1
	ands r2,r2,#0xFF		;@ Mask back to byte
	bic r9,r9,#0xFF00		;@ Clear old B reg value
	orr r9,r9,r2,lsl #8		;@ Store new b value
	addeq r0,r1,#1			;@ Adjust PC
	andeq r0,r0,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC
	orreq r7,r7,r0			;@ Add new PC
	moveq r2,#8			;@ Put tstates in R2
	beq ENDOPCODES
	bl MEMFETCH			;@ Get displacement if jump needed (R1 still contains PC correct PC).
	add r1,r1,r0			;@ Add to PC
	add r1,r1,#1			;@ Adjust for extra byte read
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bits
	orr r7,r7,r1			;@ Add new PC
	mov r2,#13			;@ Put tstates in R2
b ENDOPCODES


OPCODE_11:	;@ LD DE,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r9,r9,r12			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_12:	;@ LD (DE),A

	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	mov r1,r9,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_13:	;@ INC DE
	mov r0,r9,lsr #16		;@ Get source value
	add r0,r0,#1			;@ Increase by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r9,r9,r12			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_14:	;@ INC D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_15:	;@ DEC D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_16:	;@ LD D,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_17:	;@ RLA
	and r0,r8,#0xFF			;@ Move accumulator into R0
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0x3B00		;@ Clear 3,5,H,N,C flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	bic r8,r8,#0xFF			;@ Clear old accumulator value
	orr r8,r8,r0			;@ Store new value
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#4
b ENDOPCODES

OPCODE_18:	;@ JR (PC+e)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increase PC to compensate for byte just loaded
	add r0,r2,r1			;@ Add to PC
	tst r1,#128			;@ Check sign for 2's displacemen
	subne r0,r0,#256 		;@ Make amount negative if above 127
	and r0,r0,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
	mov r2,#12
b ENDOPCODES

OPCODE_19:	;@ ADD HL,DE
	mov r0,r9,lsr #16		;@ Get source valu
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	and r2,r2,r12			;@ Mask off to 16 bits
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
;@	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

OPCODE_1A:	;@ LD A,(DE)
	mov r1,r9,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_1B:	;@ DEC DE
	mov r0,r9,lsr #16		;@ Get source value
	sub r0,r0,#1			;@ Decrease by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r9,r9,r12			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_1C:	;@ INC E
	mov r0,r9,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_1D:	;@ DEC E
	mov r0,r9,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_1E:	;@ LD E,n
	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_1F:	;@ RRA
	and r0,r8,#0xFF			;@ Move accumulator into R0
	mov r1,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0x3B00		;@ Clear 3,5,H,N,C flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0xFF			;@ Mask back to byte
	bic r8,r8,#0xFF			;@ Clear old accumulator value
	orr r8,r8,r0			;@ Store new value
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r1,#1 			;@ Test if old carry was set
	orrne r8,r8,#0x80		;@ Set bit 7 of accumulator if so
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#4
b ENDOPCODES

OPCODE_20:	;@ JR NZ,(PC+e)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x4000			;@ Test Z flag
	bne	jrnz
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increase PC to compensate for byte just loaded
	add r0,r2,r1			;@ Add to PC
	tst r1,#128			;@ Check sign for 2's displacemen
	subne r0,r0,#256 		;@ Make amount negative if above 127
	and r0,r0,r12			;@ Mask to 16 bits
	mov r2,#12			;@ Tstates
	b jrnzf
jrnz:
	add r2,r2,#1			;@ Increase the PC by 1
	and r0,r2,r12			;@ Mask to 16 bits
	mov r2,#7			;@ Tstates
jrnzf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
b ENDOPCODES

OPCODE_21:	;@ LD HL,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_22:	;@ LD (nn),HL
	mov r0,r8,lsr #16		;@ Get source value
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#16
b ENDOPCODES

OPCODE_23:	;@ INC HL
	mov r0,r8,lsr #16		;@ Get source value
	add r0,r0,#1			;@ Increase by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_24:	;@ INC H
	mov r0,r8,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_25:	;@ DEC H
	mov r0,r8,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_26:	;@ LD H,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_27:	;@ DAA
	mov r1,r8,lsl #23		;@ Get accumulator and carry flag
	mov r1,r1,lsr #23
	tst r8,#0x1000			;@ Test H flag
	orrne r1,r1,#0x200		;@ Set bit 9 if H flag was set
	adrl r2,DAA			;@ Get start of DAA table
	ldrb r0,[r2,r1]			;@ Get DAA offset value
	and r1,r1,#0xFF			;@ Mask off bits 8 and 9
	cmp r1,#0x99			;@ Do we need to set carry flag
	orrhi r8,r8,#0x100		;@ If so, set it
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x200			;@ Are we adding or subtracting?
	subne r2,r1,r2
	addeq r2,r1,r2
	bic r8,r8,#0xFC00		;@ Clear all flags except C and N
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator  to a single byte
	tst r8,#0x200			;@ Are we adding or subtracting?
	subne r2,r2,r0			;@ Perform subtraction
	addeq r2,r2,r0			;@ Perform addition
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r0,Parity			;@ Get start of parity table
	ldrb r1,[r0,r2]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF			;@ Clear old accumulator
	orr r8,r8,r2			;@ Store new accumulator
	mov r2,#4
b ENDOPCODES

OPCODE_28:	;@ JR Z,(PC+e)
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	tst r8,#0x4000			;@ Test Z flag
	beq	jrz
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increase PC to compensate for byte just loaded
	add r0,r2,r1			;@ Add to PC
	tst r1,#128			;@ Check sign for 2's displacement
	subne r0,r0,#256 		;@ Make amount negative if above 127
	and r0,r0,r12			;@ Mask to 16 bits
	mov r2,#12			;@ Tstates
	b jrzf
jrz:
	add r2,r2,#1			;@ Increase the PC by 1
	and r0,r2,r12			;@ Mask to 16 bits
	mov r2,#7			;@ Tstates
jrzf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
b ENDOPCODES

OPCODE_29:	;@ ADD HL,HL
	mov r0,r8,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r2,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
;@	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

OPCODE_2A:	;@ LD HL,(nn)
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT2		;@ Get address in R1
	add r2,r2,#2			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#16
b ENDOPCODES

OPCODE_2B:	;@ DEC HL
	mov r0,r8,lsr #16		;@ Get source value
	sub r0,r0,#1			;@ Decrease by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_2C:	;@ INC L
	mov r0,r8,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_2D:	;@ DEC L
	mov r0,r8,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_2E:	;@ LD L,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_2F:	;@ CPL
	eor r0,r8,#0xFF			;@ Perform XOR on accumulator
	and r0,r0,#0xFF			;@ Mask to a byte
	bic r8,r8,#0x3A00		;@ Clear 5,H,3 and N flags
	bic r8,r8,#0x00FF		;@ Clear accumulator
	orr r8,r8,r0			;@ Store accumulator
	tst r8,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r8,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	orr r8,r8,#0x1000		;@ Set H flag
	mov r2,#4
b ENDOPCODES

OPCODE_30:	;@ JR NC,(PC+e)
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	tst r8,#0x100			;@ Test C flag
	bne	jrnc
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increase PC to compensate for byte just loaded
	add r0,r2,r1			;@ Add to PC
	tst r1,#128			;@ Check sign for 2's displacemen
	subne r0,r0,#256 		;@ Make amount negative if above 127
	and r0,r0,r12			;@ Mask to 16 bits
	mov r2,#12			;@ Tstates
	b jrncf
jrnc:
	add r2,r2,#1			;@ Increase the PC by 1
	and r0,r2,r12			;@ Mask to 16 bits
	mov r2,#7			;@ Tstates
jrncf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
b ENDOPCODES

OPCODE_31:	;@ LD SP,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_32:	;@ LD (n),A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#13
b ENDOPCODES

OPCODE_33:	;@ INC SP
	mov r0,r7,lsr #16		;@ Get source value
	add r0,r0,#1			;@ Increase by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_34:	;@ INC (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibble
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2 			;@ Store value in memory
;@	strb r0,[r3]			;@ R3 still contains correct address
	mov r2,#11
b ENDOPCODES

OPCODE_35:	;@ DEC (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bl STOREMEM2 			;@ Store value in memory
	;@strb r0,[r3]			;@ R£ still contains correct address
	mov r2,#11
b ENDOPCODES

OPCODE_36:	;@ LD (HL),n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#10
b ENDOPCODES

OPCODE_37:	;@ SCF
	bic r8,r8,#0x3A00		;@ Clear 5,H,3 and N flags
	tst r8,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r8,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x100		;@ Set C flag
	mov r2,#4
b ENDOPCODES

OPCODE_38:	;@ JR C,(PC+e)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x100			;@ Test C flag
	beq	jrc
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increase PC to compensate for byte just loaded
	add r0,r2,r1			;@ Add to PC
	tst r1,#128			;@ Check sign for 2's displacement
	subne r0,r0,#256 		;@ Make amount negative if above 127
	and r0,r0,r12			;@ Mask to 16 bits
	mov r2,#12			;@ Tstates
	b jrcf
jrc:
	add r2,r2,#1			;@ Increase the PC by 1
	and r0,r2,r12			;@ Mask to 16 bits
	mov r2,#7			;@ Tstates
jrcf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
b ENDOPCODES

OPCODE_39:	;@ ADD HL,SP
	mov r0,r7,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	and r2,r2,r12			;@ Mask off to 16 bits
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
;@	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

OPCODE_3A:	;@ LD A,(n)
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT2		;@ Get address
	add r2,r2,#2			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	bl MEMREAD	 		;@ Load value from memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#13
b ENDOPCODES

OPCODE_3B:	;@ DEC SP
	mov r0,r7,lsr #16		;@ Get source value
	sub r0,r0,#1			;@ Decrease by 1
;@	and r0,r0,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_3C:	;@ INC A
	mov r0,r8			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_3D:	;@ DEC A
	mov r0,r8			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_3E:	;@ LD A,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_3F:	;@ CCF
	bic r8,r8,#0x3A00		;@ Clear 5,H,3 and N flags
	tst r8,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r8,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	tst r8,#0x100			;@ Test C flag
	orrne r8,r8,#0x1000		;@ Set H flag if C was Set
	eor r8,r8,#0x100		;@ Invert C flag
	mov r2,#4
b ENDOPCODES

OPCODE_40:	;@ LD B,B
	mov r2,#4
b ENDOPCODES

OPCODE_41:	;@ LD B,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_42:	;@ LD B,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_43:	;@ LD B,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_44:	;@ LD B,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_45:	;@ LD B,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_46:	;@ LD B,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_47:	;@ LD B,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_48:	;@ LD C,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_49:	;@ LD C,C
	mov r2,#4
b ENDOPCODES

OPCODE_4A:	;@ LD C,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_4B:	;@ LD C,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_4C:	;@ LD C,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_4D:	;@ LD C,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_4E:	;@ LD C,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_4F:	;@ LD C,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_50:	;@ LD D,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_51:	;@ LD D,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_52:	;@ LD D,D
	mov r2,#4
b ENDOPCODES

OPCODE_53:	;@ LD D,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_54:	;@ LD D,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_55:	;@ LD D,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_56:	;@ LD D,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_57:	;@ LD D,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_58:	;@ LD E,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_59:	;@ LD E,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_5A:	;@ LD E,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_5B:	;@ LD E,E
	mov r2,#4
b ENDOPCODES

OPCODE_5C:	;@ LD E,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_5D:	;@ LD E,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_5E:	;@ LD E,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_5F:	;@ LD E,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_60:	;@ LD H,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_61:	;@ LD H,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_62:	;@ LD H,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_63:	;@ LD H,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_64:	;@ LD H,H
	mov r2,#4
b ENDOPCODES

OPCODE_65:	;@ LD H,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_66:	;@ LD H,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_67:	;@ LD H,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_68:	;@ LD L,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_69:	;@ LD L,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_6A:	;@ LD L,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_6B:	;@ LD L,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_6C:	;@ LD L,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_6D:	;@ LD L,L
	mov r2,#4
b ENDOPCODES

OPCODE_6E:	;@ LD L,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_6F:	;@ LD L,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_70:	;@ LD (HL),B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_71:	;@ LD (HL),C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_72:	;@ LD (HL),D
	mov r0,r9,lsr #24		;@ Get source value
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_73:	;@ LD (HL),E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_74:	;@ LD (HL),H
	mov r0,r8,lsr #24		;@ Get source value
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_75:	;@ LD (HL),L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_76:	;@ HALT
	orr r5,r5,#0x20000		;@ Set Halt flag
	mov r2,#4
b ENDOPCODES

OPCODE_77:	;@ LD (HL),A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#7
b ENDOPCODES

OPCODE_78:	;@ LD A,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_79:	;@ LD A,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_7A:	;@ LD A,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_7B:	;@ LD A,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_7C:	;@ LD A,H
	mov r0,r8,lsr #24		;@ Get source value
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_7D:	;@ LD A,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_7E:	;@ LD A,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_7F:	;@ LD A,A
	mov r2,#4
b ENDOPCODES

OPCODE_80:	;@ ADD A,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_81:	;@ ADD A,C
	and r0,r9,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_82:	;@ ADD A,D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_83:	;@ ADD A,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_84:	;@ ADD A,H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_85:	;@ ADD A,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_86:	;@ ADD A,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_87:	;@ ADD A,A
	and r0,r8,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	add r2,r1,r1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register

	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_88:	;@ ADC A,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_89:	;@ ADC A,C
	and r0,r9,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_8A:	;@ ADC A,D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_8B:	;@ ADC A,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_8C:	;@ ADC A,H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_8D:	;@ ADC A,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_8E:	;@ ADC A,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_8F:	;@ ADC A,A
	and r0,r8,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	add r2,r1,r1
	tst r8,#0x100			;@ Test carry flag
	addne r2,r2,#1			;@ If set add 1
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_90:	;@ SUB A,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_91:	;@ SUB A,C
	and r0,r9,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_92:	;@ SUB A,D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_93:	;@ SUB A,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_94:	;@ SUB A,H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_95:	;@ SUB A,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_96:	;@ SUB A,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_97:	;@ SUB A,A
	and r0,r8,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r1,r1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	subs r2,r0,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_98:	;@ SBC A,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_99:	;@ SBC A,C
	and r0,r9,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_9A:	;@ SBC A,D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_9B:	;@ SBC A,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_9C:	;@ SBC A,H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_9D:	;@ SBC A,L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_9E:	;@ SBC A,(HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_9F:	;@ SBC A,A
	and r0,r8,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r1,r1
	tst r8,#0x100			;@ Test carry flag
	subne r2,r2,#1			;@ If set subtract 1
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r2,r0,r0			;@ Perform substraction
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_A0:	;@ AND B
	mov r0,r9,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A1:	;@ AND C
	mov r0,r9			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A2:	;@ AND D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A3:	;@ AND E
	mov r0,r9,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A4:	;@ AND H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A5:	;@ AND L
	mov r0,r8,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A6:	;@ AND (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_A7:	;@ AND A
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r8,#255			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	mov r2,#4
b ENDOPCODES

OPCODE_A8:	;@ XOR B
	mov r0,r9,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_A9:	;@ XOR C
	mov r0,r9			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_AA:	;@ XOR D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_AB:	;@ XOR E
	mov r0,r9,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_AC:	;@ XOR H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_AD:	;@ XOR L
	mov r0,r8,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_AE:	;@ XOR (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_AF:	;@ XOR A
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r8,r8,#0x4000		;@ Set Zero flag
	orr r8,r8,#0x400		;@ Set parity flag if
	mov r2,#4
b ENDOPCODES

OPCODE_B0:	;@ OR B
	mov r0,r9,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B1:	;@ OR C
	mov r0,r9			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B2:	;@ OR D
	mov r0,r9,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B3:	;@ OR E
	mov r0,r9,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B4:	;@ OR H
	mov r0,r8,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B5:	;@ OR L
	mov r0,r8,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_B6:	;@ OR (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_B7:	;@ OR A
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r8,r8			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_B8:	;@ CP B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_B9:	;@ CP C
	and r0,r9,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_BA:	;@ CP D
	mov r0,r9,lsr #24		;@ Get source value
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_BB:	;@ CP E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128				;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_BC:	;@ CP H
	mov r0,r8,lsr #24		;@ Get source value
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_BD:	;@ CP L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#4
b ENDOPCODES

OPCODE_BE:	;@ CP (HL)
	mov r1,r8,lsr #16		;@ Get value of register
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8				;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	eor r0,r0,r8			;@ Perform XOR between original value and accumulator
	eor r2,r2,r8			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_BF:	;@ CP A

	bic r8,r8,#0xFF00		;@ Clear all flags

	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r1			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	;@ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orr r8,r8,#0x4200		;@ Set Z and N flags
	and r1,r7,r12			;@ Get PC
	mov r0,#0x500
	add r0,r0,#0x6B
	cmp r1,r0
	ldreq r0,=tapetype
	ldreq r3,[r0]
	;@ldreq r3,[r0,#104]		;@1=tap 2 =tzx
	cmpeq r3,#1
	orreq r5,r5,#0x800000		;@ Set Tape loader flag
	moveq r11,#4			;@ Interrupt so tape loading can start
	mov r2,#4
b ENDOPCODES

.ltorg
.data

tapetype:
.word 0
.text

OPCODE_C0:	;@ RET NZ
	mov r2,#5			;@ Tstates
	tst r8,#0x4000			;@ Test NZ flag
	bne ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_C1:	;@ POP BC
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT
	add r1,r1,#2			;@ Increase SP
	and r7,r7,r12			;@ lLear old SP value
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	bic r9,r9,r12			;@ Clear target byte To 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_C2:	;@ JP NZ,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x4000			;@ Test Z flag
	movne r1,r7			;@ Get old PC if cond not met
	addne r1,r1,#2			;@ Increase the PC by 2
	andne r1,r1,r12			;@ Mask to 16 bits
	bleq MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_C3:	;@ JP (nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_C4:	;@ CALL NZ,(nn)
	tst r8,#0x4000			;@ Test Z flag
	bne callnz
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@ Get address from current PC into r1
	mov r4,r1			;@ Save address in R4
	add r0,r2,#2			;@ Increase Pc by 2
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callnzf
callnz:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callnzf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_C5:	;@ PUSH BC

	and r0,r9,r12			;@ Mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#11
b ENDOPCODES

OPCODE_C6:	;@ ADD A,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_C7:	;@ RST 0H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x0			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_C8:	;@ RET Z
	mov r2,#5			;@ Tstates
	tst r8,#0x4000			;@ Test NZ flag
	beq ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	and r7,r0,r12			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_C9:	;@ RET
	mov r2,r7,lsr #16		;@Put SP in R2
	bl MEMREADSHORT2
	mov r7,r1			;@Create 16 bit address in PC Register
	add r2,r2,#2			;@Increase SP
	add r7,r7,r2,lsl #16		;@Put SP in Reg 7
	mov r2,#10
b ENDOPCODES

OPCODE_CA:	;@ JP Z,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x4000			;@ Test Z flag
	moveq r1,r7			;@ Get old PC if cond not met
	addeq r1,r1,#2			;@ Increase the PC by 2
	andeq r1,r1,r12			;@ Mask to 16 bits
	blne MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_CB:	;@ CB
	b CBCODES
b ENDOPCODES

OPCODE_CC:	;@ CALL Z,(nn)
	tst r8,#0x4000			;@Test Z flag
	beq callz
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@Get address from current PC into r1
	mov r4,r1			;@Save address in R4
	add r0,r2,#2			;@Increase Pc by 2
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16		;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callzf
callz:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callzf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_CD:	;@ CALL (nn)
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@Get address from current PC into r1
	mov r4,r1			;@Save address in R4
	add r0,r2,#2			;@Increase Pc by 2
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16		;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
	mov r2,#17
b ENDOPCODES

OPCODE_CE:	;@ ADC A,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_CF:	;@ RST 8H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x8			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_D0:	;@ RET NC
	mov r2,#5			;@ Tstates
	tst r8,#0x100			;@ Test NC flag
	bne ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_D1:	;@ POP DE
	mov r1,r7,lsr #16		;@Put SP in R2
	bl MEMREADSHORT
	add r1,r1,#2			;@ Increase SP
	and r7,r7,r12			;@ CLear old SP value
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	and r9,r9,r12			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_D2:	;@ JP NC,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x100			;@ Test C flag
	movne r1,r7			;@ Get old PC if cond not met
	addne r1,r1,#2			;@ Increase the PC by 2
	andne r1,r1,r12			;@ Mask to 16 bits
	bleq MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_D3:	;@ OUT (n),A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2			;@ Load byte from address
	add r2,r2,#1			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	and r0,r8,#0xFF			;@ Get port number
	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
    ldmia sp!,{r3,r12,lr}

	mov r2,#11
b ENDOPCODES

OPCODE_D4:	;@ CALL NC,(nn)
	tst r8,#0x100			;@Test C flag
	bne callnc
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@Get address from current PC into r1
	mov r4,r1			;@Save address in R4
	add r0,r2,#2			;@Increase Pc by 2
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16		;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callncf
callnc:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callncf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_D5:	;@ PUSH DE
	mov r0,r9,lsr #16		;@ Get source value
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#11
b ENDOPCODES

OPCODE_D6:	;@ SUB A,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_D7:	;@ RST 10H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x10			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_D8:	;@ RET C
	mov r2,#5			;@ Tstates
	tst r8,#0x100			;@ Test NC flag
	beq ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_DA:	;@ JP C,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x100			;@ Test C flag
	moveq r1,r7			;@ Get old PC if cond not met
	addeq r1,r1,#2			;@ Increase the PC by 2
	andeq r1,r1,r12			;@ Mask to 16 bits
	blne MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_DB:	;@ IN A,(n)
	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#0xFF			;@ Get port number
	orr r0,r0,r1,lsl #8
	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#11
b ENDOPCODES

OPCODE_DC:	;@ CALL C,(nn)
	tst r8,#0x100			;@Test C flag
	beq callc
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@Get address from current PC into r1
	mov r4,r1			;@Save address in R4
	add r0,r2,#2			;@Increase Pc by 2
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16		;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callcf
callc:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callcf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_DD:	;@ DD
	b DDCODES
b ENDOPCODES

OPCODE_DE:	;@ SBC A,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_DF:	;@ RST 18H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x18			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_E0:	;@ RET PO
	mov r2,#5			;@ Tstates
	tst r8,#0x400			;@ Test PO flag
	bne ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_E1:	;@ POP HL
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT
	add r1,r1,#2			;@ Increase SP
	and r7,r7,r12			;@ Clear old SP value
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_E2:	;@ JP PO,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x400			;@ Test P flag
	movne r1,r7			;@ Get old PC if cond not met
	addne r1,r1,#2			;@ Increase the PC by 2
	andne r1,r1,r12			;@ Mask to 16 bits
	bleq MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_E3:	;@ EX (SP),HL
	mov r2,r7,lsr #16		;@ Get location of SP
	bl MEMREADSHORT2		;@ Get value in SP location into R1
	mov r0,r8,lsr #16		;@ Get source value
	and r8,r8,r12			;@ Clear source byte to 0
	orr r8,r8,r1,lsl #16		;@ Place value on target register
	mov r1,r7,lsr #16		;@ Get value of SP
	bl MEMSTORESHORT		;@ Store to memory
	mov r2,#23
b ENDOPCODES

OPCODE_E4:	;@ CALL PO,(nn)
	tst r8,#0x400			;@Test P flag
	bne callpo
	and r2,r7,r12			;@Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@Get address from current PC into r1
	mov r4,r1			;@Save address in R4
	add r0,r2,#2			;@Increase Pc by 2
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16		;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callpof
callpo:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callpof:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_E5:	;@ PUSH HL
	mov r0,r8,lsr #16		;@ Get source value
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#11
b ENDOPCODES

OPCODE_E6:	;@ AND n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_E7:	;@ RST 20H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x20			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_E8:	;@ RET PE
	mov r2,#5			;@ Tstates
	tst r8,#0x400			;@ Test PE flag
	beq ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_E9:	;@ JP (HL)
	mov r0,r8,lsr #16		;@ Move HL into R0
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
	mov r2,#4
b ENDOPCODES

OPCODE_EA:	;@ JP PE,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x400			;@ Test P flag
	moveq r1,r7			;@ Get old PC if cond not met
	addeq r1,r1,#2			;@ Increase the PC by 2
	andeq r1,r1,r12			;@ Mask to 16 bits
	blne MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_EB:	;@ EX DE,HL
	mov r0,r8,lsr #16		;@ Get source value
	mov r1,r9,lsr #16		;@ Get destination register
	and r9,r9,r12			;@ Clear target byte to 0
	and r8,r8,r12			;@ Clear source byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	orr r8,r8,r1,lsl #16		;@ Place value on target register
	mov r2,#4
b ENDOPCODES

OPCODE_EC:	;@ CALL PE,(nn)
	tst r8,#0x400			;@ Test P flag
	beq callpe
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@ Get address from current PC into r1
	mov r4,r1			;@ Save address in R4
	add r0,r2,#2			;@ Increase Pc by 2
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callpef
callpe:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callpef:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_ED:	;@ ED
	b EXCODES
b ENDOPCODES

OPCODE_EE:	;@ XOR n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_EF:	;@ RST 28H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x28			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_F0:	;@ RET P
	mov r2,#5			;@ Tstates
	tst r8,#0x8000			;@ Test P flag
	bne ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_F1:	;@ POP AF
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT3
	add r1,r1,#2			;@ Increase SP
	and r7,r7,r12			;@ Clear old SP value
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	bic r8,r8,r12			;@ Clear target byte To 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#10
b ENDOPCODES

OPCODE_F2:	;@ JP P,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x8000			;@ Test S flag
	movne r1,r7			;@ Get old PC if cond not met
	addne r1,r1,#2			;@ Increase the PC by 2
	andne r1,r1,r12			;@ Mask to 16 bits
	bleq MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_F3:	;@ DI
	bic r5,r5,#0xC0000000		;@ Set IFF1 and IFF2 flags (bits 31 and 30)
	mov r2,#4
b ENDOPCODES

OPCODE_F4:	;@ CALL P,(nn)
	tst r8,#0x8000			;@Test S flag
	bne callp
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@ Get address from current PC into r1
	mov r4,r1			;@ Save address in R4
	add r0,r2,#2			;@ Increase Pc by 2
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callpf
callp:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callpf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_F5:	;@ PUSH AF
	and r0,r8,r12			;@ Mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r2,r1,#2			;@ Decrease stack by 2
	and r2,r2,r12			;@ Mask to 16 bits
	add r1,r2,#1
	bl MEMSTORE			;@ Store value in memory
	mov r0,r0,lsr #8
	mov r1,r2
	bl MEMSTORE			;@ Store value in memory
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r2,lsl #16		;@ Replace with new SP
	mov r2,#11
b ENDOPCODES

OPCODE_F6:	;@ OR n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#7
b ENDOPCODES

OPCODE_F7:	;@ RST 30H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x30			;@ Add New PC
	mov r2,#11
b ENDOPCODES

OPCODE_F8:	;@ RET M
	mov r2,#5			;@ Tstates
	tst r8,#0x8000			;@ Test M flag
	beq ENDOPCODES
	mov r1,r7,lsr #16		;@ Put SP in R2
	bl MEMREADSHORT			;@ Retrieve PC into R1
	mov r7,r0			;@ Put it into R7 (PC)
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#11			;@ Increase Tstates
b ENDOPCODES

OPCODE_F9:	;@ LD SP,HL
	mov r0,r8,lsr #16		;@ Get source value
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#6
b ENDOPCODES

OPCODE_FA:	;@ JP M,(nn)
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	tst r8,#0x8000			;@ Test S flag
	moveq r1,r7			;@ Get old PC if cond not met
	addeq r1,r1,#2			;@ Increase the PC by 2
	andeq r1,r1,r12			;@ Mask to 16 bits
	blne MEMFETCHSHORT2		;@ Read address into R1
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r1			;@ Add new PC
	mov r2,#10
b ENDOPCODES

OPCODE_FB:	;@ EI
	orr r5,r5,#0xC0000000		;@ Set IFF1 and IFF2 flags (bits 31 and 30)
	mov r2,#4
b ENDOPCODES

OPCODE_FC:	;@ CALL M,(nn)
	tst r8,#0x8000			;@ Test S flag
	beq callm
	and r2,r7,r12			;@ Move PC into R2 and mask to 16 bits
	bl MEMFETCHSHORT2		;@ Get address from current PC into r1
	mov r4,r1			;@ Save address in R4
	add r0,r2,#2			;@ Increase Pc by 2
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#17			;@ set tstates
	b callmf
callm:
	mov r1,r7			;@ Get old PC if cond not met
	add r1,r1,#2			;@ Increase the PC by 2
	and r4,r1,r12			;@ Mask to 16 bits
	mov r2,#10			;@ set tstates
callmf:
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r4			;@ Add new PC
b ENDOPCODES

OPCODE_FD:	;@ FD
	b FDCODES
b ENDOPCODES

OPCODE_FE:	;@ CP n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#7
b ENDOPCODES

OPCODE_FF:	;@ RST 38H
	and r0,r7,r12			;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memor
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,#0x38			;@ Add New PC
	mov r2,#11
b ENDOPCODES

EXCODES:
	bl MEMFETCH
	add r1,r1,#1		;@R1 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r3,r5,#1
	and r3,r3,#127
	bic r5,r5,#127
	orr r5,r5,r3				;@ 4 Lines to increase r register!
;@	adrl r3,rpointer
;@	ldr r2,[r3]    		;@These three lines store the opcode For debugging
;@	Str r0,[r2,#40]
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b EXOPCODE_00
			b EXOPCODE_01
			b EXOPCODE_02
			b EXOPCODE_03
			b EXOPCODE_04
			b EXOPCODE_05
			b EXOPCODE_06
			b EXOPCODE_07
			b EXOPCODE_08
			b EXOPCODE_09
			b EXOPCODE_0A
			b EXOPCODE_0B
			b EXOPCODE_0C
			b EXOPCODE_0D
			b EXOPCODE_0E
			b EXOPCODE_0F
			b EXOPCODE_10
			b EXOPCODE_11
			b EXOPCODE_12
			b EXOPCODE_13
			b EXOPCODE_14
			b EXOPCODE_15
			b EXOPCODE_16
			b EXOPCODE_17
			b EXOPCODE_18
			b EXOPCODE_19
			b EXOPCODE_1A
			b EXOPCODE_1B
			b EXOPCODE_1C
			b EXOPCODE_1D
			b EXOPCODE_1E
			b EXOPCODE_1F
			b EXOPCODE_20
			b EXOPCODE_21
			b EXOPCODE_22
			b EXOPCODE_23
			b EXOPCODE_24
			b EXOPCODE_25
			b EXOPCODE_26
			b EXOPCODE_27
			b EXOPCODE_28
			b EXOPCODE_29
			b EXOPCODE_2A
			b EXOPCODE_2B
			b EXOPCODE_2C
			b EXOPCODE_2D
			b EXOPCODE_2E
			b EXOPCODE_2F
			b EXOPCODE_30
			b EXOPCODE_31
			b EXOPCODE_32
			b EXOPCODE_33
			b EXOPCODE_34
			b EXOPCODE_35
			b EXOPCODE_36
			b EXOPCODE_37
			b EXOPCODE_38
			b EXOPCODE_39
			b EXOPCODE_3A
			b EXOPCODE_3B
			b EXOPCODE_3C
			b EXOPCODE_3D
			b EXOPCODE_3E
			b EXOPCODE_3F
			b EXOPCODE_40
			b EXOPCODE_41
			b EXOPCODE_42
			b EXOPCODE_43
			b EXOPCODE_44
			b EXOPCODE_45
			b EXOPCODE_46
			b EXOPCODE_47
			b EXOPCODE_48
			b EXOPCODE_49
			b EXOPCODE_4A
			b EXOPCODE_4B
			b EXOPCODE_4C
			b EXOPCODE_4D
			b EXOPCODE_4E
			b EXOPCODE_4F
			b EXOPCODE_50
			b EXOPCODE_51
			b EXOPCODE_52
			b EXOPCODE_53
			b EXOPCODE_54
			b EXOPCODE_55
			b EXOPCODE_56
			b EXOPCODE_57
			b EXOPCODE_58
			b EXOPCODE_59
			b EXOPCODE_5A
			b EXOPCODE_5B
			b EXOPCODE_5C
			b EXOPCODE_5D
			b EXOPCODE_5E
			b EXOPCODE_5F
			b EXOPCODE_60
			b EXOPCODE_61
			b EXOPCODE_62
			b EXOPCODE_63
			b EXOPCODE_64
			b EXOPCODE_65
			b EXOPCODE_66
			b EXOPCODE_67
			b EXOPCODE_68
			b EXOPCODE_69
			b EXOPCODE_6A
			b EXOPCODE_6B
			b EXOPCODE_6C
			b EXOPCODE_6D
			b EXOPCODE_6E
			b EXOPCODE_6F
			b EXOPCODE_70
			b EXOPCODE_71
			b EXOPCODE_72
			b EXOPCODE_73
			b EXOPCODE_74
			b EXOPCODE_75
			b EXOPCODE_76
			b EXOPCODE_77
			b EXOPCODE_78
			b EXOPCODE_79
			b EXOPCODE_7A
			b EXOPCODE_7B
			b EXOPCODE_7C
			b EXOPCODE_7D
			b EXOPCODE_7E
			b EXOPCODE_7F
			b EXOPCODE_80
			b EXOPCODE_81
			b EXOPCODE_82
			b EXOPCODE_83
			b EXOPCODE_84
			b EXOPCODE_85
			b EXOPCODE_86
			b EXOPCODE_87
			b EXOPCODE_88
			b EXOPCODE_89
			b EXOPCODE_8A
			b EXOPCODE_8B
			b EXOPCODE_8C
			b EXOPCODE_8D
			b EXOPCODE_8E
			b EXOPCODE_8F
			b EXOPCODE_90
			b EXOPCODE_91
			b EXOPCODE_92
			b EXOPCODE_93
			b EXOPCODE_94
			b EXOPCODE_95
			b EXOPCODE_96
			b EXOPCODE_97
			b EXOPCODE_98
			b EXOPCODE_99
			b EXOPCODE_9A
			b EXOPCODE_9B
			b EXOPCODE_9C
			b EXOPCODE_9D
			b EXOPCODE_9E
			b EXOPCODE_9F
			b EXOPCODE_A0
			b EXOPCODE_A1
			b EXOPCODE_A2
			b EXOPCODE_A3
			b EXOPCODE_A4
			b EXOPCODE_A5
			b EXOPCODE_A6
			b EXOPCODE_A7
			b EXOPCODE_A8
			b EXOPCODE_A9
			b EXOPCODE_AA
			b EXOPCODE_AB
			b EXOPCODE_AC
			b EXOPCODE_AD
			b EXOPCODE_AE
			b EXOPCODE_AF
			b EXOPCODE_B0
			b EXOPCODE_B1
			b EXOPCODE_B2
			b EXOPCODE_B3
			b EXOPCODE_B4
			b EXOPCODE_B5
			b EXOPCODE_B6
			b EXOPCODE_B7
			b EXOPCODE_B8
			b EXOPCODE_B9
			b EXOPCODE_BA
			b EXOPCODE_BB
			b EXOPCODE_BC
			b EXOPCODE_BD
			b EXOPCODE_BE
			b EXOPCODE_BF
			b EXOPCODE_C0
			b EXOPCODE_C1
			b EXOPCODE_C2
			b EXOPCODE_C3
			b EXOPCODE_C4
			b EXOPCODE_C5
			b EXOPCODE_C6
			b EXOPCODE_C7
			b EXOPCODE_C8
			b EXOPCODE_C9
			b EXOPCODE_CA
			b EXOPCODE_CB
			b EXOPCODE_CC
			b EXOPCODE_CD
			b EXOPCODE_CE
			b EXOPCODE_CF
			b EXOPCODE_D0
			b EXOPCODE_D1
			b EXOPCODE_D2
			b EXOPCODE_D3
			b EXOPCODE_D4
			b EXOPCODE_D5
			b EXOPCODE_D6
			b EXOPCODE_D7
			b EXOPCODE_D8
			b EXOPCODE_D9
			b EXOPCODE_DA
			b EXOPCODE_DB
			b EXOPCODE_DC
			b EXOPCODE_DD
			b EXOPCODE_DE
			b EXOPCODE_DF
			b EXOPCODE_E0
			b EXOPCODE_E1
			b EXOPCODE_E2
			b EXOPCODE_E3
			b EXOPCODE_E4
			b EXOPCODE_E5
			b EXOPCODE_E6
			b EXOPCODE_E7
			b EXOPCODE_E8
			b EXOPCODE_E9
			b EXOPCODE_EA
			b EXOPCODE_EB
			b EXOPCODE_EC
			b EXOPCODE_ED
			b EXOPCODE_EE
			b EXOPCODE_EF
			b EXOPCODE_F0
			b EXOPCODE_F1
			b EXOPCODE_F2
			b EXOPCODE_F3
			b EXOPCODE_F4
			b EXOPCODE_F5
			b EXOPCODE_F6
			b EXOPCODE_F7
			b EXOPCODE_F8
			b EXOPCODE_F9
			b EXOPCODE_FA
			b EXOPCODE_FB
			b EXOPCODE_FC
			b EXOPCODE_FD
			b EXOPCODE_FE
			b EXOPCODE_FF

EXOPCODE_00:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_01:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_02:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_03:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_04:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_05:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_06:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_07:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_08:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_09:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_0F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_10:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_11:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_12:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_13:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_14:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_15:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_16:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_17:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_18:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_19:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_1F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_20:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_21:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_22:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_23:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_24:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_25:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_26:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_27:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_28:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_29:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_2F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_30:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_31:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_32:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_33:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_34:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_35:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_36:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_37:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_38:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_39:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_3F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_40:		;@IN B,(C)

	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}


	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_41:		;@OUT (C),B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)

	mov r2,#12
b ENDOPCODES

EXOPCODE_42:		;@SBC HL,BC
	and r0,r9,r12			;@ Maskto 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform subtraction
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_43:		;@LD (nn),BC
	and r0,r9,r12			;@ Mask value to a 16 bit number
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

EXOPCODE_44:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask accumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_45:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_46:		;@IM 0
	bic r5,r5,#0x30000000		;@ Set IM to 0, flags (bits 29 And 28 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_47:		;@LD I,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r5,r5,#0x0000FF00		;@ Clear target byte to 0
	orr r5,r5,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

EXOPCODE_48:		;@IN C,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_49:		;@OUT (C),C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)

	mov r2,#12
b ENDOPCODES

EXOPCODE_4A:		;@ADC HL,BC
	and r0,r9,r12			;@ Maskto 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_4B:		;@LD BC,(nn)
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT2		;@ Get address
	add r2,r2,#2			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	bic r9,r9,r12			;@ Clear target byte To 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#20
b ENDOPCODES

EXOPCODE_4C:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask accumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_4D:		;@RETI
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_4E:		;@IM 0
	bic r5,r5,#0x30000000		;@ Set IM to 0, flags (bits 29 And 28 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_4F:		;@LD R,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r5,r5,#0x000000FF		;@ Clear target byte to 0
	orr r5,r5,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

EXOPCODE_50:		;@IN D,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_51:		;@OUT (C),D
	mov r0,r9,lsr #24		;@ Get source value
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)
	mov r2,#12
b ENDOPCODES

EXOPCODE_52:		;@SBC HL,DE
	mov r0,r9,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform subtraction
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_53:		;@LD (nn),DE
	mov r0,r9,lsr #16		;@ Get source value
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

EXOPCODE_54:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask accumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_55:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_56:		;@IM 1
	bic r5,r5,#0x20000000		;@ Set IM to 1, flags (bits 29 cleared And 28 set)
	orr r5,r5,#0x10000000		;@ Set IM to 1, flags (bits 29 cleared And 28 set)
	mov r2,#8
b ENDOPCODES

EXOPCODE_57:		;@LD A,I
	mov r0,r5,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0			;@ Test if zero
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	tst r5,#0x80000000		;@ Test IFF2 flag
	orrne r8,r8,#0x400		;@ Set parity to IFF2
	mov r2,#8
b ENDOPCODES

EXOPCODE_58:		;@IN E,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_59:		;@OUT (C),E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)
	mov r2,#12
b ENDOPCODES

EXOPCODE_5A:		;@ADC HL,DE
	mov r0,r9,lsr #16		;@ Get source valu
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_5B:		;@LD DE,(nn)
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT2		;@ Get address
	add r2,r2,#2			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	and r9,r9,r12			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#20
b ENDOPCODES

EXOPCODE_5C:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask accumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_5D:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_5E:		;@IM 2
	orr r5,r5,#0x20000000		;@ Set IM to 2, flags (bits 29 set And 29 cleared)
	bic r5,r5,#0x10000000		;@ Set IM to 2, flags (bits 29 set And 29 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_5F:		;@LD A,R
	and r0,r5,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0			;@ Test if zero
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	tst r5,#0x80000000		;@ Test IFF2 flag
	orrne r8,r8,#0x400		;@ Set parity to IFF2
	mov r2,#8
b ENDOPCODES

EXOPCODE_60:		;@IN H,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_61:		;@OUT (C),H
	mov r0,r8,lsr #24		;@ Get source value
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)
	mov r2,#12
b ENDOPCODES

EXOPCODE_62:		;@SBC HL,HL
	mov r0,r8,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	sub r2,r1,r1
	subne r2,r2,#1			;@ If set subtract 1
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform subtraction
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_63:		;@LD (nn),HL
	mov r0,r8,lsr #16		;@ Get source value
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

EXOPCODE_64:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask acumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_65:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_66:		;@IM 0
	bic r5,r5,#0x30000000		;@ Set IM to 0, flags (bits 29 And 28 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_67:		;@RRD
	mov r1,r8,lsr #16		;@ Get value of HL register
	bl MEMREAD
	mov r2,r0			;@ Move value to R2
	and r1,r8,#0xF			;@ Get low nibble of accumulator
	mov r1,r1,lsl #4		;@ Move low nibble to high nibble
	orr r0,r1,r0,lsr #4		;@ Create new (HL) value
	bl STOREMEM2			;@ Store back to memory
;@	strb r0,[r3]			;@ R3 still contains correct address
	and r0,r2,#0xF			;@ Get low nibble
	bic r8,r8,#0xF			;@ Clear low nible of accumulator
	orrs r8,r8,r0			;@ Create new accumulator value
 	bic r8,r8,#0xFE00		;@ Clear old flags (except carry)
	tst r8,#0xFF			;@ Test if zero
	orreq r8,r8,#0x4000		;@ Set zero flag if acc is 0
	tst r8,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r8,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r8,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	tst r5,#0x80000000		;@ Test IFF2 flag
	orrne r8,r8,#0x400		;@ Set P flag if IFF2 set
	mov r2,#18
b ENDOPCODES


EXOPCODE_68:		;@IN L,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_69:		;@OUT (C),L
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)
	mov r2,#12
b ENDOPCODES

EXOPCODE_6A:		;@ADC HL,HL
	mov r0,r8,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	add r2,r2,r2
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_6B:		;@LD HL,(nn)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT			;@ Get address
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r0			;@ Put address to load into R1
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	and r8,r8,r12			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#20
b ENDOPCODES

EXOPCODE_6C:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask acumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_6D:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@ Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_6E:		;@IM 0
	bic r5,r5,#0x30000000		;@ Set IM to 0, flags (bits 29 And 28 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_6F:		;@RLD
	mov r1,r8,lsr #16		;@ Get value of HL register
	bl MEMREAD			;@ load value from memory
	mov r2,r0,lsl #4		;@ Move low nibble to high nibble
	and r1,r8,#0xF			;@ Get low nibble of accumulator
	orr r0,r2,r1			;@ Create new (HL) value
	bl STOREMEM2			;@ Store back to memory
;@	strb r0,[r3]			;@ R3 still contains correct HL address
	and r1,r8,#0xF0			;@ Get high nible of accumulator
	orrs r0,r1,r2,lsr #8		;@ Create new accumulator value
	bic r8,r8,#0xFF			;@ Clear old accumulator
	orr r8,r8,r0			;@ Store new accumulator
 	bic r8,r8,#0xFE00		;@ Clear old flags (except carry)
	orreq r8,r8,#0x4000		;@ Set zero flag if acc is 0
	tst r8,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r8,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r8,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	tst r5,#0x80000000		;@ Test IFF2 flag
	orrne r8,r8,#0x400		;@ Set P flag if IFF2 set
	mov r2,#18
b ENDOPCODES

EXOPCODE_70:		;@IN F,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x0000FF00		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #8		;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_71:		;@OUT (C),0
	mov r0,#0			;@ Put zero in R0
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)

	mov r2,#12
b ENDOPCODES

EXOPCODE_72:		;@SBC HL,SP
	mov r0,r7,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform subtraction
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_73:		;@LD (nn),SP
	mov r0,r7,lsr #16		;@ Get source value
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

EXOPCODE_74:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask acumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_75:		;@RETN
	bic r5,r5,#0x40000000		;@ Clear old IFF 1 value
	tst r5,#0x80000000		;@ Test IFF 2 value
	orrne r5,r5,#0x40000000		;@Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@ Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@ Put new PC in R7
	add r1,r1,#2			;@ Increase SP
	add r7,r7,r1,lsl #16		;@ Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_76:		;@IM 1
	bic r5,r5,#0x20000000		;@ Set IM to 1, flags (bits 29 cleared And 28 set)
	orr r5,r5,#0x10000000		;@ Set IM to 1, flags (bits 29 cleared And 28 set)
	mov r2,#8
b ENDOPCODES

EXOPCODE_77:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_78:		;@IN A,(C)
	and r0,r9,r12			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#12
b ENDOPCODES

EXOPCODE_79:		;@OUT (C),A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	and r1,r1,#0xFF			;@ Mask B Reg (Port number)
	mov r2,#12
b ENDOPCODES

EXOPCODE_7A:		;@ADC HL,SP
	mov r0,r7,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r8,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r8,lsr #16		;@ Get destination register
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,r12			;@ Mask back to 16 bits and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#32768			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r8,r8,r12			;@ Clear target short to 0
	orr r8,r8,r2,lsl #16		;@ Place value on target register
	mov r1,r8,lsr #16		;@ Get destination register
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#32768			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

EXOPCODE_7B:		;@LD SP,(nn)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT			;@ Get address
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r0			;@ Put address to load into R1
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#20
b ENDOPCODES

EXOPCODE_7C:		;@NEG
	mov r0,#0			;@ Put 0 in R0
	and r2,r8,#15			;@ Mask off to a low nibble of accumulator
	sub r2,r0,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask acumulator off to a single byte
	subs r2,r0,r2			;@ Perform subtraction
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0xFF			;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	and r0,r8,r2			;@ And the accumulator and result
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

EXOPCODE_7D:		;@RETN
	bic r5,r5,#0x40000000		;@Clear old IFF 1 value
	tst r5,#0x80000000		;@Test IFF 2 value
	orrne r5,r5,#0x40000000		;@Set IFF1 to same as IFF2
	mov r1,r7,lsr #16		;@Put SP in R1
	bl MEMREADSHORT
	mov r7,r0			;@Put new PC in R7
	add r1,r1,#2			;@Increase SP
	add r7,r7,r1,lsl #16		;@Put SP in Reg 7
	mov r2,#14
b ENDOPCODES

EXOPCODE_7E:		;@IM 2
	orr r5,r5,#0x20000000		;@ Set IM to 2, flags (bits 29 set And 29 cleared)
	bic r5,r5,#0x10000000		;@ Set IM to 2, flags (bits 29 set And 29 cleared)
	mov r2,#8
b ENDOPCODES

EXOPCODE_7F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_80:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_81:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_82:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_83:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_84:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_85:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_86:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_87:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_88:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_89:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_8F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_90:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_91:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_92:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_93:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_94:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_95:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_96:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_97:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_98:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_99:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_9F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_A0:		;@LDI
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value

	mov r1,r9,lsr #16			;@ Get value of DE register

	sub r9,r9,#1 				;@ Decrease BC
	ands r9,r9,r12 				;@ Mask to 16 bits
	bic r8,r8,#0x1600			;@ Clear H,P & N flags
	orrne r8,r8,#0x400			;@ Set P flag if not zero

	add r2,r1,#1 				;@ Increase DE
	orr r9,r9,r2,lsl #16			;@ Store new DE value


	bl MEMSTORE 				;@ Store value to memory - before inc in R1
	mov r2,#16
b ENDOPCODES

EXOPCODE_A1:		;@CPI
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	bic r8,r8,#0xFE00			;@ Clear all flags except carry
	and r1,r8,#15				;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16				;@ Test bit 4 flag
	orrne r8,r8,#0x1000			;@ Set H flag if set
	and r1,r8,#255				;@ Mask off accumulator to a single byte
	sub r2,r1,r0				;@ Compare values
	ands r2,r2,#0xFF			;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000			;@ Set Zero flag if need be
	tst r2,#128				;@ Test sign
	orrne r8,r8,#0x8000			;@ Set Sign flag if need be
	tst r2,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r2,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	orr r8,r8,#0x200			;@ Set N fla
	and r2,r9,r12				;@ Get masked value of BC register
	sub r2,r2,#1 				;@ Decrease BC
	ands r2,r2,r12 				;@ Mask to 16 bits
	bic r9,r9,r12 				;@ Clear old BC value
	orr r9,r9,r2				;@ Store new BC value
	orrne r8,r8,#0x400			;@ Set P flag if not zero
	mov r2,#16
b ENDOPCODES

EXOPCODE_A2:		;@INI
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	sub r0,r1,#1			;@ Decrease B reg
	bic r9,r9,#0xFF00		;@ Clear old B reg
	ands r0,r0,#0xFF		;@ Mask new B reg
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	orr r9,r9,r0,lsl #8		;@ Store new B reg
	and r0,r1,#0xFF			;@ Mask B Reg (Port number)

	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	orr r8,r8,#0x200		;@ Set N Flag
;@	tst r0,#32			;@ Test 5 flag
;@	orrne r8,r8,#0x2000		;@ Set 5 flag
;@	tst r0,#8			;@ Test 3 flag
;@	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8,lsr #16		;@ Move HL into R1
	add r2,r1,#1			;@ Increment HL Register
	and r8,r8,#12			;@ Clear old HL value
	orr r8,r8,r2,lsl #16		;@ Replace with new HL value
	bl MEMSTORE			;@ Store byte to memory
	mov r2,#16
b ENDOPCODES

EXOPCODE_A3:		;@OUTI
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	;@and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r2,r9,lsr #8			;@ Get B register
	and r2,r2,#0xFF				;@ Get masked value of B register
	sub r2,r2,#1 				;@ Decrease B
	ands r2,r2,#0xFF 			;@ Mask to 8 bits
	and r1,r9,#0xFF				;@ Get masked value of C register

	bic r9,r9,#0xFF00 			;@ Clear old B value
	orr r9,r9,r2,lsl #8			;@ Store new B value
	mov r2,#16
b ENDOPCODES

EXOPCODE_A4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_A5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_A6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_A7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_A8:		;@LDD
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value

	mov r1,r9,lsr #16			;@ Get value of DE register

	sub r9,r9,#1 				;@ Decrease BC
	ands r9,r9,r12 				;@ Mask to 16 bits
	bic r8,r8,#0x1600			;@ Clear H,P & N flags
	orrne r8,r8,#0x400			;@ Set P flag if not zero

	sub r2,r1,#1 				;@ Decrease DE
	orr r9,r9,r2,lsl #16			;@ Store new DE value


	bl MEMSTORE 				;@ Store value to memory - before inc in R1
	mov r2,#16
b ENDOPCODES

EXOPCODE_A9:		;@CPD
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	bic r8,r8,#0xFE00			;@ Clear all flags except carry
	and r1,r8,#15				;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16				;@ Test bit 4 flag
	orrne r8,r8,#0x1000			;@ Set H flag if set
	and r1,r8,#255				;@ Mask off accumulator to a single byte
	sub r2,r1,r0				;@ Compare values
	ands r2,r2,#0xFF			;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000			;@ Set Zero flag if need be
	tst r2,#128				;@ Test sign
	orrne r8,r8,#0x8000			;@ Set Sign flag if need be
	tst r2,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r2,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	orr r8,r8,#0x200			;@ Set N fla
	and r2,r9,r12				;@ Get masked value of BC register
	sub r2,r2,#1 				;@ Decrease BC
	ands r2,r2,r12 				;@ Mask to 16 bits
	bic r9,r9,r12 				;@ Clear old BC value
	orr r9,r9,r2				;@ Store new BC value
	orrne r8,r8,#0x400			;@ Set P flag if not zero
	mov r2,#16
b ENDOPCODES

EXOPCODE_AA:		;@IND
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	sub r0,r1,#1			;@ Decrease B reg
	bic r9,r9,#0xFF00		;@ Clear old B reg
	ands r0,r0,#0xFF		;@ Mask new B reg
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	orr r9,r9,r0,lsl #8		;@ Store new B reg
	and r0,r1,#0xFF			;@ Mask B Reg (Port number)
	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	orr r8,r8,#0x200		;@ Set N Flag
;@	tst r0,#32			;@ Test 5 flag
;@	orrne r8,r8,#0x2000		;@ Set 5 flag
;@	tst r0,#8			;@ Test 3 flag
;@	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8,lsr #16		;@ Move HL into R1
	sub r2,r1,#1			;@ Decrement HL Register
	and r8,r8,#12			;@ Clear old HL value
	orr r8,r8,r2,lsl #16		;@ Replace with new HL value
	bl MEMSTORE			;@ Store byte to memory
	mov r2,#16
b ENDOPCODES

EXOPCODE_AB:		;@OUTD
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	;@and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r2,r9,lsr #8			;@ Get B register
	and r2,r2,#0xFF				;@ Get masked value of B register
	sub r2,r2,#1 				;@ Decrease B
	ands r2,r2,#0xFF 			;@ Mask to 8 bits
	and r1,r9,#0xFF				;@ Get masked value of C register

	bic r9,r9,#0xFF00 			;@ Clear old B value
	orr r9,r9,r2,lsl #8			;@ Store new B value
	mov r2,#16
b ENDOPCODES

EXOPCODE_AC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_AD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_AE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_AF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_B0:		;@LDIR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r1,r9,lsr #16			;@ Get value of DE register
	add r2,r1,#1 				;@ Increase DE
	bl MEMSTORE 				;@ Store value to memory

	sub r9,r9,#1 				;@ Decrease BC
	ands r9,r9,r12 				;@ Mask to 16 bits

	orr r9,r9,r2,lsl #16			;@ Store new DE value

	bic r8,r8,#0x1600			;@ Clear H,P & N flags
	moveq r2,#16				;@ Put in initial tstates
	beq ENDOPCODES				;@ Finish instruction if zero
	;@and r1,r7,r12				;@ Get masked PC
	sub r1,r7,#2				;@ Take PC back 2
	and r1,r1,r12				;@ Mask back to 16 bits
	bic r7,r7,r12				;@ Clear old PC value
	orr r7,r7,r1				;@ Store new PC value
	mov r2,#21				;@ Increase tstates
b ENDOPCODES

EXOPCODE_B1:		;@CPIR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	bic r8,r8,#0xFE00			;@ Clear all flags except carry
	and r1,r8,#15				;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16				;@ Test bit 4 flag
	orrne r8,r8,#0x1000			;@ Set H flag if set
	and r1,r8,#255				;@ Mask off accumulator to a single byte
	sub r2,r1,r0				;@ Compare values
	ands r2,r2,#0xFF			;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000			;@ Set Zero flag if need be
	tst r2,#128				;@ Test sign
	orrne r8,r8,#0x8000			;@ Set Sign flag if need be
	tst r2,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r2,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	orr r8,r8,#0x200			;@ Set N fla
	and r2,r9,r12				;@ Get masked value of BC register
	sub r2,r2,#1 				;@ Decrease BC
	ands r2,r2,r12 				;@ Mask to 16 bits
	bic r9,r9,r12 				;@ Clear old BC value
	orr r9,r9,r2				;@ Store new BC value
	orrne r8,r8,#0x400			;@ Set P flag if not zero
	mov r2,#16				;@ Increase tstates
	beq ENDOPCODES				;@ Finish instruction if zero
	tst r8,#0x4000				;@ Test Z flag
	bne ENDOPCODES				;@ Finish instruction if set
	;@and r1,r7,r12				;@ Get masked PC
	sub r1,r7,#2				;@ Take PC back 2
	and r1,r1,r12				;@ Mask back to 16 bits
	bic r7,r7,r12				;@ Clear old PC value
	orr r7,r7,r1				;@ Store new PC value
	add r2,r2,#5				;@ Increase tstates
b ENDOPCODES

EXOPCODE_B2:		;@INIR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0			;@ 4 Lines to increase r register!
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	sub r0,r1,#1			;@ Decrease B reg
	bic r9,r9,#0xFF00		;@ Clear old B reg
	ands r0,r0,#0xFF		;@ Mask new B reg
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	orr r9,r9,r0,lsl #8		;@ Store new B reg
	and r0,r1,#0xFF			;@ Mask B Reg (Port number)
	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	orr r8,r8,#0x200		;@ Set N Flag
;@	tst r0,#32			;@ Test 5 flag
;@	orrne r8,r8,#0x2000		;@ Set 5 flag
;@	tst r0,#8			;@ Test 3 flag
;@	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8,lsr #16		;@ Move HL into R1
	add r2,r1,#1			;@ Increment HL Register
	and r8,r8,#12			;@ Clear old HL value
	orr r8,r8,r2,lsl #16		;@ Replace with new HL value
	bl MEMSTORE			;@ Store byte to memory
	tst r8,#0x4000			;@ Test Zero Flag
	movne r2,#16
	bne ENDOPCODES
	mov r2,#21			;@ Increase tstates
	sub r1,r7,#2
	and r1,r1,r12
	bic r7,r7,r12
	orr r7,r7,r1
b ENDOPCODES

EXOPCODE_B3:		;@OTIR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	add r1,r1,#1 				;@ Increase HL
	;@and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r2,r9,lsr #8			;@ Get B register
	and r2,r2,#0xFF				;@ Get masked value of B register
	sub r2,r2,#1 				;@ Decrease B
	ands r2,r2,#0xFF 			;@ Mask to 8 bits
	and r1,r9,#0xFF				;@ Get masked value of C register

	bic r9,r9,#0xFF00 			;@ Clear old B value
	orr r9,r9,r2,lsl #8			;@ Store new B value
	cmp r2,#0
	mov r2,#16
	beq ENDOPCODES
	add r2,r2,#5			;@ Increase tstates
	sub r1,r7,#2
	and r1,r1,r12
	bic r7,r7,r12
	orr r7,r7,r1
b ENDOPCODES

EXOPCODE_B4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_B5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_B6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_B7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_B8:		;@LDDR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r1,r9,lsr #16			;@ Get value of DE register
	sub r2,r1,#1 				;@ Decrease DE
	bl MEMSTORE 				;@ Store value to memory

	sub r9,r9,#1 				;@ Decrease BC
	ands r9,r9,r12 				;@ Mask to 16 bits

	orr r9,r9,r2,lsl #16			;@ Store new DE value

	bic r8,r8,#0x1600			;@ Clear H,P & N flags
	moveq r2,#16				;@ Put in initial tstates
	beq ENDOPCODES				;@ Finish instruction if zero
	;@and r1,r7,r12				;@ Get masked PC
	sub r1,r7,#2				;@ Take PC back 2
	and r1,r1,r12				;@ Mask back to 16 bits
	bic r7,r7,r12				;@ Clear old PC value
	orr r7,r7,r1				;@ Store new PC value
	mov r2,#21
b ENDOPCODES

EXOPCODE_B9:		;@CPDR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	bic r8,r8,#0xFE00			;@ Clear all flags except carry
	and r1,r8,#15				;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16				;@ Test bit 4 flag
	orrne r8,r8,#0x1000			;@ Set H flag if set
	and r1,r8,#255				;@ Mask off accumulator to a single byte
	sub r2,r1,r0				;@ Compare values
	ands r2,r2,#0xFF			;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000			;@ Set Zero flag if need be
	tst r2,#128				;@ Test sign
	orrne r8,r8,#0x8000			;@ Set Sign flag if need be
	tst r2,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r2,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	orr r8,r8,#0x200			;@ Set N fla
	and r2,r9,r12				;@ Get masked value of BC register
	sub r2,r2,#1 				;@ Decrease BC
	ands r2,r2,r12 				;@ Mask to 16 bits
	bic r9,r9,r12 				;@ Clear old BC value
	orr r9,r9,r2				;@ Store new BC value
	orrne r8,r8,#0x400			;@ Set P flag if not zero
	mov r2,#16				;@ Set initial tstates
	beq ENDOPCODES				;@ Finish instruction if zero
	tst r8,#0x4000				;@ Test Z flag
	bne ENDOPCODES				;@ Finish instruction if set
	;@and r1,r7,r12				;@ Get masked PC
	sub r1,r7,#2				;@ Take PC back 2
	and r1,r1,r12				;@ Mask back to 16 bits
	bic r7,r7,r12				;@ Clear old PC value
	orr r7,r7,r1				;@ Store new PC value
	add r2,r2,#5				;@ Increase tstates
b ENDOPCODES

EXOPCODE_BA:		;@INDR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0			;@ 4 Lines to increase r register!
	bic r8,r8,#0xFE00		;@ Clear all flags except carry
	and r2,r9,#0xFF			;@ Get value of C reg
	mov r1,r9,lsr #8		;@ Get value of B reg
	sub r0,r1,#1			;@ Decrease B reg
	bic r9,r9,#0xFF00		;@ Clear old B reg
	ands r0,r0,#0xFF		;@ Mask new B reg
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	orr r9,r9,r0,lsl #8		;@ Store new B reg
	and r0,r1,#0xFF			;@ Mask B Reg (Port number)
	stmdb sp!,{r3,r12,lr}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;;@ r0=port - data returned in r0
    ldmia sp!,{r3,r12,lr}

	orr r8,r8,#0x200		;@ Set N Flag
;@	tst r0,#32			;@ Test 5 flag
;@	orrne r8,r8,#0x2000		;@ Set 5 flag
;@	tst r0,#8			;@ Test 3 flag
;@	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r1,r8,lsr #16		;@ Move HL into R1
	sub r2,r1,#1			;@ Decrement HL Register
	and r8,r8,#12			;@ Clear old HL value
	orr r8,r8,r2,lsl #16		;@ Replace with new HL value
	bl MEMSTORE			;@ Store byte to memory
	tst r8,#0x4000			;@ Test Zero Flag
	movne r2,#16
	bne ENDOPCODES
	mov r2,#21			;@ Increase tstates
	sub r1,r7,#2
	and r1,r1,r12
	bic r7,r7,r12
	orr r7,r7,r1
b ENDOPCODES

EXOPCODE_BB:		;@OTDR
	;@add r0,r5,#1
	;@and r0,r0,#127
	;@bic r5,r5,#127
	;@orr r5,r5,r0				;@ 4 Lines to increase r register!
	mov r1,r8,lsr #16			;@ Get value of HL register
	bl MEMREAD
	sub r1,r1,#1 				;@ Decrease HL
	;@and r1,r1,r12 				;@ Mask to 16 bits
	and r8,r8,r12 				;@ Clear old HL value
	orr r8,r8,r1,lsl #16			;@ Store new HL value
	mov r2,r9,lsr #8			;@ Get B register
	and r2,r2,#0xFF				;@ Get masked value of B register
	sub r2,r2,#1 				;@ Decrease B
	ands r2,r2,#0xFF 			;@ Mask to 8 bits
	and r1,r9,#0xFF				;@ Get masked value of C register
	bic r9,r9,#0xFF00 			;@ Clear old B value
	orr r9,r9,r2,lsl #8			;@ Store new B value
	cmp r2,#0
	mov r2,#16
	beq ENDOPCODES
	add r2,r2,#5			;@ Increase tstates
	sub r1,r7,#2
	and r1,r1,r12
	bic r7,r7,r12
	orr r7,r7,r1

b ENDOPCODES

EXOPCODE_BC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_BD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_BE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_BF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_C9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_CF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_D9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_DF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_E9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_EA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_EB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_EC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_ED:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_EE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_EF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_F9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

EXOPCODE_FF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

CBCODES:
	bl MEMREAD
	add r1,r1,#1		;@R1 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r3,r5,#1
	and r3,r3,#127
	bic r5,r5,#127
	orr r5,r5,r3				;@ 4 Lines to increase r register!
;@	ldr r3,=rpointer
;@	ldr r2,[r3]    		;@These three lines store the opcode For debugging
;@	Str r0,[r2,#40]
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b CBOPCODE_00
			b CBOPCODE_01
			b CBOPCODE_02
			b CBOPCODE_03
			b CBOPCODE_04
			b CBOPCODE_05
			b CBOPCODE_06
			b CBOPCODE_07
			b CBOPCODE_08
			b CBOPCODE_09
			b CBOPCODE_0A
			b CBOPCODE_0B
			b CBOPCODE_0C
			b CBOPCODE_0D
			b CBOPCODE_0E
			b CBOPCODE_0F
			b CBOPCODE_10
			b CBOPCODE_11
			b CBOPCODE_12
			b CBOPCODE_13
			b CBOPCODE_14
			b CBOPCODE_15
			b CBOPCODE_16
			b CBOPCODE_17
			b CBOPCODE_18
			b CBOPCODE_19
			b CBOPCODE_1A
			b CBOPCODE_1B
			b CBOPCODE_1C
			b CBOPCODE_1D
			b CBOPCODE_1E
			b CBOPCODE_1F
			b CBOPCODE_20
			b CBOPCODE_21
			b CBOPCODE_22
			b CBOPCODE_23
			b CBOPCODE_24
			b CBOPCODE_25
			b CBOPCODE_26
			b CBOPCODE_27
			b CBOPCODE_28
			b CBOPCODE_29
			b CBOPCODE_2A
			b CBOPCODE_2B
			b CBOPCODE_2C
			b CBOPCODE_2D
			b CBOPCODE_2E
			b CBOPCODE_2F
			b CBOPCODE_30
			b CBOPCODE_31
			b CBOPCODE_32
			b CBOPCODE_33
			b CBOPCODE_34
			b CBOPCODE_35
			b CBOPCODE_36
			b CBOPCODE_37
			b CBOPCODE_38
			b CBOPCODE_39
			b CBOPCODE_3A
			b CBOPCODE_3B
			b CBOPCODE_3C
			b CBOPCODE_3D
			b CBOPCODE_3E
			b CBOPCODE_3F
			b CBOPCODE_40
			b CBOPCODE_41
			b CBOPCODE_42
			b CBOPCODE_43
			b CBOPCODE_44
			b CBOPCODE_45
			b CBOPCODE_46
			b CBOPCODE_47
			b CBOPCODE_48
			b CBOPCODE_49
			b CBOPCODE_4A
			b CBOPCODE_4B
			b CBOPCODE_4C
			b CBOPCODE_4D
			b CBOPCODE_4E
			b CBOPCODE_4F
			b CBOPCODE_50
			b CBOPCODE_51
			b CBOPCODE_52
			b CBOPCODE_53
			b CBOPCODE_54
			b CBOPCODE_55
			b CBOPCODE_56
			b CBOPCODE_57
			b CBOPCODE_58
			b CBOPCODE_59
			b CBOPCODE_5A
			b CBOPCODE_5B
			b CBOPCODE_5C
			b CBOPCODE_5D
			b CBOPCODE_5E
			b CBOPCODE_5F
			b CBOPCODE_60
			b CBOPCODE_61
			b CBOPCODE_62
			b CBOPCODE_63
			b CBOPCODE_64
			b CBOPCODE_65
			b CBOPCODE_66
			b CBOPCODE_67
			b CBOPCODE_68
			b CBOPCODE_69
			b CBOPCODE_6A
			b CBOPCODE_6B
			b CBOPCODE_6C
			b CBOPCODE_6D
			b CBOPCODE_6E
			b CBOPCODE_6F
			b CBOPCODE_70
			b CBOPCODE_71
			b CBOPCODE_72
			b CBOPCODE_73
			b CBOPCODE_74
			b CBOPCODE_75
			b CBOPCODE_76
			b CBOPCODE_77
			b CBOPCODE_78
			b CBOPCODE_79
			b CBOPCODE_7A
			b CBOPCODE_7B
			b CBOPCODE_7C
			b CBOPCODE_7D
			b CBOPCODE_7E
			b CBOPCODE_7F
			b CBOPCODE_80
			b CBOPCODE_81
			b CBOPCODE_82
			b CBOPCODE_83
			b CBOPCODE_84
			b CBOPCODE_85
			b CBOPCODE_86
			b CBOPCODE_87
			b CBOPCODE_88
			b CBOPCODE_89
			b CBOPCODE_8A
			b CBOPCODE_8B
			b CBOPCODE_8C
			b CBOPCODE_8D
			b CBOPCODE_8E
			b CBOPCODE_8F
			b CBOPCODE_90
			b CBOPCODE_91
			b CBOPCODE_92
			b CBOPCODE_93
			b CBOPCODE_94
			b CBOPCODE_95
			b CBOPCODE_96
			b CBOPCODE_97
			b CBOPCODE_98
			b CBOPCODE_99
			b CBOPCODE_9A
			b CBOPCODE_9B
			b CBOPCODE_9C
			b CBOPCODE_9D
			b CBOPCODE_9E
			b CBOPCODE_9F
			b CBOPCODE_A0
			b CBOPCODE_A1
			b CBOPCODE_A2
			b CBOPCODE_A3
			b CBOPCODE_A4
			b CBOPCODE_A5
			b CBOPCODE_A6
			b CBOPCODE_A7
			b CBOPCODE_A8
			b CBOPCODE_A9
			b CBOPCODE_AA
			b CBOPCODE_AB
			b CBOPCODE_AC
			b CBOPCODE_AD
			b CBOPCODE_AE
			b CBOPCODE_AF
			b CBOPCODE_B0
			b CBOPCODE_B1
			b CBOPCODE_B2
			b CBOPCODE_B3
			b CBOPCODE_B4
			b CBOPCODE_B5
			b CBOPCODE_B6
			b CBOPCODE_B7
			b CBOPCODE_B8
			b CBOPCODE_B9
			b CBOPCODE_BA
			b CBOPCODE_BB
			b CBOPCODE_BC
			b CBOPCODE_BD
			b CBOPCODE_BE
			b CBOPCODE_BF
			b CBOPCODE_C0
			b CBOPCODE_C1
			b CBOPCODE_C2
			b CBOPCODE_C3
			b CBOPCODE_C4
			b CBOPCODE_C5
			b CBOPCODE_C6
			b CBOPCODE_C7
			b CBOPCODE_C8
			b CBOPCODE_C9
			b CBOPCODE_CA
			b CBOPCODE_CB
			b CBOPCODE_CC
			b CBOPCODE_CD
			b CBOPCODE_CE
			b CBOPCODE_CF
			b CBOPCODE_D0
			b CBOPCODE_D1
			b CBOPCODE_D2
			b CBOPCODE_D3
			b CBOPCODE_D4
			b CBOPCODE_D5
			b CBOPCODE_D6
			b CBOPCODE_D7
			b CBOPCODE_D8
			b CBOPCODE_D9
			b CBOPCODE_DA
			b CBOPCODE_DB
			b CBOPCODE_DC
			b CBOPCODE_DD
			b CBOPCODE_DE
			b CBOPCODE_DF
			b CBOPCODE_E0
			b CBOPCODE_E1
			b CBOPCODE_E2
			b CBOPCODE_E3
			b CBOPCODE_E4
			b CBOPCODE_E5
			b CBOPCODE_E6
			b CBOPCODE_E7
			b CBOPCODE_E8
			b CBOPCODE_E9
			b CBOPCODE_EA
			b CBOPCODE_EB
			b CBOPCODE_EC
			b CBOPCODE_ED
			b CBOPCODE_EE
			b CBOPCODE_EF
			b CBOPCODE_F0
			b CBOPCODE_F1
			b CBOPCODE_F2
			b CBOPCODE_F3
			b CBOPCODE_F4
			b CBOPCODE_F5
			b CBOPCODE_F6
			b CBOPCODE_F7
			b CBOPCODE_F8
			b CBOPCODE_F9
			b CBOPCODE_FA
			b CBOPCODE_FB
			b CBOPCODE_FC
			b CBOPCODE_FD
			b CBOPCODE_FE
			b CBOPCODE_FF

CBOPCODE_00:		;@RLC B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flags
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry old bit 7 was set
	orrne r0,r0,#0x1			;@ Set bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_01:		;@RLC C
	mov r0,r9				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_02:		;@RLC D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_03:		;@RLC E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_04:		;@RLC H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_05:		;@RLC L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_06:		;@RLC (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	;@strb r0,[r3]				;@ Store back in mem as R3 still contains address of HL
	bl STOREMEM2
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_07:		;@RLC A
	mov r0,r8				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1			;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_08:		;@RRC B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	and r0,r0,#0x7F				;@ Mask back to byte and clear bit 7
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_09:		;@RRC C
	and r0,r9,#0xFF				;@ Get source value and mask
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_0A:		;@RRC D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_0B:		;@RRC E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	and r0,r0,#0x7F				;@ Mask back to byte and clear bit 7
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_0C:		;@RRC H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift left 1
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_0D:		;@RRC L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	and r0,r0,#0x7F				;@ Clear to byte and clear bit 7
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	cmp r0,#0				;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_0E:		;@RRC (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store back to mem as R3 still contains address of HL
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_0F:		;@RRC A
	and r0,r8,#0xFF				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift left 1
	orrcs r8,r8,#0x100			;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80			;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_10:		;@RL B
	mov r0,r9,lsr #8			;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_11:		;@RL C
	mov r0,r9				;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_12:		;@RL D
	mov r0,r9,lsr #24			;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_13:		;@RL E
	mov r0,r9,lsr #16			;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_14:		;@RL H
	mov r0,r8,lsr #24			;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_15:		;@RL L
	mov r0,r8,lsr #16			;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_16:		;@RL (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem, R3 still contain HL address
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_17:		;@RL A
	mov r0,r8				;@ Get source value
	tst r8,#0x100				;@ Test current carry flag
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	orrne r0,r0,#1				;@ Set bit 0 if carry was set
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_18:		;@RR B
	mov r0,r9,lsr #8			;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R3
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	and r0,r0,#0x7F				;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_19:		;@RR C
	and r0,r9,#0xFF				;@ Get source value and mask
	mov r3,r8,lsr #8			;@ Move old flags into R3
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_1A:		;@RR D
	mov r0,r9,lsr #24			;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_1B:		;@RR E
	mov r0,r9,lsr #16			;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	and r0,r0,#0x7F				;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_1C:		;@RR H
	mov r0,r8,lsr #24			;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_1D:		;@RR L
	mov r0,r8,lsr #16			;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	and r0,r0,#0x7F				;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_1E:		;@RR (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r2,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r2,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_1F:		;@RR A
	and r0,r8,#0xFF				;@ Get source value
	mov r3,r8,lsr #8			;@ Move old flags into R1
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift Right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry flag is shift cause ARM carry
	tst r3,#1 				;@ Test if old carry was set
	orrne r0,r0,#0x80			;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_20:		;@SLA B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_21:		;@SLA C
	mov r0,r9				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_22:		;@SLA D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_23:		;@SLA E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_24:		;@SLA H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_25:		;@SLA L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_26:		;@SLA (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_27:		;@SLA A
	mov r0,r8				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_28:		;@SRA B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_29:		;@SRA C
	mov r0,r9				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_2A:		;@SRA D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_2B:		;@SRA E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_2C:		;@SRA H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_2D:		;@SRA L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_2E:		;@SRA (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_2F:		;@SRA A
	mov r0,r8				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128				;@ Clear bit 7
	tst r0,#64				;@ Test bit 6
	orrne r0,r0,#0x80			;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF			;@ Mask back to byte
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_30:		;@SLL B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_31:		;@SLL C
	mov r0,r9				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_32:		;@SLL D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_33:		;@SLL E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_34:		;@SLL H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_35:		;@SLL L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_36:		;@SLL (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_37:		;@SLL A
	mov r0,r8				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	mov r0,r0,lsl #1			;@ Shift left 1
	tst r0,#256				;@ Test bit 8
	orrne r8,r8,#0x100			;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF				;@ Mask back to byte
	orr r0,r0,#1				;@ Insert 1 at end
	tst r0,#128				;@ Test S flag
	orrne r8,r8,#0x8000			;@ Set S flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_38:		;@SRL B
	mov r0,r9,lsr #8			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_39:		;@SRL C
	mov r0,r9				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_3A:		;@SRL D
	mov r0,r9,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_3B:		;@SRL E
	mov r0,r9,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_3C:		;@SRL H
	mov r0,r8,lsr #24			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_3D:		;@SRL L
	mov r0,r8,lsr #16			;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_3E:		;@SRL (HL)
	mov r1,r8,lsr #16			;@ Get value of register
	and r1,r1,r12				;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store to mem
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	mov r2,#15
b ENDOPCODES

CBOPCODE_3F:		;@SRL A
	mov r0,r8				;@ Get source value
	bic r8,r8,#0xFF00			;@ Clear all flag
	movs r0,r0,lsr #1			;@ Shift right 1
	orrcs r8,r8,#0x100			;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F			;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000			;@ Set Zero flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	adrl r2,Parity				;@ Get start of parity table
	ldrb r3,[r2,r0]				;@ Get parity value
	cmp r3,#0				;@ Test parity value
	orrne r8,r8,#0x400			;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0				;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_40:		;@BIT 0,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_41:		;@BIT 0,C
	mov r0,r9				;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_42:		;@BIT 0,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_43:		;@BIT 0,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_44:		;@BIT 0,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_45:		;@BIT 0,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_46:		;@BIT 0,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x01			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_47:		;@BIT 0,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_48:		;@BIT 1,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_49:		;@BIT 1,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_4A:		;@BIT 1,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_4B:		;@BIT 1,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_4C:		;@BIT 1,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_4D:		;@BIT 1,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_4E:		;@BIT 1,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x02			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_4F:		;@BIT 1,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_50:		;@BIT 2,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_51:		;@BIT 2,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_52:		;@BIT 2,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_53:		;@BIT 2,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_54:		;@BIT 2,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_55:		;@BIT 2,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_56:		;@BIT 2,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x04			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_57:		;@BIT 2,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_58:		;@BIT 3,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_59:		;@BIT 3,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_5A:		;@BIT 3,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_5B:		;@BIT 3,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_5C:		;@BIT 3,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_5D:		;@BIT 3,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_5E:		;@BIT 3,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x08			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_5F:		;@BIT 3,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_60:		;@BIT 4,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_61:		;@BIT 4,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_62:		;@BIT 4,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_63:		;@BIT 4,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_64:		;@BIT 4,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_65:		;@BIT 4,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_66:		;@BIT 4,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x10			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_67:		;@BIT 4,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_68:		;@BIT 5,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_69:		;@BIT 5,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_6A:		;@BIT 5,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_6B:		;@BIT 5,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_6C:		;@BIT 5,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_6D:		;@BIT 5,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_6E:		;@BIT 5,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x20			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_6F:		;@BIT 5,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_70:		;@BIT 6,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_71:		;@BIT 6,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_72:		;@BIT 6,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_73:		;@BIT 6,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_74:		;@BIT 6,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_75:		;@BIT 6,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_76:		;@BIT 6,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x40			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_77:		;@BIT 6,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_78:		;@BIT 7,B
	mov r0,r9,lsr #8			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_79:		;@BIT 7,C
	mov r0,r9			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_7A:		;@BIT 7,D
	mov r0,r9,lsr #24			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_7B:		;@BIT 7,E
	mov r0,r9,lsr #16			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_7C:		;@BIT 7,H
	mov r0,r8,lsr #24			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_7D:		;@BIT 7,L
	mov r0,r8,lsr #16			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_7E:		;@BIT 7,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	ands r1,r0,#0x80			;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000			;@Set S flag if bit was set
	orreq r8,r8,#0x4400			;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#12
b ENDOPCODES

CBOPCODE_7F:		;@BIT 7,A
	mov r0,r8			;@ Get source value
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#8
b ENDOPCODES

CBOPCODE_80:		;@RES 0,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_81:		;@RES 0,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_82:		;@RES 0,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_83:		;@RES 0,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_84:		;@RES 0,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_85:		;@RES 0,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_86:		;@RES 0,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_87:		;@RES 0,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x01			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_88:		;@RES 1,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_89:		;@RES 1,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_8A:		;@RES 1,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_8B:		;@RES 1,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_8C:		;@RES 1,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_8D:		;@RES 1,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_8E:		;@RES 1,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_8F:		;@RES 1,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x02			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_90:		;@RES 2,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_91:		;@RES 2,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_92:		;@RES 2,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_93:		;@RES 2,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_94:		;@RES 2,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_95:		;@RES 2,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_96:		;@RES 2,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_97:		;@RES 2,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x04			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_98:		;@RES 3,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_99:		;@RES 3,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_9A:		;@RES 3,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_9B:		;@RES 3,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_9C:		;@RES 3,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_9D:		;@RES 3,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_9E:		;@RES 3,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_9F:		;@RES 3,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x08			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A0:		;@RES 4,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A1:		;@RES 4,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A2:		;@RES 4,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A3:		;@RES 4,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A4:		;@RES 4,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A5:		;@RES 4,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A6:		;@RES 4,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_A7:		;@RES 4,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x10			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A8:		;@RES 5,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_A9:		;@RES 5,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_AA:		;@RES 5,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_AB:		;@RES 5,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_AC:		;@RES 5,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_AD:		;@RES 5,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_AE:		;@RES 5,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_AF:		;@RES 5,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x20			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B0:		;@RES 6,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B1:		;@RES 6,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B2:		;@RES 6,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B3:		;@RES 6,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B4:		;@RES 6,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B5:		;@RES 6,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B6:		;@RES 6,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_B7:		;@RES 6,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x40			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B8:		;@RES 7,B
	mov r0,r9,lsr #8			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_B9:		;@RES 7,C
	mov r0,r9			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_BA:		;@RES 7,D
	mov r0,r9,lsr #24			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_BB:		;@RES 7,E
	mov r0,r9,lsr #16			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_BC:		;@RES 7,H
	mov r0,r8,lsr #24			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_BD:		;@RES 7,L
	mov r0,r8,lsr #16			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_BE:		;@RES 7,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_BF:		;@RES 7,A
	mov r0,r8			;@ Get source value
	bic r0,r0,#0x80			;@ Reset Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C0:		;@SET 0,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C1:		;@SET 0,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C2:		;@SET 0,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C3:		;@SET 0,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C4:		;@SET 0,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C5:		;@SET 0,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C6:		;@SET 0,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_C7:		;@SET 0,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x01			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C8:		;@SET 1,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_C9:		;@SET 1,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_CA:		;@SET 1,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_CB:		;@SET 1,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_CC:		;@SET 1,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_CD:		;@SET 1,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_CE:		;@SET 1,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_CF:		;@SET 1,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x02			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D0:		;@SET 2,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D1:		;@SET 2,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D2:		;@SET 2,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D3:		;@SET 2,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D4:		;@SET 2,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D5:		;@SET 2,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D6:		;@SET 2,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_D7:		;@SET 2,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x04			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D8:		;@SET 3,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_D9:		;@SET 3,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_DA:		;@SET 3,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_DB:		;@SET 3,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_DC:		;@SET 3,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_DD:		;@SET 3,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_DE:		;@SET 3,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_DF:		;@SET 3,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x08			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E0:		;@SET 4,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E1:		;@SET 4,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E2:		;@SET 4,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E3:		;@SET 4,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E4:		;@SET 4,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E5:		;@SET 4,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E6:		;@SET 4,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_E7:		;@SET 4,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x10			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E8:		;@SET 5,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_E9:		;@SET 5,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_EA:		;@SET 5,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_EB:		;@SET 5,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_EC:		;@SET 5,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_ED:		;@SET 5,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_EE:		;@SET 5,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_EF:		;@SET 5,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x20			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F0:		;@SET 6,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F1:		;@SET 6,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F2:		;@SET 6,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F3:		;@SET 6,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F4:		;@SET 6,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F5:		;@SET 6,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F6:		;@SET 6,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_F7:		;@SET 6,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x40			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F8:		;@SET 7,B
	mov r0,r9,lsr #8			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_F9:		;@SET 7,C
	mov r0,r9			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_FA:		;@SET 7,D
	mov r0,r9,lsr #24			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_FB:		;@SET 7,E
	mov r0,r9,lsr #16			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_FC:		;@SET 7,H
	mov r0,r8,lsr #24			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_FD:		;@SET 7,L
	mov r0,r8,lsr #16			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

CBOPCODE_FE:		;@SET 7,(HL)
	mov r1,r8,lsr #16			;@ Get value of register
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2
	;@strb r0,[r3]				;@ Store value in memory
	mov r2,#15
b ENDOPCODES

CBOPCODE_FF:		;@SET 7,A
	mov r0,r8			;@ Get source value
	orr r0,r0,#0x80			;@ Set Bit
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDCODES:
	bl MEMFETCH
	add r1,r1,#1		;@R1 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r2,r5,#1
	and r2,r2,#127
	bic r5,r5,#127
	orr r5,r5,r2				;@ 4 Lines to increase r register!
;@	ldr r3,=rpointer
;@	ldr r2,[r3]    		;@These three lines store the opcode For debugging
;@	Str r0,[r2,#40]
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b DDOPCODE_00
			b DDOPCODE_01
			b DDOPCODE_02
			b DDOPCODE_03
			b DDOPCODE_04
			b DDOPCODE_05
			b DDOPCODE_06
			b DDOPCODE_07
			b DDOPCODE_08
			b DDOPCODE_09
			b DDOPCODE_0A
			b DDOPCODE_0B
			b DDOPCODE_0C
			b DDOPCODE_0D
			b DDOPCODE_0E
			b DDOPCODE_0F
			b DDOPCODE_10
			b DDOPCODE_11
			b DDOPCODE_12
			b DDOPCODE_13
			b DDOPCODE_14
			b DDOPCODE_15
			b DDOPCODE_16
			b DDOPCODE_17
			b DDOPCODE_18
			b DDOPCODE_19
			b DDOPCODE_1A
			b DDOPCODE_1B
			b DDOPCODE_1C
			b DDOPCODE_1D
			b DDOPCODE_1E
			b DDOPCODE_1F
			b DDOPCODE_20
			b DDOPCODE_21
			b DDOPCODE_22
			b DDOPCODE_23
			b DDOPCODE_24
			b DDOPCODE_25
			b DDOPCODE_26
			b DDOPCODE_27
			b DDOPCODE_28
			b DDOPCODE_29
			b DDOPCODE_2A
			b DDOPCODE_2B
			b DDOPCODE_2C
			b DDOPCODE_2D
			b DDOPCODE_2E
			b DDOPCODE_2F
			b DDOPCODE_30
			b DDOPCODE_31
			b DDOPCODE_32
			b DDOPCODE_33
			b DDOPCODE_34
			b DDOPCODE_35
			b DDOPCODE_36
			b DDOPCODE_37
			b DDOPCODE_38
			b DDOPCODE_39
			b DDOPCODE_3A
			b DDOPCODE_3B
			b DDOPCODE_3C
			b DDOPCODE_3D
			b DDOPCODE_3E
			b DDOPCODE_3F
			b DDOPCODE_40
			b DDOPCODE_41
			b DDOPCODE_42
			b DDOPCODE_43
			b DDOPCODE_44
			b DDOPCODE_45
			b DDOPCODE_46
			b DDOPCODE_47
			b DDOPCODE_48
			b DDOPCODE_49
			b DDOPCODE_4A
			b DDOPCODE_4B
			b DDOPCODE_4C
			b DDOPCODE_4D
			b DDOPCODE_4E
			b DDOPCODE_4F
			b DDOPCODE_50
			b DDOPCODE_51
			b DDOPCODE_52
			b DDOPCODE_53
			b DDOPCODE_54
			b DDOPCODE_55
			b DDOPCODE_56
			b DDOPCODE_57
			b DDOPCODE_58
			b DDOPCODE_59
			b DDOPCODE_5A
			b DDOPCODE_5B
			b DDOPCODE_5C
			b DDOPCODE_5D
			b DDOPCODE_5E
			b DDOPCODE_5F
			b DDOPCODE_60
			b DDOPCODE_61
			b DDOPCODE_62
			b DDOPCODE_63
			b DDOPCODE_64
			b DDOPCODE_65
			b DDOPCODE_66
			b DDOPCODE_67
			b DDOPCODE_68
			b DDOPCODE_69
			b DDOPCODE_6A
			b DDOPCODE_6B
			b DDOPCODE_6C
			b DDOPCODE_6D
			b DDOPCODE_6E
			b DDOPCODE_6F
			b DDOPCODE_70
			b DDOPCODE_71
			b DDOPCODE_72
			b DDOPCODE_73
			b DDOPCODE_74
			b DDOPCODE_75
			b DDOPCODE_76
			b DDOPCODE_77
			b DDOPCODE_78
			b DDOPCODE_79
			b DDOPCODE_7A
			b DDOPCODE_7B
			b DDOPCODE_7C
			b DDOPCODE_7D
			b DDOPCODE_7E
			b DDOPCODE_7F
			b DDOPCODE_80
			b DDOPCODE_81
			b DDOPCODE_82
			b DDOPCODE_83
			b DDOPCODE_84
			b DDOPCODE_85
			b DDOPCODE_86
			b DDOPCODE_87
			b DDOPCODE_88
			b DDOPCODE_89
			b DDOPCODE_8A
			b DDOPCODE_8B
			b DDOPCODE_8C
			b DDOPCODE_8D
			b DDOPCODE_8E
			b DDOPCODE_8F
			b DDOPCODE_90
			b DDOPCODE_91
			b DDOPCODE_92
			b DDOPCODE_93
			b DDOPCODE_94
			b DDOPCODE_95
			b DDOPCODE_96
			b DDOPCODE_97
			b DDOPCODE_98
			b DDOPCODE_99
			b DDOPCODE_9A
			b DDOPCODE_9B
			b DDOPCODE_9C
			b DDOPCODE_9D
			b DDOPCODE_9E
			b DDOPCODE_9F
			b DDOPCODE_A0
			b DDOPCODE_A1
			b DDOPCODE_A2
			b DDOPCODE_A3
			b DDOPCODE_A4
			b DDOPCODE_A5
			b DDOPCODE_A6
			b DDOPCODE_A7
			b DDOPCODE_A8
			b DDOPCODE_A9
			b DDOPCODE_AA
			b DDOPCODE_AB
			b DDOPCODE_AC
			b DDOPCODE_AD
			b DDOPCODE_AE
			b DDOPCODE_AF
			b DDOPCODE_B0
			b DDOPCODE_B1
			b DDOPCODE_B2
			b DDOPCODE_B3
			b DDOPCODE_B4
			b DDOPCODE_B5
			b DDOPCODE_B6
			b DDOPCODE_B7
			b DDOPCODE_B8
			b DDOPCODE_B9
			b DDOPCODE_BA
			b DDOPCODE_BB
			b DDOPCODE_BC
			b DDOPCODE_BD
			b DDOPCODE_BE
			b DDOPCODE_BF
			b DDOPCODE_C0
			b DDOPCODE_C1
			b DDOPCODE_C2
			b DDOPCODE_C3
			b DDOPCODE_C4
			b DDOPCODE_C5
			b DDOPCODE_C6
			b DDOPCODE_C7
			b DDOPCODE_C8
			b DDOPCODE_C9
			b DDOPCODE_CA
			b DDOPCODE_CB
			b DDOPCODE_CC
			b DDOPCODE_CD
			b DDOPCODE_CE
			b DDOPCODE_CF
			b DDOPCODE_D0
			b DDOPCODE_D1
			b DDOPCODE_D2
			b DDOPCODE_D3
			b DDOPCODE_D4
			b DDOPCODE_D5
			b DDOPCODE_D6
			b DDOPCODE_D7
			b DDOPCODE_D8
			b DDOPCODE_D9
			b DDOPCODE_DA
			b DDOPCODE_DB
			b DDOPCODE_DC
			b DDOPCODE_DD
			b DDOPCODE_DE
			b DDOPCODE_DF
			b DDOPCODE_E0
			b DDOPCODE_E1
			b DDOPCODE_E2
			b DDOPCODE_E3
			b DDOPCODE_E4
			b DDOPCODE_E5
			b DDOPCODE_E6
			b DDOPCODE_E7
			b DDOPCODE_E8
			b DDOPCODE_E9
			b DDOPCODE_EA
			b DDOPCODE_EB
			b DDOPCODE_EC
			b DDOPCODE_ED
			b DDOPCODE_EE
			b DDOPCODE_EF
			b DDOPCODE_F0
			b DDOPCODE_F1
			b DDOPCODE_F2
			b DDOPCODE_F3
			b DDOPCODE_F4
			b DDOPCODE_F5
			b DDOPCODE_F6
			b DDOPCODE_F7
			b DDOPCODE_F8
			b DDOPCODE_F9
			b DDOPCODE_FA
			b DDOPCODE_FB
			b DDOPCODE_FC
			b DDOPCODE_FD
			b DDOPCODE_FE
			b DDOPCODE_FF

DDOPCODE_00:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_01:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_02:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_03:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_04:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_05:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_06:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_07:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_08:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_09:		;@ADD IX,BC
	and r0,r9,r12			;@ Maskto 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r10,r12			;@ Mask off destination reg to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r10,r12			;@ Get destination register
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,r12			;@ Clear target short To 0
	orr r10,r10,r2			;@ Place value on target register
	mov r2,#15
b ENDOPCODES

DDOPCODE_0A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_0B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_0C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_0D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_0E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_0F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_10:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_11:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_12:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_13:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_14:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_15:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_16:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_17:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_18:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_19:		;@ADD IX,DE
	mov r0,r9,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r10,r12			;@ Mask off destination reg to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r10,r12			;@ Get destination register
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,r12			;@ Clear target short To 0
	orr r10,r10,r2			;@ Place value on target register
	mov r2,#15
b ENDOPCODES

DDOPCODE_1A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_1B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_1C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_1D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_1E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_1F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_20:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_21:		;@LD IX,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r10,r10,r12			;@ Clear target byte To 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#14
b ENDOPCODES

DDOPCODE_22:		;@LD (nn),IX
;@	mov r0,r10			;@ Get source value
	and r0,r10,r12			;@ Mask value to a 16 bit number
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

DDOPCODE_23:		;@INC IX
	add r0,r10,#1			;@ Increase source by 1
	and r0,r0,r12			;@ Mask to 16 bits
	bic r10,r10,r12			;@ Clear target byte To 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#10
b ENDOPCODES

DDOPCODE_24:		;@INC IXH
	mov r0,r10,lsr #8		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibble
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_25:		;@DEC IXH
	mov r0,r10,lsr #8		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibble
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_26:		;@LD IXH,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

DDOPCODE_27:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_28:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_29:		;@ADD IX,IX
	and r0,r10,r12			;@ Get source value and mask to 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r0,r12			;@ Adjust to low 'nibble'
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r1
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,r12			;@ Clear target short To 0
	orr r10,r10,r2			;@ Place value on target register
	mov r2,#15
b ENDOPCODES

DDOPCODE_2A:		;@LD IX,(nn)
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT2		;@ Get address
	add r2,r2,#2			;@ Increment PC
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	bic r10,r10,r12			;@ Clear target byte To 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#20
b ENDOPCODES

DDOPCODE_2B:		;@DEC IX
	sub r0,r10,#1			;@ Decrease by 1
	and r0,r0,r12			;@ Mask to 16 bits
	bic r10,r10,r12			;@ Clear target byte To 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#10
b ENDOPCODES

DDOPCODE_2C:		;@INC IXL
	mov r0,r10			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibble
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_2D:		;@DEC IXL
	mov r0,r10			;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibble
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_2E:		;@LD IXL,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#11
b ENDOPCODES

DDOPCODE_2F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_30:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_31:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_32:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_33:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_34:		;@INC (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMREAD	 		;@ load value from memory
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3] 			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

DDOPCODE_35:		;@DEC (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMREAD	 		;@ Load value from memory
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bl STOREMEM2
	;@strb r0,[r3] 			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

DDOPCODE_36:		;@LD (IX+d),n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH				;@ Get displacement
	mov r4,r0
	add r1,r1,#1			;@ Increase PC
	bl MEMFETCH				;@ Get value
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r2,r10,r12			;@ Get masked valued of register
	add r1,r2,r4			;@ Add displacement
	tst r4,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_37:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_38:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_39:		;@ADD IX,SP
	mov r0,r7,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r10,r12			;@ Mask off destination reg to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r10,r12			;@ Mask off to destination reg to 16 bits
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,r12			;@ Clear target short To 0
	orr r10,r10,r2			;@ Place value on target register
	mov r2,#15
b ENDOPCODES

DDOPCODE_3A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_3B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_3C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_3D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_3E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_3F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_40:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_41:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_42:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_43:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_44:		;@LD B,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_45:		;@LD B,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_46:		;@LD B,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_47:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_48:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_49:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_4A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_4B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_4C:		;@LD C,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_4D:		;@LD C,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_4E:		;@LD C,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_4F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_50:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_51:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_52:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_53:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_54:		;@LD D,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_55:		;@LD D,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_56:		;@LD D,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_57:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_58:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_59:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_5A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_5B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_5C:		;@LD E,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_5D:		;@LD E,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_5E:		;@LD E,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_5F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_60:		;@LD IXH,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_61:		;@LD IXH,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_62:		;@LD IXH,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_63:		;@LD IXH,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_64:		;@LD IXH,IXH
	mov r2,#8
b ENDOPCODES

DDOPCODE_65:		;@LD IXH,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_66:		;@LD H,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_67:		;@LD IXH,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x0000FF00		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_68:		;@LD IXL,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_69:		;@LD IXL,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_6A:		;@LD IXL,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_6B:		;@LD IXL,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_6C:		;@LD IXL,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_6D:		;@LD IXL,IXL
	mov r2,#8
b ENDOPCODES

DDOPCODE_6E:		;@LD L,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_6F:		;@LD IXL,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x000000FF		;@ Clear target byte to 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_70:		;@LD (IX+d),B
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_71:		;@LD (IX+d),C
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_72:		;@LD (IX+d),D
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #24		;@ Get source value
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_73:		;@LD (IX+d),E
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_74:		;@LD (IX+d),H
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r8,lsr #24			;@ Get source value
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_75:		;@LD (IX+d),L
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_76:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_77:		;@LD (IX+d),A
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r10			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask to 16 bit
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

DDOPCODE_78:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_79:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_7A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_7B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_7C:		;@LD A,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_7D:		;@LD A,IXL
	and r0,r10,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_7E:		;@LD A,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	add r1,r10,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_7F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_80:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_81:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_82:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_83:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_84:		;@ADD A,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128				;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_85:		;@ADD A,IXL
	and r0,r10,#0xFF		;@ Mask off source to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_86:		;@ADD A,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

DDOPCODE_87:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_88:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_89:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_8A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_8B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_8C:		;@ADC A,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128				;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_8D:		;@ADC A,IXL
	and r0,r10,#0xFF		;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_8E:		;@ADC A,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

DDOPCODE_8F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_90:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_91:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_92:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_93:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_94:		;@SUB A,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_95:		;@SUB A,IXL
	and r0,r10,#0xFF		;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_96:		;@SUB A,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

DDOPCODE_97:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_98:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_99:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_9A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_9B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_9C:		;@SBC A,IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_9D:		;@SBC A,IXL
	and r0,r10,#0xFF		;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_9E:		;@SBC A,(IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

DDOPCODE_9F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A4:		;@AND IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_A5:		;@AND IXL
	mov r0,r10			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_A6:		;@AND (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_A7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_A9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_AA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_AB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_AC:		;@XOR IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_AD:		;@XOR IXL
	mov r0,r10			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_AE:		;@XOR (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_AF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B4:		;@OR IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_B5:		;@OR IXL
	mov r0,r10			;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

DDOPCODE_B6:		;@OR (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

DDOPCODE_B7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_B9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_BA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_BB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_BC:		;@CP IXH
	mov r0,r10,lsr #8		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_BD:		;@CP IXL
	and r0,r10,#0xFF		;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

DDOPCODE_BE:		;@CP (IX+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r1,r10,r12			;@ Get masked valued of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

DDOPCODE_BF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_C9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_CA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_CB:		;@DDCB
	b CBXCODES
b ENDOPCODES

DDOPCODE_CC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_CD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_CE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_CF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_D9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_DF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E1:		;@POP IX
	mov r1,r7,lsr #16		;@Put SP in R1
	bl MEMREADSHORT
	add r1,r1,#2			;@Increase SP
	and r7,r7,r12			;@CLear old SP value
	add r7,r7,r1,lsl #16		;@Put SP in Reg 7
	bic r10,r10,r12			;@ Clear target byte To 0
	orr r10,r10,r0			;@ Place value on target register
	mov r2,#14
b ENDOPCODES

DDOPCODE_E2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E3:		;@EX (SP),IX
	mov r2,r7,lsr #16		;@ Get value of SP
	bl MEMREADSHORT2		;@ Get value in SP location into R1
	and r0,r10,r12			;@ Mask source value to a 16 bit number
	bic r10,r10,r12			;@ Clear source byte To 0
	orr r10,r10,r1			;@ Place value on target register
	mov r1,r3
	bl MEMSTORESHORT
	;@strb r0,[r3] 			;@ store low byte in memory
	;@mov r0,r0,lsr #8
	;@strb r0,[r3,#1]			;@ Store high byte of PC
	mov r2,#23
b ENDOPCODES

DDOPCODE_E4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E5:		;@PUSH IX
	and r0,r10,r12			;@ Maskto 16 bits
	mov r1,r7,lsr #16		;@Put SP into R1
	sub r1,r1,#2			;@Decrease stack by 2
	and r1,r1,r12			;@Mask to 16 bits
	and r7,r7,r12			;@Clear old SP
	orr r7,r7,r1,lsl #16	;@Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#15
b ENDOPCODES

DDOPCODE_E6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_E9:		;@JP (IX)
	and r0,r10,r12			;@Move IX into R0
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
	mov r2,#8
b ENDOPCODES

DDOPCODE_EA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_EB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_EC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_ED:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_EE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_EF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_F9:		;@LD SP,IX
	and r0,r10,r12			;@ Mask value to a 16 bit number
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

DDOPCODE_FA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_FB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_FC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_FD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_FE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

DDOPCODE_FF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDCODES:
	bl MEMFETCH
	add r1,r1,#1		;@R0 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r2,r5,#1
	and r2,r2,#127
	bic r5,r5,#127
	orr r5,r5,r2				;@ 4 Lines to increase r register!
;@	ldr r3,=rpointer
;@	ldr r2,[r3]    		;@These three lines store the opcode For debugging
;@	Str r0,[r2,#40]
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b FDOPCODE_00
			b FDOPCODE_01
			b FDOPCODE_02
			b FDOPCODE_03
			b FDOPCODE_04
			b FDOPCODE_05
			b FDOPCODE_06
			b FDOPCODE_07
			b FDOPCODE_08
			b FDOPCODE_09
			b FDOPCODE_0A
			b FDOPCODE_0B
			b FDOPCODE_0C
			b FDOPCODE_0D
			b FDOPCODE_0E
			b FDOPCODE_0F
			b FDOPCODE_10
			b FDOPCODE_11
			b FDOPCODE_12
			b FDOPCODE_13
			b FDOPCODE_14
			b FDOPCODE_15
			b FDOPCODE_16
			b FDOPCODE_17
			b FDOPCODE_18
			b FDOPCODE_19
			b FDOPCODE_1A
			b FDOPCODE_1B
			b FDOPCODE_1C
			b FDOPCODE_1D
			b FDOPCODE_1E
			b FDOPCODE_1F
			b FDOPCODE_20
			b FDOPCODE_21
			b FDOPCODE_22
			b FDOPCODE_23
			b FDOPCODE_24
			b FDOPCODE_25
			b FDOPCODE_26
			b FDOPCODE_27
			b FDOPCODE_28
			b FDOPCODE_29
			b FDOPCODE_2A
			b FDOPCODE_2B
			b FDOPCODE_2C
			b FDOPCODE_2D
			b FDOPCODE_2E
			b FDOPCODE_2F
			b FDOPCODE_30
			b FDOPCODE_31
			b FDOPCODE_32
			b FDOPCODE_33
			b FDOPCODE_34
			b FDOPCODE_35
			b FDOPCODE_36
			b FDOPCODE_37
			b FDOPCODE_38
			b FDOPCODE_39
			b FDOPCODE_3A
			b FDOPCODE_3B
			b FDOPCODE_3C
			b FDOPCODE_3D
			b FDOPCODE_3E
			b FDOPCODE_3F
			b FDOPCODE_40
			b FDOPCODE_41
			b FDOPCODE_42
			b FDOPCODE_43
			b FDOPCODE_44
			b FDOPCODE_45
			b FDOPCODE_46
			b FDOPCODE_47
			b FDOPCODE_48
			b FDOPCODE_49
			b FDOPCODE_4A
			b FDOPCODE_4B
			b FDOPCODE_4C
			b FDOPCODE_4D
			b FDOPCODE_4E
			b FDOPCODE_4F
			b FDOPCODE_50
			b FDOPCODE_51
			b FDOPCODE_52
			b FDOPCODE_53
			b FDOPCODE_54
			b FDOPCODE_55
			b FDOPCODE_56
			b FDOPCODE_57
			b FDOPCODE_58
			b FDOPCODE_59
			b FDOPCODE_5A
			b FDOPCODE_5B
			b FDOPCODE_5C
			b FDOPCODE_5D
			b FDOPCODE_5E
			b FDOPCODE_5F
			b FDOPCODE_60
			b FDOPCODE_61
			b FDOPCODE_62
			b FDOPCODE_63
			b FDOPCODE_64
			b FDOPCODE_65
			b FDOPCODE_66
			b FDOPCODE_67
			b FDOPCODE_68
			b FDOPCODE_69
			b FDOPCODE_6A
			b FDOPCODE_6B
			b FDOPCODE_6C
			b FDOPCODE_6D
			b FDOPCODE_6E
			b FDOPCODE_6F
			b FDOPCODE_70
			b FDOPCODE_71
			b FDOPCODE_72
			b FDOPCODE_73
			b FDOPCODE_74
			b FDOPCODE_75
			b FDOPCODE_76
			b FDOPCODE_77
			b FDOPCODE_78
			b FDOPCODE_79
			b FDOPCODE_7A
			b FDOPCODE_7B
			b FDOPCODE_7C
			b FDOPCODE_7D
			b FDOPCODE_7E
			b FDOPCODE_7F
			b FDOPCODE_80
			b FDOPCODE_81
			b FDOPCODE_82
			b FDOPCODE_83
			b FDOPCODE_84
			b FDOPCODE_85
			b FDOPCODE_86
			b FDOPCODE_87
			b FDOPCODE_88
			b FDOPCODE_89
			b FDOPCODE_8A
			b FDOPCODE_8B
			b FDOPCODE_8C
			b FDOPCODE_8D
			b FDOPCODE_8E
			b FDOPCODE_8F
			b FDOPCODE_90
			b FDOPCODE_91
			b FDOPCODE_92
			b FDOPCODE_93
			b FDOPCODE_94
			b FDOPCODE_95
			b FDOPCODE_96
			b FDOPCODE_97
			b FDOPCODE_98
			b FDOPCODE_99
			b FDOPCODE_9A
			b FDOPCODE_9B
			b FDOPCODE_9C
			b FDOPCODE_9D
			b FDOPCODE_9E
			b FDOPCODE_9F
			b FDOPCODE_A0
			b FDOPCODE_A1
			b FDOPCODE_A2
			b FDOPCODE_A3
			b FDOPCODE_A4
			b FDOPCODE_A5
			b FDOPCODE_A6
			b FDOPCODE_A7
			b FDOPCODE_A8
			b FDOPCODE_A9
			b FDOPCODE_AA
			b FDOPCODE_AB
			b FDOPCODE_AC
			b FDOPCODE_AD
			b FDOPCODE_AE
			b FDOPCODE_AF
			b FDOPCODE_B0
			b FDOPCODE_B1
			b FDOPCODE_B2
			b FDOPCODE_B3
			b FDOPCODE_B4
			b FDOPCODE_B5
			b FDOPCODE_B6
			b FDOPCODE_B7
			b FDOPCODE_B8
			b FDOPCODE_B9
			b FDOPCODE_BA
			b FDOPCODE_BB
			b FDOPCODE_BC
			b FDOPCODE_BD
			b FDOPCODE_BE
			b FDOPCODE_BF
			b FDOPCODE_C0
			b FDOPCODE_C1
			b FDOPCODE_C2
			b FDOPCODE_C3
			b FDOPCODE_C4
			b FDOPCODE_C5
			b FDOPCODE_C6
			b FDOPCODE_C7
			b FDOPCODE_C8
			b FDOPCODE_C9
			b FDOPCODE_CA
			b FDOPCODE_CB
			b FDOPCODE_CC
			b FDOPCODE_CD
			b FDOPCODE_CE
			b FDOPCODE_CF
			b FDOPCODE_D0
			b FDOPCODE_D1
			b FDOPCODE_D2
			b FDOPCODE_D3
			b FDOPCODE_D4
			b FDOPCODE_D5
			b FDOPCODE_D6
			b FDOPCODE_D7
			b FDOPCODE_D8
			b FDOPCODE_D9
			b FDOPCODE_DA
			b FDOPCODE_DB
			b FDOPCODE_DC
			b FDOPCODE_DD
			b FDOPCODE_DE
			b FDOPCODE_DF
			b FDOPCODE_E0
			b FDOPCODE_E1
			b FDOPCODE_E2
			b FDOPCODE_E3
			b FDOPCODE_E4
			b FDOPCODE_E5
			b FDOPCODE_E6
			b FDOPCODE_E7
			b FDOPCODE_E8
			b FDOPCODE_E9
			b FDOPCODE_EA
			b FDOPCODE_EB
			b FDOPCODE_EC
			b FDOPCODE_ED
			b FDOPCODE_EE
			b FDOPCODE_EF
			b FDOPCODE_F0
			b FDOPCODE_F1
			b FDOPCODE_F2
			b FDOPCODE_F3
			b FDOPCODE_F4
			b FDOPCODE_F5
			b FDOPCODE_F6
			b FDOPCODE_F7
			b FDOPCODE_F8
			b FDOPCODE_F9
			b FDOPCODE_FA
			b FDOPCODE_FB
			b FDOPCODE_FC
			b FDOPCODE_FD
			b FDOPCODE_FE
			b FDOPCODE_FF

FDOPCODE_00:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_01:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_02:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_03:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_04:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_05:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_06:		;@ILL
;@ Illegal Opcode
	sub r1,r1,#1			;@ Decrement PC to go to normal 06 opcode
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value

	sub r2,r5,#1
	and r2,r2,#127
	bic r5,r5,#127
	orr r5,r5,r2				;@ 4 Lines to decrease r register!

	mov r2,#4
b ENDOPCODES

FDOPCODE_07:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_08:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_09:		;@ADD IY,BC
	and r0,r9,r12			;@ Maskto 16 bits
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r10,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r10,lsr #16		;@ Get destination register
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r10,r10,r12			;@ Clear target short to 0
	orr r10,r10,r2,lsl #16		;@ Place value on target register
	mov r2,#15
b ENDOPCODES

FDOPCODE_0A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_0B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_0C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_0D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_0E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_0F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_10:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_11:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_12:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_13:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_14:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_15:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_16:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_17:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_18:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_19:		;@ADD IY,DE
	mov r0,r9,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r10,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r10,lsr #16		;@ Get destination register
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r10,r10,r12			;@ Clear target short to 0
	orr r10,r10,r2,lsl #16		;@ Place value on target register
	mov r2,#15
b ENDOPCODES

FDOPCODE_1A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_1B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_1C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_1D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_1E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_1F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_20:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_21:		;@LD IY,nn
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	and r10,r10,r12			;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#14
b ENDOPCODES

FDOPCODE_22:		;@LD (nn),IY
	mov r0,r10,lsr #16		;@ Get source value
	and r2,r7,r12			;@ Mask PC register
	add r1,r2,#2			;@ Store PC + 2 in R1
	and r1,r1,r12			;@ Mask new PC to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store incremented value
	bl MEMFETCHSHORT2		;@ Get memory location into R1
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#20
b ENDOPCODES

FDOPCODE_23:		;@INC IY
	mov r0,r10,lsr #16		;@ Get source value
	add r0,r0,#1			;@ Increase by 1
	and r10,r10,r12			;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

FDOPCODE_24:		;@INC IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_25:		;@DEC IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_26:		;@LD IYH,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

FDOPCODE_27:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_28:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_29:		;@ADD IY,IY
	mov r0,r10,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	and r1,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r1
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r2,r0,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r10,r10,r12			;@ Clear target short to 0
	orr r10,r10,r2,lsl #16		;@ Place value on target register
	mov r2,#15
b ENDOPCODES

FDOPCODE_2A:		;@LD IY,(nn)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCHSHORT			;@ Get address
	add r1,r1,#2			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r0			;@ Put address to load into R1
	bl MEMREADSHORT			;@ Load 16 bit value from memory
	and r10,r10,r12			;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#20
b ENDOPCODES

FDOPCODE_2B:		;@DEC IY
	mov r0,r10,lsr #16		;@ Get source value
	sub r0,r0,#1			;@ Decrease by 1
	and r10,r10,r12			;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

FDOPCODE_2C:		;@INC IYL
	mov r0,r10,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_2D:		;@DEC IYL
	mov r0,r10,lsr #16		;@ Get source value
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0			;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_2E:		;@LD IYL,n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#11
b ENDOPCODES

FDOPCODE_2F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_30:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_31:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_32:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_33:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_34:		;@INC (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMREAD	 		;@ load value from memory
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#127			;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	and r2,r0,#0xF			;@ Move R0 to R2 to test half carry and mask lower nibbl
	add r2,r2,#1			;@ add 1
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	add r0,r0,#1			;@ Increase by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2
	;@strb r0,[r3] 			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

FDOPCODE_35:		;@DEC (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMREAD	 			;@load value from memory
	bic r8,r8,#0xFE00		;@ Clear flags
	cmp r0,#128				;@ Test for P flag
	orreq r8,r8,#0x400		;@ Set P flag if necessary
	mov r2,r0				;@ Move R0 to R2 to test half carry
	and r2,r2,#0xF			;@ Mask lower nibbl
	sub r2,r2,#1			;@ sub 1
	tst r2,#16				;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	sub r0,r0,#1			;@ Decrease by 1
	ands r0,r0,#255			;@ Mask to 8 bit
	orreq r8,r8,#0x4000		;@ Set Z flag if 0
	tst r0,#128				;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32				;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8				;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N flag
	bl STOREMEM2
	;@strb r0,[r3] 			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

FDOPCODE_36:		;@LD (IY+d),n
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH				;@ Get displacement
	mov r4,r0
	add r1,r1,#1			;@ Increase PC
	bl MEMFETCH				;@ Get value
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r2,r10,lsr #16			;@ Get value of register
	add r1,r2,r4			;@ Add displacement
	tst r4,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_37:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_38:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_39:		;@ADD IY,SP
	mov r0,r7,lsr #16		;@ Get source value
	bic r12,r12,#0xF000		;@ Adjust R12 mask to 0xFFF
	mov r1,r10,lsr #16		;@ Get destination register
	and r1,r1,r12			;@ Mask off to a low nibble
	and r2,r0,r12
	orr r12,r12,#0xF000		;@ restore R12 mask to 0xFFFF
	bic r8,r8,#0x3B00		;@ Clear C,N,3,H,5 flags
	add r2,r1,r2
	tst r2,#4096			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	mov r2,r10,lsr #16		;@ Get destination register
	add r2,r2,r0			;@ Perform addition
	tst r2,#65536			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	and r2,r2,r12			;@ Mask back to 16 bits and set flags
	tst r2,#8192			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#2048			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	and r10,r10,r12			;@ Clear target short to 0
	orr r10,r10,r2,lsl #16		;@ Place value on target register
	mov r2,#15
b ENDOPCODES

FDOPCODE_3A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_3B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_3C:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_3D:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_3E:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_3F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_40:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_41:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_42:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_43:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_44:		;@LD B,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_45:		;@LD B,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_46:		;@LD B,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_47:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_48:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_49:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_4A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_4B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_4C:		;@LD C,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_4D:		;@LD C,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_4E:		;@LD C,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_4F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_50:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_51:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_52:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_53:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_54:		;@LD D,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_55:		;@LD D,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_56:		;@LD D,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_57:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_58:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_59:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_5A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_5B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_5C:		;@LD E,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_5D:		;@LD E,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_5E:		;@LD E,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_5F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_60:		;@LD IYH,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_61:		;@LD IYH,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_62:		;@LD IYH,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_63:		;@LD IYH,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_64:		;@LD IYH,IYH
	mov r2,#8
b ENDOPCODES

FDOPCODE_65:		;@LD IYH,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_66:		;@LD H,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_67:		;@LD IYH,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0xFF000000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #24		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_68:		;@LD IYL,B
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_69:		;@LD IYL,C
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_6A:		;@LD IYL,D
	mov r0,r9,lsr #24		;@ Get source value
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_6B:		;@LD IYL,E
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_6C:		;@LD IYL,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_6D:		;@LD IYL,IYL
	mov r2,#8
b ENDOPCODES

FDOPCODE_6E:		;@LD L,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_6F:		;@LD IYL,A
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	bic r10,r10,#0x00FF0000		;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_70:		;@LD (IY+d),B
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #8		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_71:		;@LD (IY+d),C
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	and r0,r9,#0x000000FF		;@ Mask value to a single byte
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_72:		;@LD (IY+d),D
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #24		;@ Get source value
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_73:		;@LD (IY+d),E
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r9,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_74:		;@LD (IY+d),H
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r8,lsr #24		;@ Get source value
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_75:		;@LD (IY+d),L
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	mov r0,r8,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_76:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_77:		;@LD (IY+d),A
	and r2,r7,r12			;@ Mask PC register
	bl MEMFETCH2
	add r2,r2,#1			;@ Increment PC by 1
	and r2,r2,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r2			;@ Store new PC value
	and r0,r8,#0x000000FF		;@ Mask value to a single byte
	mov r2,r10,lsr #16		;@ Get value of register
	tst r1,#128			;@ Check sign for 2's displacemen
	add r1,r1,r2			;@ Add displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMSTORE 			;@ Store value in memory
	mov r2,#19
b ENDOPCODES

FDOPCODE_78:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_79:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_7A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_7B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_7C:		;@LD A,IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_7D:		;@LD A,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0x000000FF		;@ Mask value to a single byte
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_7E:		;@LD A,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH			;@ Load byte from address
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_7F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_80:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_81:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_82:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_83:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_84:		;@ADD A,IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_85:		;@ADD A,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_86:		;@ADD A,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	add r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

FDOPCODE_87:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_88:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_89:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_8A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_8B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_8C:		;@ADC A,IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_8D:		;@ADC A,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_8E:		;@ADC A,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	addne r1,r1,#1			;@ If set add 1
	add r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	addne r2,r2,#1			;@ If set add 1 to accumulator
	add r2,r2,r0			;@ Perform addition
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	mvn r0,r0			;@ perform NOT on original value
	and r0,r0,r12			;@ mask to 16 bits
	eor r0,r1,r0			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

FDOPCODE_8F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_90:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_91:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_92:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_93:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_94:		;@SUB A,IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_95:		;@SUB A,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_96:		;@SUB A,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@ load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r2,r0			;@ Perform addition
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

FDOPCODE_97:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_98:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_99:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_9A:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_9B:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_9C:		;@SBC A,IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_9D:		;@SBC A,IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_9E:		;@SBC A,(IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	tst r8,#0x100			;@ Test carry flag
	subne r1,r1,#1			;@ If set subtract 1
	sub r2,r1,r2
	mov r1,r8			;@ Store old flags in R1
	bic r8,r8,#0xFF00		;@ Clear all flags
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r2,r8,#255			;@ Mask off to a single byte
	tst r1,#0x100			;@ Test old carry flag
	subne r2,r2,#1			;@ If set subtract 1 from accumulator
	sub r2,r2,r0			;@ Perform substraction
	tst r2,#256			;@ Test Carry bit
	orrne r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r2			;@ Place value on target register
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

FDOPCODE_9F:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A4:		;@AND IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_A5:		;@AND IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_A6:		;@AND (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	ands r0,r0,r1			;@ Perform AND and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,#0x1000		;@ Set H flag
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_A7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_A9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_AA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_AB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_AC:		;@XOR IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_AD:		;@XOR IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_AE:		;@XOR (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	eor r0,r0,r1			;@ Perform XOR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_AF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B4:		;@OR IYH
	mov r0,r10,lsr #24		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_B5:		;@OR IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#8
b ENDOPCODES

FDOPCODE_B6:		;@OR (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	and r1,r8,#255			;@ Mask off to a single byte
	bic r8,r8,#0xFF			;@ Clear accumulator byte To 0
	bic r8,r8,#0xFF00		;@ Clear all flag
	orr r0,r0,r1			;@ Perform OR
	ands r0,r0,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r0,#128			;@ test for sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	adrl r2,Parity			;@ Get start of parity table
	ldrb r1,[r2,r0]			;@ Get parity value
	cmp r1,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#19
b ENDOPCODES

FDOPCODE_B7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_B9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_BA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_BB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_BC:		;@CP IYH
	mov r0,r10,lsr #24		;@ Get source value
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_BD:		;@CP IYL
	mov r0,r10,lsr #16		;@ Get source value
	and r0,r0,#0xFF			;@ Mask to single byte
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#8
b ENDOPCODES

FDOPCODE_BE:		;@CP (IY+d)
;@	and r1,r7,r12			;@ Mask PC register
	bl MEMFETCH
	add r1,r1,#1			;@ Increment PC
	and r1,r1,r12			;@ Mask to 16 bits
	bic r7,r7,r12			;@ Clear old PC value
	orr r7,r7,r1			;@ Store new PC value
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r0			;@ Add displacement
	tst r0,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	bl MEMREAD	 		;@load value from memory
	bic r8,r8,#0xFF00		;@ Clear all flags
	and r1,r8,#15			;@ Mask off to a low nibble of accumulator
	and r2,r0,#15
	sub r2,r1,r2
	tst r2,#16			;@ Test bit 4 flag
	orrne r8,r8,#0x1000		;@ Set H flag if set
	and r1,r8,#255			;@ Mask off accumulator to a single byte
	subs r2,r1,r0			;@ Compare values
	orrcc r8,r8,#0x100		;@ Set C flag
	ands r2,r2,#0xFF		;@ Mask back to byte and set flags
	orreq r8,r8,#0x4000		;@ Set Zero flag if need be
	tst r2,#128			;@ Test sign
	orrne r8,r8,#0x8000		;@ Set Sign flag if need be
	tst r2,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r2,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	orr r8,r8,#0x200		;@ Set N fla
	mov r1,r8			;@ load accumulator in R1
	eor r0,r0,r1			;@ Perform XOR between original value and accumulator
	eor r2,r2,r1			;@ Perform XOR between result and accumulator
	and r0,r0,r2			;@ And the resulting value
	tst r0,#128			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#19
b ENDOPCODES

FDOPCODE_BF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_C9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_CA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_CB:		;@FDCB
	b CBYCODES
b ENDOPCODES

FDOPCODE_CC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_CD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_CE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_CF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_D9:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_DF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E1:		;@POP IY
	mov r1,r7,lsr #16		;@Put SP in R1
	bl MEMREADSHORT
	add r1,r1,#2			;@Increase SP
	and r7,r7,r12			;@CLear old SP value
	add r7,r7,r1,lsl #16		;@Put SP in Reg 7
	and r10,r10,r12			;@ Clear target byte to 0
	orr r10,r10,r0,lsl #16		;@ Place value on target register
	mov r2,#14
b ENDOPCODES

FDOPCODE_E2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E3:		;@EX (SP),IY
	mov r2,r7,lsr #16		;@ Get value of SP
	bl MEMREADSHORT2		;@ Get value in SP location into R1
	mov r0,r10,lsr #16		;@ Get source value
	and r10,r10,r12			;@ Clear source byte to 0
	orr r10,r10,r1,lsl #16		;@ Place value on target register
	mov r1,r3
	bl MEMSTORESHORT
	;@strb r0,[r3] 			;@ store low byte in memory
	;@mov r0,r0,lsr #8
	;@strb r0,[r3,#1]			;@ Store high byte of PC
	;@mov r2,#23
b ENDOPCODES

FDOPCODE_E4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E5:		;@PUSH IY
	mov r0,r10,lsr #16		;@ Get source value
	mov r1,r7,lsr #16		;@ Put SP into R1
	sub r1,r1,#2			;@ Decrease stack by 2
	and r1,r1,r12			;@ Mask to 16 bits
	and r7,r7,r12			;@ Clear old SP
	orr r7,r7,r1,lsl #16		;@ Replace with new SP
	bl MEMSTORESHORT		;@ Store value in memory
	mov r2,#15
b ENDOPCODES

FDOPCODE_E6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_E9:		;@JP (IY)
	mov r0,r10,lsr #16		;@ Move IY into R0
	bic r7,r7,r12			;@ Clear old PC
	orr r7,r7,r0			;@ Add new PC
	mov r2,#8
b ENDOPCODES

FDOPCODE_EA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_EB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_EC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_ED:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_EE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_EF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F0:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F1:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F2:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F3:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F4:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F5:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F6:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F7:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F8:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_F9:		;@LD SP,IY
	mov r0,r10,lsr #16		;@ Get source value
	and r7,r7,r12			;@ Clear target byte to 0
	orr r7,r7,r0,lsl #16		;@ Place value on target register
	mov r2,#10
b ENDOPCODES

FDOPCODE_FA:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_FB:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_FC:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_FD:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_FE:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

FDOPCODE_FF:		;@ILL
;@ Illegal Opcode
	mov r2,#8
b ENDOPCODES

CBXCODES:
	bl MEMFETCH
	mov r2,r0			;@load displacement Value into r2
	add r1,r1,#1		;@load Next OP-CODE into r0
	bl MEMFETCH
	add r1,r1,#1		;@R1 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r1,r5,#1
	and r1,r1,#127
	bic r5,r5,#127
	orr r5,r5,r1				;@ 4 Lines to increase r register!
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b CBXOPCODE_00
			b CBXOPCODE_01
			b CBXOPCODE_02
			b CBXOPCODE_03
			b CBXOPCODE_04
			b CBXOPCODE_05
			b CBXOPCODE_06
			b CBXOPCODE_07
			b CBXOPCODE_08
			b CBXOPCODE_09
			b CBXOPCODE_0A
			b CBXOPCODE_0B
			b CBXOPCODE_0C
			b CBXOPCODE_0D
			b CBXOPCODE_0E
			b CBXOPCODE_0F
			b CBXOPCODE_10
			b CBXOPCODE_11
			b CBXOPCODE_12
			b CBXOPCODE_13
			b CBXOPCODE_14
			b CBXOPCODE_15
			b CBXOPCODE_16
			b CBXOPCODE_17
			b CBXOPCODE_18
			b CBXOPCODE_19
			b CBXOPCODE_1A
			b CBXOPCODE_1B
			b CBXOPCODE_1C
			b CBXOPCODE_1D
			b CBXOPCODE_1E
			b CBXOPCODE_1F
			b CBXOPCODE_20
			b CBXOPCODE_21
			b CBXOPCODE_22
			b CBXOPCODE_23
			b CBXOPCODE_24
			b CBXOPCODE_25
			b CBXOPCODE_26
			b CBXOPCODE_27
			b CBXOPCODE_28
			b CBXOPCODE_29
			b CBXOPCODE_2A
			b CBXOPCODE_2B
			b CBXOPCODE_2C
			b CBXOPCODE_2D
			b CBXOPCODE_2E
			b CBXOPCODE_2F
			b CBXOPCODE_30
			b CBXOPCODE_31
			b CBXOPCODE_32
			b CBXOPCODE_33
			b CBXOPCODE_34
			b CBXOPCODE_35
			b CBXOPCODE_36
			b CBXOPCODE_37
			b CBXOPCODE_38
			b CBXOPCODE_39
			b CBXOPCODE_3A
			b CBXOPCODE_3B
			b CBXOPCODE_3C
			b CBXOPCODE_3D
			b CBXOPCODE_3E
			b CBXOPCODE_3F
			b CBXOPCODE_40
			b CBXOPCODE_41
			b CBXOPCODE_42
			b CBXOPCODE_43
			b CBXOPCODE_44
			b CBXOPCODE_45
			b CBXOPCODE_46
			b CBXOPCODE_47
			b CBXOPCODE_48
			b CBXOPCODE_49
			b CBXOPCODE_4A
			b CBXOPCODE_4B
			b CBXOPCODE_4C
			b CBXOPCODE_4D
			b CBXOPCODE_4E
			b CBXOPCODE_4F
			b CBXOPCODE_50
			b CBXOPCODE_51
			b CBXOPCODE_52
			b CBXOPCODE_53
			b CBXOPCODE_54
			b CBXOPCODE_55
			b CBXOPCODE_56
			b CBXOPCODE_57
			b CBXOPCODE_58
			b CBXOPCODE_59
			b CBXOPCODE_5A
			b CBXOPCODE_5B
			b CBXOPCODE_5C
			b CBXOPCODE_5D
			b CBXOPCODE_5E
			b CBXOPCODE_5F
			b CBXOPCODE_60
			b CBXOPCODE_61
			b CBXOPCODE_62
			b CBXOPCODE_63
			b CBXOPCODE_64
			b CBXOPCODE_65
			b CBXOPCODE_66
			b CBXOPCODE_67
			b CBXOPCODE_68
			b CBXOPCODE_69
			b CBXOPCODE_6A
			b CBXOPCODE_6B
			b CBXOPCODE_6C
			b CBXOPCODE_6D
			b CBXOPCODE_6E
			b CBXOPCODE_6F
			b CBXOPCODE_70
			b CBXOPCODE_71
			b CBXOPCODE_72
			b CBXOPCODE_73
			b CBXOPCODE_74
			b CBXOPCODE_75
			b CBXOPCODE_76
			b CBXOPCODE_77
			b CBXOPCODE_78
			b CBXOPCODE_79
			b CBXOPCODE_7A
			b CBXOPCODE_7B
			b CBXOPCODE_7C
			b CBXOPCODE_7D
			b CBXOPCODE_7E
			b CBXOPCODE_7F
			b CBXOPCODE_80
			b CBXOPCODE_81
			b CBXOPCODE_82
			b CBXOPCODE_83
			b CBXOPCODE_84
			b CBXOPCODE_85
			b CBXOPCODE_86
			b CBXOPCODE_87
			b CBXOPCODE_88
			b CBXOPCODE_89
			b CBXOPCODE_8A
			b CBXOPCODE_8B
			b CBXOPCODE_8C
			b CBXOPCODE_8D
			b CBXOPCODE_8E
			b CBXOPCODE_8F
			b CBXOPCODE_90
			b CBXOPCODE_91
			b CBXOPCODE_92
			b CBXOPCODE_93
			b CBXOPCODE_94
			b CBXOPCODE_95
			b CBXOPCODE_96
			b CBXOPCODE_97
			b CBXOPCODE_98
			b CBXOPCODE_99
			b CBXOPCODE_9A
			b CBXOPCODE_9B
			b CBXOPCODE_9C
			b CBXOPCODE_9D
			b CBXOPCODE_9E
			b CBXOPCODE_9F
			b CBXOPCODE_A0
			b CBXOPCODE_A1
			b CBXOPCODE_A2
			b CBXOPCODE_A3
			b CBXOPCODE_A4
			b CBXOPCODE_A5
			b CBXOPCODE_A6
			b CBXOPCODE_A7
			b CBXOPCODE_A8
			b CBXOPCODE_A9
			b CBXOPCODE_AA
			b CBXOPCODE_AB
			b CBXOPCODE_AC
			b CBXOPCODE_AD
			b CBXOPCODE_AE
			b CBXOPCODE_AF
			b CBXOPCODE_B0
			b CBXOPCODE_B1
			b CBXOPCODE_B2
			b CBXOPCODE_B3
			b CBXOPCODE_B4
			b CBXOPCODE_B5
			b CBXOPCODE_B6
			b CBXOPCODE_B7
			b CBXOPCODE_B8
			b CBXOPCODE_B9
			b CBXOPCODE_BA
			b CBXOPCODE_BB
			b CBXOPCODE_BC
			b CBXOPCODE_BD
			b CBXOPCODE_BE
			b CBXOPCODE_BF
			b CBXOPCODE_C0
			b CBXOPCODE_C1
			b CBXOPCODE_C2
			b CBXOPCODE_C3
			b CBXOPCODE_C4
			b CBXOPCODE_C5
			b CBXOPCODE_C6
			b CBXOPCODE_C7
			b CBXOPCODE_C8
			b CBXOPCODE_C9
			b CBXOPCODE_CA
			b CBXOPCODE_CB
			b CBXOPCODE_CC
			b CBXOPCODE_CD
			b CBXOPCODE_CE
			b CBXOPCODE_CF
			b CBXOPCODE_D0
			b CBXOPCODE_D1
			b CBXOPCODE_D2
			b CBXOPCODE_D3
			b CBXOPCODE_D4
			b CBXOPCODE_D5
			b CBXOPCODE_D6
			b CBXOPCODE_D7
			b CBXOPCODE_D8
			b CBXOPCODE_D9
			b CBXOPCODE_DA
			b CBXOPCODE_DB
			b CBXOPCODE_DC
			b CBXOPCODE_DD
			b CBXOPCODE_DE
			b CBXOPCODE_DF
			b CBXOPCODE_E0
			b CBXOPCODE_E1
			b CBXOPCODE_E2
			b CBXOPCODE_E3
			b CBXOPCODE_E4
			b CBXOPCODE_E5
			b CBXOPCODE_E6
			b CBXOPCODE_E7
			b CBXOPCODE_E8
			b CBXOPCODE_E9
			b CBXOPCODE_EA
			b CBXOPCODE_EB
			b CBXOPCODE_EC
			b CBXOPCODE_ED
			b CBXOPCODE_EE
			b CBXOPCODE_EF
			b CBXOPCODE_F0
			b CBXOPCODE_F1
			b CBXOPCODE_F2
			b CBXOPCODE_F3
			b CBXOPCODE_F4
			b CBXOPCODE_F5
			b CBXOPCODE_F6
			b CBXOPCODE_F7
			b CBXOPCODE_F8
			b CBXOPCODE_F9
			b CBXOPCODE_FA
			b CBXOPCODE_FB
			b CBXOPCODE_FC
			b CBXOPCODE_FD
			b CBXOPCODE_FE
			b CBXOPCODE_FF

CBXOPCODE_00:		;@LD B,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ ShifT left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_01:		;@LD C,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_02:		;@LD D,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_03:		;@LD E,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_04:		;@LD H,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_05:		;@LD L,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_06:		;@RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_07:		;@LD A,RLC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_08:		;@LD B,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_09:		;@LD C,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0A:		;@LD D,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0B:		;@LD E,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0C:		;@LD H,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0D:		;@LD L,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0E:		;@RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_0F:		;@LD A,RRC (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_10:		;@LD B,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_11:		;@LD C,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_12:		;@LD D,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_13:		;@LD E,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_14:		;@LD H,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_15:		;@LD L,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_16:		;@RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_17:		;@LD A,RL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_18:		;@LD B,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_19:		;@LD C,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1A:		;@LD D,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1B:		;@LD E,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1C:		;@LD H,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1D:		;@LD L,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1E:		;@RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_1F:		;@LD A,RR (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_20:		;@LD B,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_21:		;@LD C,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_22:		;@LD D,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_23:		;@LD E,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_24:		;@LD H,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_25:		;@LD L,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_26:		;@SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_27:		;@LD A,SLA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_28:		;@LD B,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_29:		;@LD C,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2A:		;@LD D,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2B:		;@LD E,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2C:		;@LD H,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2D:		;@LD L,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2E:		;@SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_2F:		;@LD A,SRA (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 6
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_30:		;@LD B,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_31:		;@LD C,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_32:		;@LD D,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_33:		;@LD E,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_34:		;@LD H,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_35:		;@LD L,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_36:		;@SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_37:		;@LD A,SLL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_38:		;@LD B,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_39:		;@LD C,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3A:		;@LD D,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3B:		;@LD E,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3C:		;@LD H,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3D:		;@LD L,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3E:		;@SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBXOPCODE_3F:		;@LD A,SRL (IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to mem
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_40:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_41:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_42:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_43:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_44:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_45:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_46:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_47:		;@BIT 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_48:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_49:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4A:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4B:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4C:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4D:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4E:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_4F:		;@BIT 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_50:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_51:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_52:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_53:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_54:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_55:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_56:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_57:		;@BIT 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_58:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_59:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5A:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5B:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5C:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5D:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5E:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_5F:		;@BIT 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_60:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_61:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_62:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_63:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_64:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_65:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_66:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_67:		;@BIT 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_68:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_69:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6A:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6B:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6C:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6D:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6E:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_6F:		;@BIT 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_70:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_71:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_72:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_73:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_74:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_75:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_76:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_77:		;@BIT 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_78:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_79:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7A:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7B:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7C:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7D:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7E:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_7F:		;@BIT 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00		;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400		;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000		;@ Set H Flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBXOPCODE_80:		;@LD B,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_81:		;@LD C,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_82:		;@LD D,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_83:		;@LD E,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_84:		;@LD H,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_85:		;@LD L,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_86:		;@RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_87:		;@LD A,RES 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_88:		;@LD B,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_89:		;@LD C,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8A:		;@LD D,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8B:		;@LD E,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8C:		;@LD H,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8D:		;@LD L,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8E:		;@RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_8F:		;@LD A,RES 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_90:		;@LD B,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_91:		;@LD C,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_92:		;@LD D,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_93:		;@LD E,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_94:		;@LD H,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_95:		;@LD L,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_96:		;@RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_97:		;@LD A,RES 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_98:		;@LD B,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_99:		;@LD C,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9A:		;@LD D,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9B:		;@LD E,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9C:		;@LD H,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9D:		;@LD L,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9E:		;@RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_9F:		;@LD A,RES 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A0:		;@LD B,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A1:		;@LD C,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A2:		;@LD D,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A3:		;@LD E,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A4:		;@LD H,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A5:		;@LD L,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A6:		;@RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A7:		;@LD A,RES 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A8:		;@LD B,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_A9:		;@LD C,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AA:		;@LD D,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AB:		;@LD E,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AC:		;@LD H,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AD:		;@LD L,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AE:		;@RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_AF:		;@LD A,RES 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B0:		;@LD B,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B1:		;@LD C,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B2:		;@LD D,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B3:		;@LD E,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B4:		;@LD H,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B5:		;@LD L,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B6:		;@RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B7:		;@LD A,RES 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B8:		;@LD B,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_B9:		;@LD C,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BA:		;@LD D,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BB:		;@LD E,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BC:		;@LD H,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BD:		;@LD L,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BE:		;@RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	mov r2,#23
b ENDOPCODES

CBXOPCODE_BF:		;@LD A,RES 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacement
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2			;@ Store to mem
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C0:		;@LD B,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C1:		;@LD C,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C2:		;@LD D,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C3:		;@LD E,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C4:		;@LD H,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C5:		;@LD L,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C6:		;@SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C7:		;@LD A,SET 0,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C8:		;@LD B,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_C9:		;@LD C,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CA:		;@LD D,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CB:		;@LD E,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CC:		;@LD H,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CD:		;@LD L,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CE:		;@SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_CF:		;@LD A,SET 1,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D0:		;@LD B,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D1:		;@LD C,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D2:		;@LD D,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D3:		;@LD E,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D4:		;@LD H,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D5:		;@LD L,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D6:		;@SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D7:		;@LD A,SET 2,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D8:		;@LD B,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_D9:		;@LD C,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DA:		;@LD D,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DB:		;@LD E,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DC:		;@LD H,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DD:		;@LD L,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DE:		;@SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_DF:		;@LD A,SET 3,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E0:		;@LD B,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E1:		;@LD C,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E2:		;@LD D,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E3:		;@LD E,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E4:		;@LD H,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E5:		;@LD L,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E6:		;@SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E7:		;@LD A,SET 4,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E8:		;@LD B,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_E9:		;@LD C,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_EA:		;@LD D,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_EB:		;@LD E,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_EC:		;@LD H,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_ED:		;@LD L,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_EE:		;@SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_EF:		;@LD A,SET 5,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F0:		;@LD B,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F1:		;@LD C,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F2:		;@LD D,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F3:		;@LD E,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F4:		;@LD H,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F5:		;@LD L,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F6:		;@SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F7:		;@LD A,SET 6,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F8:		;@LD B,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_F9:		;@LD C,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x000000FF		;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FA:		;@LD D,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0xFF000000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FB:		;@LD E,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r9,r9,#0x00FF0000		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FC:		;@LD H,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0xFF000000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FD:		;@LD L,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x00FF0000		;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FE:		;@SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBXOPCODE_FF:		;@LD A,SET 7,(IX+d)
	add r1,r10,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2			;@ Store value in memory
	bic r8,r8,#0x000000FF		;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYCODES:
	bl MEMREAD
	mov r2,r0			;@load displacement Value into r2
	add r1,r1,#1		;@load Next OP-CODE into r0
	bl MEMREAD
	add r1,r1,#1		;@R1 should still contain the PC so increment
	and r1,r1,r12		;@Mask the 16 bits that relate to the PC
	bic r7,r7,r12		;@Clear the old PC value
	orr r7,r7,r1		;@Store the new PC value
	add r1,r5,#1
	and r1,r1,#127
	bic r5,r5,#127
	orr r5,r5,r1				;@ 4 Lines to increase r register!
	add r15,r15,r0, lsl #2  ;@Multipy opcode by 4 To get value To add To PC

	nop

			b CBYOPCODE_00
			b CBYOPCODE_01
			b CBYOPCODE_02
			b CBYOPCODE_03
			b CBYOPCODE_04
			b CBYOPCODE_05
			b CBYOPCODE_06
			b CBYOPCODE_07
			b CBYOPCODE_08
			b CBYOPCODE_09
			b CBYOPCODE_0A
			b CBYOPCODE_0B
			b CBYOPCODE_0C
			b CBYOPCODE_0D
			b CBYOPCODE_0E
			b CBYOPCODE_0F
			b CBYOPCODE_10
			b CBYOPCODE_11
			b CBYOPCODE_12
			b CBYOPCODE_13
			b CBYOPCODE_14
			b CBYOPCODE_15
			b CBYOPCODE_16
			b CBYOPCODE_17
			b CBYOPCODE_18
			b CBYOPCODE_19
			b CBYOPCODE_1A
			b CBYOPCODE_1B
			b CBYOPCODE_1C
			b CBYOPCODE_1D
			b CBYOPCODE_1E
			b CBYOPCODE_1F
			b CBYOPCODE_20
			b CBYOPCODE_21
			b CBYOPCODE_22
			b CBYOPCODE_23
			b CBYOPCODE_24
			b CBYOPCODE_25
			b CBYOPCODE_26
			b CBYOPCODE_27
			b CBYOPCODE_28
			b CBYOPCODE_29
			b CBYOPCODE_2A
			b CBYOPCODE_2B
			b CBYOPCODE_2C
			b CBYOPCODE_2D
			b CBYOPCODE_2E
			b CBYOPCODE_2F
			b CBYOPCODE_30
			b CBYOPCODE_31
			b CBYOPCODE_32
			b CBYOPCODE_33
			b CBYOPCODE_34
			b CBYOPCODE_35
			b CBYOPCODE_36
			b CBYOPCODE_37
			b CBYOPCODE_38
			b CBYOPCODE_39
			b CBYOPCODE_3A
			b CBYOPCODE_3B
			b CBYOPCODE_3C
			b CBYOPCODE_3D
			b CBYOPCODE_3E
			b CBYOPCODE_3F
			b CBYOPCODE_40
			b CBYOPCODE_41
			b CBYOPCODE_42
			b CBYOPCODE_43
			b CBYOPCODE_44
			b CBYOPCODE_45
			b CBYOPCODE_46
			b CBYOPCODE_47
			b CBYOPCODE_48
			b CBYOPCODE_49
			b CBYOPCODE_4A
			b CBYOPCODE_4B
			b CBYOPCODE_4C
			b CBYOPCODE_4D
			b CBYOPCODE_4E
			b CBYOPCODE_4F
			b CBYOPCODE_50
			b CBYOPCODE_51
			b CBYOPCODE_52
			b CBYOPCODE_53
			b CBYOPCODE_54
			b CBYOPCODE_55
			b CBYOPCODE_56
			b CBYOPCODE_57
			b CBYOPCODE_58
			b CBYOPCODE_59
			b CBYOPCODE_5A
			b CBYOPCODE_5B
			b CBYOPCODE_5C
			b CBYOPCODE_5D
			b CBYOPCODE_5E
			b CBYOPCODE_5F
			b CBYOPCODE_60
			b CBYOPCODE_61
			b CBYOPCODE_62
			b CBYOPCODE_63
			b CBYOPCODE_64
			b CBYOPCODE_65
			b CBYOPCODE_66
			b CBYOPCODE_67
			b CBYOPCODE_68
			b CBYOPCODE_69
			b CBYOPCODE_6A
			b CBYOPCODE_6B
			b CBYOPCODE_6C
			b CBYOPCODE_6D
			b CBYOPCODE_6E
			b CBYOPCODE_6F
			b CBYOPCODE_70
			b CBYOPCODE_71
			b CBYOPCODE_72
			b CBYOPCODE_73
			b CBYOPCODE_74
			b CBYOPCODE_75
			b CBYOPCODE_76
			b CBYOPCODE_77
			b CBYOPCODE_78
			b CBYOPCODE_79
			b CBYOPCODE_7A
			b CBYOPCODE_7B
			b CBYOPCODE_7C
			b CBYOPCODE_7D
			b CBYOPCODE_7E
			b CBYOPCODE_7F
			b CBYOPCODE_80
			b CBYOPCODE_81
			b CBYOPCODE_82
			b CBYOPCODE_83
			b CBYOPCODE_84
			b CBYOPCODE_85
			b CBYOPCODE_86
			b CBYOPCODE_87
			b CBYOPCODE_88
			b CBYOPCODE_89
			b CBYOPCODE_8A
			b CBYOPCODE_8B
			b CBYOPCODE_8C
			b CBYOPCODE_8D
			b CBYOPCODE_8E
			b CBYOPCODE_8F
			b CBYOPCODE_90
			b CBYOPCODE_91
			b CBYOPCODE_92
			b CBYOPCODE_93
			b CBYOPCODE_94
			b CBYOPCODE_95
			b CBYOPCODE_96
			b CBYOPCODE_97
			b CBYOPCODE_98
			b CBYOPCODE_99
			b CBYOPCODE_9A
			b CBYOPCODE_9B
			b CBYOPCODE_9C
			b CBYOPCODE_9D
			b CBYOPCODE_9E
			b CBYOPCODE_9F
			b CBYOPCODE_A0
			b CBYOPCODE_A1
			b CBYOPCODE_A2
			b CBYOPCODE_A3
			b CBYOPCODE_A4
			b CBYOPCODE_A5
			b CBYOPCODE_A6
			b CBYOPCODE_A7
			b CBYOPCODE_A8
			b CBYOPCODE_A9
			b CBYOPCODE_AA
			b CBYOPCODE_AB
			b CBYOPCODE_AC
			b CBYOPCODE_AD
			b CBYOPCODE_AE
			b CBYOPCODE_AF
			b CBYOPCODE_B0
			b CBYOPCODE_B1
			b CBYOPCODE_B2
			b CBYOPCODE_B3
			b CBYOPCODE_B4
			b CBYOPCODE_B5
			b CBYOPCODE_B6
			b CBYOPCODE_B7
			b CBYOPCODE_B8
			b CBYOPCODE_B9
			b CBYOPCODE_BA
			b CBYOPCODE_BB
			b CBYOPCODE_BC
			b CBYOPCODE_BD
			b CBYOPCODE_BE
			b CBYOPCODE_BF
			b CBYOPCODE_C0
			b CBYOPCODE_C1
			b CBYOPCODE_C2
			b CBYOPCODE_C3
			b CBYOPCODE_C4
			b CBYOPCODE_C5
			b CBYOPCODE_C6
			b CBYOPCODE_C7
			b CBYOPCODE_C8
			b CBYOPCODE_C9
			b CBYOPCODE_CA
			b CBYOPCODE_CB
			b CBYOPCODE_CC
			b CBYOPCODE_CD
			b CBYOPCODE_CE
			b CBYOPCODE_CF
			b CBYOPCODE_D0
			b CBYOPCODE_D1
			b CBYOPCODE_D2
			b CBYOPCODE_D3
			b CBYOPCODE_D4
			b CBYOPCODE_D5
			b CBYOPCODE_D6
			b CBYOPCODE_D7
			b CBYOPCODE_D8
			b CBYOPCODE_D9
			b CBYOPCODE_DA
			b CBYOPCODE_DB
			b CBYOPCODE_DC
			b CBYOPCODE_DD
			b CBYOPCODE_DE
			b CBYOPCODE_DF
			b CBYOPCODE_E0
			b CBYOPCODE_E1
			b CBYOPCODE_E2
			b CBYOPCODE_E3
			b CBYOPCODE_E4
			b CBYOPCODE_E5
			b CBYOPCODE_E6
			b CBYOPCODE_E7
			b CBYOPCODE_E8
			b CBYOPCODE_E9
			b CBYOPCODE_EA
			b CBYOPCODE_EB
			b CBYOPCODE_EC
			b CBYOPCODE_ED
			b CBYOPCODE_EE
			b CBYOPCODE_EF
			b CBYOPCODE_F0
			b CBYOPCODE_F1
			b CBYOPCODE_F2
			b CBYOPCODE_F3
			b CBYOPCODE_F4
			b CBYOPCODE_F5
			b CBYOPCODE_F6
			b CBYOPCODE_F7
			b CBYOPCODE_F8
			b CBYOPCODE_F9
			b CBYOPCODE_FA
			b CBYOPCODE_FB
			b CBYOPCODE_FC
			b CBYOPCODE_FD
			b CBYOPCODE_FE
			b CBYOPCODE_FF

CBYOPCODE_00:		;@LD B,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_01:		;@LD C,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_02:		;@LD D,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_03:		;@LD E,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_04:		;@LD H,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_05:		;@LD L,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_06:		;@RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_07:		;@LD A,RLC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry and bit 0 if old bit 7 was set
	orrne r0,r0,#0x1		;@ Set carry and bit 0 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_08:		;@LD B,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_09:		;@LD C,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0A:		;@LD D,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0B:		;@LD E,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0C:		;@LD H,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0D:		;@LD L,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0E:		;@RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_0F:		;@LD A,RRC (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift left 1
	orrcs r8,r8,#0x100		;@ Set carry if old bit 0 was set
	orrcs r0,r0,#0x80		;@ Set bit 7 if old bit 0 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_10:		;@LD B,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_11:		;@LD C,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_12:		;@LD D,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_13:		;@LD E,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_14:		;@LD H,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_15:		;@LD L,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_16:		;@RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_17:		;@LD A,RL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	tst r8,#0x100			;@ Test current carry flag
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	orrne r0,r0,#1			;@ Set bit 0 if carry was set
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_18:		;@LD B,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_19:		;@LD C,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1A:		;@LD D,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1B:		;@LD E,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1C:		;@LD H,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1D:		;@LD L,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1E:		;@RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_1F:		;@LD A,RR (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	mov r4,r8,lsr #8		;@ Move old flags into R1
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift Right 1
	and r0,r0,#0x7F			;@ Mask back to byte less bit 7
	orrcs r8,r8,#0x100		;@ Set Z80 carry flag is shift cause ARM carry
	tst r4,#1 			;@ Test if old carry was set
	orrne r0,r0,#0x80		;@ Set bit 7 if so
	cmp r0,#0
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store to memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_20:		;@LD B,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_21:		;@LD C,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_22:		;@LD D,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_23:		;@LD E,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_24:		;@LD H,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_25:		;@LD L,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_26:		;@SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_27:		;@LD A,SLA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_28:		;@LD B,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_29:		;@LD C,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2A:		;@LD D,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2B:		;@LD E,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2C:		;@LD H,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2D:		;@LD L,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2E:		;@SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_2F:		;@LD A,SRA (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	bic r0,r0,#128			;@ Clear bit 7
	tst r0,#64			;@ Test bit 8
	orrne r0,r0,#0x80		;@ Set new bit 7 if old bit 7 was set
	ands r0,r0,#0xFF		;@ Mask back to byte
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_30:		;@LD B,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_31:		;@LD C,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_32:		;@LD D,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_33:		;@LD E,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_34:		;@LD H,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_35:		;@LD L,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_36:		;@SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_37:		;@LD A,SLL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	mov r0,r0,lsl #1		;@ Shift left 1
	tst r0,#256			;@ Test bit 8
	orrne r8,r8,#0x100		;@ Set carry flag if old bit 7 was set
	and r0,r0,#0xFF			;@ Mask back to byte
	orr r0,r0,#1			;@ Insert 1 at end
	tst r0,#128			;@ Test S flag
	orrne r8,r8,#0x8000		;@ Set S flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_38:		;@LD B,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x0000FF00		;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8		;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_39:		;@LD C,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3A:		;@LD D,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3B:		;@LD E,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3C:		;@LD H,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3D:		;@LD L,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3E:		;@SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	mov r2,#23
b ENDOPCODES

CBYOPCODE_3F:		;@LD A,SRL (IY+d)
	mov r1,r10,lsr #16		;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128			;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r8,r8,#0xFF00		;@ Clear all flag
	movs r0,r0,lsr #1		;@ Shift right 1
	orrcs r8,r8,#0x100		;@ Set Z80 carry if ARM carry set
	ands r0,r0,#0x7F		;@ Mask back to byte and reset bit 7
	orreq r8,r8,#0x4000		;@ Set Zero flag
	tst r0,#32			;@ Test 5 flag
	orrne r8,r8,#0x2000		;@ Set 5 flag
	tst r0,#8			;@ Test 3 flag
	orrne r8,r8,#0x800		;@ Set 3 flag
	bl STOREMEM2			;@ Store value in memory
	adrl r2,Parity			;@ Get start of parity table
	ldrb r3,[r2,r0]			;@ Get parity value
	cmp r3,#0			;@ Test parity value
	orrne r8,r8,#0x400		;@ Set parity flag if needs be
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_40:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_41:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_42:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_43:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_44:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_45:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_46:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_47:		;@BIT 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x01		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_48:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_49:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4A:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4B:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4C:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4D:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4E:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_4F:		;@BIT 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x02		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_50:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_51:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_52:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_53:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_54:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_55:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_56:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_57:		;@BIT 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x04		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_58:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_59:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5A:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5B:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5C:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5D:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5E:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_5F:		;@BIT 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x08		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_60:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_61:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_62:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_63:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_64:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_65:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_66:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_67:		;@BIT 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x10		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_68:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_69:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6A:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6B:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6C:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6D:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6E:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_6F:		;@BIT 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x20		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_70:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_71:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_72:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_73:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_74:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_75:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_76:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_77:		;@BIT 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x40		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_78:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_79:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7A:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7B:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7C:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7D:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7E:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_7F:		;@BIT 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	ands r1,r0,#0x80		;@ Test Bit
	bic r8,r8,#0xEE00			;@ Clear S,Z,5,P,3 and N flags
	orrne r8,r8,#0x8000		;@Set S flag if bit was set
	orreq r8,r8,#0x4400				;@ Set Z and P flags if bit wasn't set
	orr r8,r8,#0x1000			;@ Set H Flag
	tst r0,#32					;@ Test 5 flag
	orrne r8,r8,#0x2000			;@ Set 5 flag
	tst r0,#8					;@ Test 3 flag
	orrne r8,r8,#0x800			;@ Set 3 flag
	mov r2,#20
b ENDOPCODES

CBYOPCODE_80:		;@LD B,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_81:		;@LD C,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_82:		;@LD D,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_83:		;@LD E,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_84:		;@LD H,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_85:		;@LD L,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_86:		;@RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_87:		;@LD A,RES 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x01			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_88:		;@LD B,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_89:		;@LD C,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8A:		;@LD D,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8B:		;@LD E,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8C:		;@LD H,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8D:		;@LD L,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8E:		;@RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_8F:		;@LD A,RES 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x02			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_90:		;@LD B,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_91:		;@LD C,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_92:		;@LD D,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_93:		;@LD E,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_94:		;@LD H,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_95:		;@LD L,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_96:		;@RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_97:		;@LD A,RES 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x04			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_98:		;@LD B,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_99:		;@LD C,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9A:		;@LD D,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9B:		;@LD E,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9C:		;@LD H,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9D:		;@LD L,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9E:		;@RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_9F:		;@LD A,RES 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x08			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A0:		;@LD B,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A1:		;@LD C,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A2:		;@LD D,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A3:		;@LD E,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A4:		;@LD H,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A5:		;@LD L,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A6:		;@RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A7:		;@LD A,RES 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x10			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A8:		;@LD B,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_A9:		;@LD C,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AA:		;@LD D,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AB:		;@LD E,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AC:		;@LD H,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AD:		;@LD L,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AE:		;@RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_AF:		;@LD A,RES 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x20			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B0:		;@LD B,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B1:		;@LD C,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B2:		;@LD D,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B3:		;@LD E,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B4:		;@LD H,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B5:		;@LD L,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B6:		;@RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B7:		;@LD A,RES 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x40			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B8:		;@LD B,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_B9:		;@LD C,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BA:		;@LD D,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BB:		;@LD E,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BC:		;@LD H,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BD:		;@LD L,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BE:		;@RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_BF:		;@LD A,RES 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	bic r0,r0,#0x80			;@ Reset Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C0:		;@LD B,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C1:		;@LD C,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C2:		;@LD D,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C3:		;@LD E,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C4:		;@LD H,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C5:		;@LD L,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C6:		;@SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C7:		;@LD A,SET 0,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x01			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C8:		;@LD B,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_C9:		;@LD C,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CA:		;@LD D,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CB:		;@LD E,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CC:		;@LD H,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CD:		;@LD L,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CE:		;@SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_CF:		;@LD A,SET 1,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x02			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D0:		;@LD B,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D1:		;@LD C,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D2:		;@LD D,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D3:		;@LD E,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D4:		;@LD H,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D5:		;@LD L,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D6:		;@SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D7:		;@LD A,SET 2,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x04			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D8:		;@LD B,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_D9:		;@LD C,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DA:		;@LD D,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DB:		;@LD E,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DC:		;@LD H,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DD:		;@LD L,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DE:		;@SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_DF:		;@LD A,SET 3,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x08			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E0:		;@LD B,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E1:		;@LD C,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E2:		;@LD D,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E3:		;@LD E,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E4:		;@LD H,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E5:		;@LD L,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E6:		;@SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E7:		;@LD A,SET 4,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x10			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E8:		;@LD B,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_E9:		;@LD C,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_EA:		;@LD D,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_EB:		;@LD E,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_EC:		;@LD H,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_ED:		;@LD L,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_EE:		;@SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_EF:		;@LD A,SET 5,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x20			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F0:		;@LD B,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F1:		;@LD C,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F2:		;@LD D,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F3:		;@LD E,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F4:		;@LD H,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F5:		;@LD L,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F6:		;@SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F7:		;@LD A,SET 6,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x40			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F8:		;@LD B,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x0000FF00			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #8			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_F9:		;@LD C,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x000000FF			;@ Clear target byte to 0
	orr r9,r9,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FA:		;@LD D,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0xFF000000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FB:		;@LD E,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r9,r9,#0x00FF0000			;@ Clear target byte to 0
	orr r9,r9,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FC:		;@LD H,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0xFF000000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #24			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FD:		;@LD L,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x00FF0000			;@ Clear target byte to 0
	orr r8,r8,r0,lsl #16			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FE:		;@SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	mov r2,#23
b ENDOPCODES

CBYOPCODE_FF:		;@LD A,SET 7,(IY+d)
	mov r1,r10,lsr #16			;@ Get value of register
	add r1,r1,r2			;@ Add displacement
	tst r2,#128				;@ Check sign for 2's displacemen
	subne r1,r1,#256 		;@ Make amount negative if above 127
	and r1,r1,r12			;@ Mask register value to a short (16 bit) value
	bl MEMREAD
	orr r0,r0,#0x80			;@ Set Bit
	bl STOREMEM2				;@ Store value in memory
	bic r8,r8,#0x000000FF			;@ Clear target byte to 0
	orr r8,r8,r0			;@ Place value on target register
	mov r2,#23
b ENDOPCODES

ENDOPCODES:






			;@tst r5,#0x10000		;@Test whether in debug mode
			;@bne INTRETURN		;@If so exit out of core
			;@and r0,r7,r12		;@Get PC
			;@mov r1,#0x5D00		;@Breakpoint
			;@add r1,r1,#0xD0
			;@cmp r0,r1
			;@orreq r5,r5,#0x10000	;@ Set debug to true
			;@beq INTRETURN


			subs r11,r11,r2		;@ Reduce cycles

			bpl CPU_LOOP		;@ Keep within CPU core if not reached INT

;@			b INTERRUPT		;@Call INT Interrupt routine
INTRETURN:
			;@ldr r1,=rpointer ;@Load address For external register storage
			;@ldr r0,[r1]
			mov r0,cpucontext

			ldr r4,=ExReg
			ldr r2,[r4,#4]
			ldr r3,[r4,#8]

			str r7,[r0],#4 ;@Start storing registers
			str r8,[r0],#4
			str r9,[r0],#4
			str r10,[r0],#4
			str r2,[r0],#4
			str r3,[r0],#4
			str r11,[r0],#4
			str r5,[r0]


			ldmfd r13!,{r3-r12,lr}
			bx lr

.align 4


INTERRUPT:
	adrl r2,totalcycles				;@ Move the new number of cycles back in
	ldr r2,[r2]
	add r11,r11,r2					;@ Add total cycles back to NMI cycle count

	;@tst r5,#0x800000				;@ Is tape loader flag set?
	;@bne INTRETURN

	mov r2,#0
	bic r5,r5,#0x20000				;@ Clear Halt flag
	tst r5,#0x40000000				;@ Test if IFF1 is set
	beq INTRETURN					;@ Go back to main routine if not
	bic r5,r5,#0x40000000				;@ Clear IFF1 flag
	tst r5,#0x20000000				;@ Test Interrupt Mode Bit 2
	bne MODE2					;@ Jump to MODE2 if set

	and r0,r7,r12					;@ Move PC into R0 and mask to 16 bits
	mov r1,r7,lsr #16				;@ Put SP into R1
	sub r1,r1,#2					;@ Decrease stack by 2
	and r1,r1,r12					;@ Mask to 16 bits
	and r7,r7,r12					;@ Clear old SP
	orr r7,r7,r1,lsl #16				;@ Replace with new SP
	bl MEMSTORESHORT				;@ Store low byte of PC
	bic r7,r7,r12					;@ Clear old PC
	orr r7,r7,#0x38					;@ Out in address 38H
	sub r11,r11,#12
	tst r5,#0x10000000				;@ test IM1 flag
	subne r11,r11,#1
	mov r2,#12					;@ It takes 12 cycles to enter interrupt
	addne r2,r2,#1
	b INTRETURN					;@ Exit from interrupt

MODE2:
	and r0,r7,r12					;@ Move PC into R2 and mask to 16 bits
	mov r1,r7,lsr #16				;@ Put SP into R1
	sub r1,r1,#2					;@ Decrease stack by 2
	and r1,r1,r12					;@ Mask to 16 bits
	and r7,r7,r12					;@ Clear old SP
	orr r7,r7,r1,lsl #16				;@ Replace with new SP
	bl MEMSTORESHORT
	bic r7,r7,r12					;@ Clear old PC
	and r1,r5,#0xFF00				;@ Get value of I register
	orr r1,r1,#0x00FF				;@ Add 255
	bl MEMREADSHORT
	orr r7,r7,r0					;@ Copy to PC
	sub r11,r11,#19
	mov r2,#19					;@ It takes 19 cycles to enter interrupt
	b INTRETURN					;@ Exit from Interrupt

totalcycles: .word 69888


MEMSTORE:
    ;;@ r0 = data, r1 = addr
     stmdb sp!,{r2,r3,r12,lr}
     ldr r3,[cpucontext,#ppMemWrite]		;;@ r3 point to ppMemWrite[0]
     mov r2,r1,lsr#8
     ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemWrite[addr >> 8]
     cmp r3,#0
     strneb r0,[r3,r1]
     bne write8_end
     mov r2,r1								;;@ swp r1, r0
     mov r1,r0
     mov r0,r2
     ;;@str z80_icount,[cpucontext,#nCyclesLeft]
     mov lr,pc								;;@ call z80_write8(r0, r1)
     ldr pc,[cpucontext,#z80_write8]
write8_end:
     ldmia sp!,{r2,r3,r12,lr}
	mov pc,lr				;@ Go back


STOREMEM2:
    ;;@ r0 = data, r3 = addr
     stmdb sp!,{r1,r2,r12,lr}
     ldr r1,[cpucontext,#ppMemWrite]		;;@ r3 point to ppMemWrite[0]
     mov r2,r3,lsr#8
     ldr r1,[r1,r2,lsl#2]					;;@ r3 = ppMemWrite[addr >> 8]
     cmp r1,#0
     strneb r0,[r1,r3]
     bne write8_end_2
     mov r2,r3								;;@ swp r1, r0
     mov r3,r0
     mov r0,r2
     ;;@str z80_icount,[cpucontext,#nCyclesLeft]
     mov lr,pc								;;@ call z80_write8(r0, r1)
     ldr pc,[cpucontext,#z80_write8]
write8_end_2:
     ldmia sp!,{r1,r2,r12,lr}
	mov pc,lr				;@ Go back


MEMSTORESHORT:
;;@ r0 = data, r1 = addr
     stmdb sp!,{r2,r3,r12,lr}
     ldr r3,[cpucontext,#ppMemWrite]		;;@ r3 point to ppMemWrite[0]

     cmp r3,#0
     addne r3,r3,r1
     movne r2,r0,lsr#8
     strneb r0,[r3],#1
     strneb r2,[r3]
     bne write16_end
;;@     str z80pc,[cpucontext,#z80pc_pointer]
     mov lr,pc								;;@ call z80_write8(r0, r1)
     ldr pc,[cpucontext,#z80_write16]
write16_end:
    ldmia sp!,{r2,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREAD:
    ;@r3=addr
    mov r0,r1
    stmdb sp!,{r2,r3,r12,lr}
    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
    mov r2,r0,lsr#8
    ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
    cmp r3,#0
    ldrneb r0,[r3,r0]
    bne read8_1_end
    mov lr,pc								;;@ call z80_read8(r0, r1)
    ldr pc,[cpucontext,#z80_read8]
read8_1_end:
     ldmia sp!,{r2,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREADSHORT:
    mov r0,r1
     ;;@ r0 = addr
    stmdb sp!,{r1,r2,r3,r12,lr}
    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8
     ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
     cmp r3,#0
     beq read16_call_1
     add r3,r3,r0
     ldrb r0,[r3],#1
     ldrb r1,[r3]
     orr r0,r0,r1,lsl #8
     b read16_end_1
read16_call_1:
;;@     str z80pc,[cpucontext,#z80pc_pointer]
     mov lr,pc								;;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read16]
read16_end_1:
     ldmia sp!,{r1,r2,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREAD2:
    stmdb sp!,{r0,r2,r3,r12,lr}
	mov r0,r2
    ;@r0=addr
    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
    mov r2,r0,lsr#8
    ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
    cmp r3,#0
    ldrneb r1,[r3,r0]
    bne read8_2_end
    mov lr,pc								;;@ call z80_read8(r0, r1)
    ldr pc,[cpucontext,#z80_read8]
    mov r1,r0
read8_2_end:
     ldmia sp!,{r0,r2,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREADSHORT2:
    stmdb sp!,{r0,r2,r3,r12,lr}
    mov r0,r2
     ;;@ r0 = addr

    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8
     ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
     cmp r3,#0
     beq read16_call_2
     add r3,r3,r0
     ldrb r0,[r3],#1
     ldrb r1,[r3]
     orr r1,r0,r1,lsl #8
     b read16_end_2
read16_call_2:
;;@     str z80pc,[cpucontext,#z80pc_pointer]
     mov lr,pc								;;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read16]
     mov r1,r0
read16_end_2:
     ldmia sp!,{r0,r2,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREAD3:					;@ For OUT and IN operation
    stmdb sp!,{r0,r3,r12,lr}
	mov r0,r1
    ;@r0=addr
    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
    mov r2,r0,lsr#8
    ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
    cmp r3,#0
    ldrneb r2,[r3,r0]
    bne read8_3_end
    mov lr,pc								;;@ call z80_read8(r0, r1)
    ldr pc,[cpucontext,#z80_read8]
    mov r2,r0
read8_3_end:
     ldmia sp!,{r0,r3,r12,lr}
	mov pc,lr				;@ Go back


MEMREADSHORT3:				;@ Especially for POP operation
    stmdb sp!,{r0,r1,r3,r12,lr}
    mov r0,r1
     ;;@ r0 = addr
    ldr r3,[cpucontext,#ppMemRead]			;;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8
     ldr r3,[r3,r2,lsl#2]					;;@ r3 = ppMemRead[addr >> 8]
     cmp r3,#0
     beq read16_call_3
     add r3,r3,r0
     ldrb r0,[r3],#1
     ldrb r1,[r3]
     orr r2,r0,r1,lsl #8
     b read16_end_3
read16_call_3:
;;@     str z80pc,[cpucontext,#z80pc_pointer]
     mov lr,pc								;;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read16]
     mov r2,r0
read16_end_3:
     ldmia sp!,{r0,r1,r3,r12,lr}
	mov pc,lr				;@ Go back

MEMFETCH:
    stmdb sp!,{r1,r2,r3}
    mov r2,r1
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r0,[r1,r2]
     ldmia sp!,{r1,r2,r3}
	mov pc,lr				;@ Go back


MEMFETCHSHORT:
    stmdb sp!,{r1,r2,r3}
    mov r2,r1
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r0,[r1,r2]
     add r2,r2,#1
     ldrb r1,[r1,r2]
     orr r0,r0,r1, lsl #8

     ldmia sp!,{r1,r2,r3}
	mov pc,lr				;@ Go back


MEMFETCH2:
    stmdb sp!,{r2,r3}
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r1,[r1,r2]
     ldmia sp!,{r2,r3}
	mov pc,lr				;@ Go back


MEMFETCHSHORT2:
    stmdb sp!,{r2,r3}
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r0,[r1,r2]
     add r2,r2,#1
     ldrb r1,[r1,r2]
     orr r1,r0,r1, lsl #8

     ldmia sp!,{r2,r3}
	mov pc,lr				;@ Go back

MEMFETCH3:
    stmdb sp!,{r1,r3}
    mov r2,r1
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r2,[r1,r2]
     ldmia sp!,{r1,r3}
	mov pc,lr				;@ Go back


MEMFETCHSHORT3:
    stmdb sp!,{r1,r3}
    mov r2,r1
     ldr r1,[cpucontext,#ppMemFetchData]	;;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8
     ldr r1,[r1,r0,lsl#2]					;;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r0,[r1,r2]
     add r2,r2,#1
     ldrb r1,[r1,r2]
     orr r2,r0,r1, lsl #8

     ldmia sp!,{r1,r3}
	mov pc,lr				;@ Go back

.align 4


Flag3:
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.align 4

Flag5:
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
.align 4

DAA:
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00, 0x00
.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60, 0x60, 0x60, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x60
.byte 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
.byte 0x06, 0x06, 0x06, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.byte 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
.align 4

Parity:
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 1, 0, 0, 1, 0, 1, 1, 0
.byte 0, 1, 1, 0, 1, 0, 0, 1
.align 4
