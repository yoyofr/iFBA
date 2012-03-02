;@ Reesy's Z80 Emulator Version 0.001

;@ (c) Copyright 2004 Reesy, All rights reserved
;@ DrZ80 is free for non-commercial use.

;@ For commercial use, separate licencing terms must be obtained.

;@ the memory handler is changed to speed up memory access
;@ and support q-sound encrypt z80 progran rom format
;@
;@ OopsWare   2007.2
;@ http://oopsware.googlepages.com

.align 4
    .global _DrZ80Run
      .global _DrZ80Ver
                  
_DrZ80Ver: .long 0x0001

;@ --------------------------- Defines ----------------------------

     opcodes .req r3
     z80_icount .req r4
     cpucontext .req r5
     z80pc .req r6
     z80a .req r7
     z80f .req r8
     z80bc .req r9
     z80de .req r10
     z80hl .req r11
     z80sp .req r12	
     z80xx .req lr

     z80a_pointer=            0                  ;@  0
     z80f_pointer=            z80a_pointer+4     ;@  4
     z80bc_pointer=           z80f_pointer+4     ;@  
     z80de_pointer=           z80bc_pointer+4
     z80hl_pointer=           z80de_pointer+4
     z80pc_pointer=           z80hl_pointer+4
     z80pc_base=              z80pc_pointer+4
     z80sp_pointer=           z80pc_base+4
     z80sp_base=              z80sp_pointer+4
     z80ix=                   z80sp_base+4
     z80iy=                   z80ix+4
     z80i=                    z80iy+4
     z80a2=                   z80i+4
     z80f2=                   z80a2+4
     z80bc2=                  z80f2+4
     z80de2=                  z80bc2+4
     z80hl2=                  z80de2+4     
     z80irq=                  z80hl2+4   
     z80if=                   z80irq+1
     z80im=                   z80if+1
	 z80spare=                z80im+1
	 z80irqvector=            z80spare+1

     nEI=			 		  z80irqvector+4
	 nCyclesLeft=		  	  nEI+4
	 nCyclesTotal=	 		  nCyclesLeft+4
	 nCyclesSegment=	 	  nCyclesTotal+4
	 nInterruptLatch=	 	  nCyclesSegment+4

	 z80irqcallback=          nInterruptLatch+4
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
    
     VFlag= 0
     CFlag= 1
     ZFlag= 2
     SFlag= 3
     HFlag= 4
     NFlag= 5
     Flag3= 6
     Flag5= 7

     Z80_CFlag= 0
     Z80_NFlag= 1
     Z80_VFlag= 2
     Z80_Flag3= 3
     Z80_HFlag= 4
     Z80_Flag5= 5
     Z80_ZFlag= 6
     Z80_SFlag= 7

     Z80_IF1= 1
     Z80_IF2= 2
     Z80_HALT= 4

.macro fetch cycs
     subs z80_icount,z80_icount,#\cycs
     ldrplb r0,[z80pc],#1
     ldrpl pc,[opcodes,r0, lsl #2]
     b z80_execute_end
     ;@bmi z80_execute_end
.endm

.macro DAM_READ8 jpname
     ;@ r0 = addr
     stmdb sp!,{r3,r12}
     
     ;@str z80pc,[cpucontext,#z80pc_pointer]	;@ save pc for debug only
     
     ldr r3,[cpucontext,#ppMemRead]			;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8						
     ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemRead[addr >> 8]
     
     cmp r3,#0
     ldrneb r0,[r3,r0]
     bne read8_end_\jpname
     
     mov lr,pc								;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read8]
read8_end_\jpname:
     ldmia sp!,{r3,r12}
.endm

.macro DAM_READ8R1 jpname
     ;@ r0 = addr
     stmdb sp!,{r0,r3,r12}
     ldr r3,[cpucontext,#ppMemRead]			;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8						
     ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemRead[addr >> 8]
     
     cmp r3,#0
     ldrneb r0,[r3,r0]
     bne read8r1_end_\jpname
     
     mov lr,pc								;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read8]
read8r1_end_\jpname:
     ldmia sp!,{r1,r3,r12}
.endm

.macro DAM_READ16 jpname
     ;@ r0 = addr
     stmdb sp!,{r3,r12}
     
     ldr r3,[cpucontext,#ppMemRead]			;@ r3 point to ppMemRead[0]
     mov r2,r0,lsr#8						
     ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemRead[addr >> 8]
     
     cmp r3,#0
     beq read16_call_\jpname
     
     add r3,r3,r0
     ldrb r0,[r3],#1
     ldrb r1,[r3]
     orr r0,r0,r1,lsl #8
     b read16_end_\jpname

read16_call_\jpname:

;@     str z80pc,[cpucontext,#z80pc_pointer]
     
     mov lr,pc								;@ call z80_read8(r0, r1)
     ldr pc,[cpucontext,#z80_read16]
read16_end_\jpname:
     ldmia sp!,{r3,r12}
.endm


.macro DAM_WRITE8 jpname
     ;@ r0 = data, r1 = addr
     stmdb sp!,{r3,r12}
     ldr r3,[cpucontext,#ppMemWrite]		;@ r3 point to ppMemWrite[0]
     mov r2,r1,lsr#8						
     ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemWrite[addr >> 8]
     
     cmp r3,#0
     strneb r0,[r3,r1]
     bne write8_end_\jpname
     
     mov r2,r1								;@ swp r1, r0
     mov r1,r0
     mov r0,r2
     
     ;@str z80_icount,[cpucontext,#nCyclesLeft]
     
     mov lr,pc								;@ call z80_write8(r0, r1)
     ldr pc,[cpucontext,#z80_write8]
     
write8_end_\jpname:
     ldmia sp!,{r3,r12}
.endm

.macro DAM_WRITE16 jpname
     ;@ r0 = data, r1 = addr
     stmdb sp!,{r3,r12}
     ldr r3,[cpucontext,#ppMemWrite]		;@ r3 point to ppMemWrite[0]
     mov r2,r1,lsr#8						
     ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemWrite[addr >> 8]
     
     cmp r3,#0
     addne r3,r3,r1
     movne r2,r0,lsr#8
     strneb r0,[r3],#1
     strneb r2,[r3]
     bne write16_end_\jpname
     
;@     str z80pc,[cpucontext,#z80pc_pointer]
     mov lr,pc								;@ call z80_write8(r0, r1)
     ldr pc,[cpucontext,#z80_write16]
     
write16_end_\jpname:
     ldmia sp!,{r3,r12}
.endm

.macro DAM_FETCH8
     ;@ldrb r0,[z80pc],#1
     ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
     sub r2,z80pc,r2
     ldr r1,[cpucontext,#ppMemFetch]		;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8						
     ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]
     
     ldrb r0,[r1,r2]
     add z80pc,z80pc,#1
.endm

.macro DAM_FETCH8D reg
     ;@ldrb \reg,[z80pc],#1
     ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
     sub r2,z80pc,r2
     ldr r1,[cpucontext,#ppMemFetchData]	;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8						
     ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]
     
     ldrb \reg,[r1,r2]
     add z80pc,z80pc,#1
.endm

.macro DAM_FETCH8D_S inc_pc
     ;@ldrb r0,[z80pc],#1
     
     ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
     sub r2,z80pc,r2
     ldr r1,[cpucontext,#ppMemFetchData]	;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8						
     ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]
     
     ldrsb r0,[r1,r2]
     add z80pc,z80pc,#\inc_pc
.endm

.macro DAM_FETCH16D reg
     ;@ldrb r0,[z80pc],#1
     ;@ldrb r1,[z80pc],#1
     ;@orr \reg,r0,r1, lsl #8

     ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
     sub r2,z80pc,r2
     ldr r1,[cpucontext,#ppMemFetchData]	;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8						
     ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]
     
     ldrb r0,[r1,r2]
     add r2,r2,#1
     ldrb r1,[r1,r2]
     orr \reg,r0,r1, lsl #8
     add z80pc,z80pc,#2
.endm

.macro REBASE_PC
     ;@stmdb sp!,{r3,r12}
     ;@mov lr,pc
     ;@ldr pc,[cpucontext,#z80_rebasePC] ;@ r0=new pc - external function sets z80pc_base and returns new z80pc in r0
     ;@ldmia sp!,{r3,r12}
     ;@mov z80pc,r0
     
     ldr r1,[cpucontext,#ppMemFetch]
     mov r2,r0,lsr#8
     ldr r1,[r1,r2,lsl#2]
     
     str r1,[cpucontext,#z80pc_base]
     add z80pc,r1,r0
.endm

.macro PUSH_r0 dec_sp
     sub z80sp,z80sp,#\dec_sp

     ldr r2,[cpucontext,#ppMemWrite]
     mov r1,z80sp,lsr#8						
     ldr r1,[r2,r1,lsl#2]
     
     cmp r1,#0
     beq end_loop
     
     add r1,r1,z80sp
     mov r2,r0,lsr#8
     strb r0,[r1],#1
     strb r2,[r1]
.endm

.macro POP_r0 inc_sp
     ldr r2,[cpucontext,#ppMemRead]
     mov r1,z80sp,lsr#8		
     ldr r1,[r2,r1,lsl#2]
     
     cmp r1,#0
     beq end_loop
     
     add r2,r1,z80sp
     ldrb r0,[r2],#1
     ldrb r1,[r2]
     orr r0,r0,r1,lsl #8     
     
     add z80sp,z80sp,#\inc_sp
.endm

.macro POP_r0_r1
     ldr r2,[cpucontext,#ppMemRead]
     mov r1,z80sp,lsr#8		
     ldr r1,[r2,r1,lsl#2]
     
     cmp r1,#0
     beq end_loop
     
     add r2,r1,z80sp
     ldrb r0,[r2],#1
     ldrb r1,[r2]
     ;@orr r0,r0,r1,lsl #8     
     
     add z80sp,z80sp,#2
.endm

;@ --------------------------- Framework --------------------------

_DrZ80Run:
     ;@ r0 = pointer to cpu context
     ;@ r1 = ISTATES to execute  
     ;@#########################################   
     stmdb sp!,{r4-r12,lr}  ;@ save registers on stack
     mov cpucontext,r0       ;@ setup main memory pointer
     ldr z80a,[cpucontext,#z80a_pointer] ;@ load Z80 registers
     ldr z80f,[cpucontext,#z80f_pointer]
     ldr z80bc,[cpucontext,#z80bc_pointer]
     ldr z80de,[cpucontext,#z80de_pointer]
     ldr z80hl,[cpucontext,#z80hl_pointer]
     ldr z80sp,[cpucontext,#z80sp_pointer]
     ldr z80pc,[cpucontext,#z80pc_pointer]

     
     
     mov z80_icount,r1  ;@ setup number of Tstates to execute
     ldr opcodes,MAIN_opcodes_POINTER2
	 	 
     ldrb r0,[z80pc],#1    ;@ get first op code
     ldr pc,[opcodes,r0, lsl #2]  ;@ execute op code
     
MAIN_opcodes_POINTER2: .word MAIN_opcodes

     
z80_execute_end:
     ;@ save registers in CPU context
     str z80a,[cpucontext,#z80a_pointer]
     str z80f,[cpucontext,#z80f_pointer]
     str z80bc,[cpucontext,#z80bc_pointer]
     str z80de,[cpucontext,#z80de_pointer]
     str z80hl,[cpucontext,#z80hl_pointer]
     str z80sp,[cpucontext,#z80sp_pointer]
     str z80pc,[cpucontext,#z80pc_pointer]
     str z80_icount,[cpucontext,#nCyclesLeft]	;@ OopsWare
     mov r0, z80_icount     ;@ notaz
     ldmia sp!,{r4-r12,pc}  ;@ restore registers from stack and return to C code



DAATable: .hword  (0x00<<8)|(1<<ZFlag)|(1<<VFlag)
         .hword  (0x01<<8)                  
         .hword  (0x02<<8)                  
         .hword  (0x03<<8)               |(1<<VFlag)
         .hword  (0x04<<8)                  
         .hword  (0x05<<8)               |(1<<VFlag)
         .hword  (0x06<<8)               |(1<<VFlag)
         .hword  (0x07<<8)                  
         .hword  (0x08<<8)               
         .hword  (0x09<<8)            |(1<<VFlag)
         .hword  (0x10<<8)         |(1<<HFlag)      
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x13<<8)         |(1<<HFlag)      
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x15<<8)         |(1<<HFlag)      
         .hword  (0x10<<8)                  
         .hword  (0x11<<8)               |(1<<VFlag)
         .hword  (0x12<<8)               |(1<<VFlag)
         .hword  (0x13<<8)                  
         .hword  (0x14<<8)               |(1<<VFlag)
         .hword  (0x15<<8)                  
         .hword  (0x16<<8)                  
         .hword  (0x17<<8)               |(1<<VFlag)
         .hword  (0x18<<8)            |(1<<VFlag)
         .hword  (0x19<<8)               
         .hword  (0x20<<8)      |(1<<HFlag)      
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x23<<8)      |(1<<HFlag)      
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x25<<8)      |(1<<HFlag)      
         .hword  (0x20<<8)               
         .hword  (0x21<<8)            |(1<<VFlag)
         .hword  (0x22<<8)            |(1<<VFlag)
         .hword  (0x23<<8)               
         .hword  (0x24<<8)            |(1<<VFlag)
         .hword  (0x25<<8)               
         .hword  (0x26<<8)               
         .hword  (0x27<<8)            |(1<<VFlag)
         .hword  (0x28<<8)         |(1<<VFlag)
         .hword  (0x29<<8)            
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x31<<8)      |(1<<HFlag)      
         .hword  (0x32<<8)      |(1<<HFlag)      
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x34<<8)      |(1<<HFlag)      
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x30<<8)            |(1<<VFlag)
         .hword  (0x31<<8)               
         .hword  (0x32<<8)               
         .hword  (0x33<<8)            |(1<<VFlag)
         .hword  (0x34<<8)               
         .hword  (0x35<<8)            |(1<<VFlag)
         .hword  (0x36<<8)            |(1<<VFlag)
         .hword  (0x37<<8)               
         .hword  (0x38<<8)            
         .hword  (0x39<<8)         |(1<<VFlag)
         .hword  (0x40<<8)         |(1<<HFlag)      
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x43<<8)         |(1<<HFlag)      
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x45<<8)         |(1<<HFlag)      
         .hword  (0x40<<8)                  
         .hword  (0x41<<8)               |(1<<VFlag)
         .hword  (0x42<<8)               |(1<<VFlag)
         .hword  (0x43<<8)                  
         .hword  (0x44<<8)               |(1<<VFlag)
         .hword  (0x45<<8)                  
         .hword  (0x46<<8)                  
         .hword  (0x47<<8)               |(1<<VFlag)
         .hword  (0x48<<8)            |(1<<VFlag)
         .hword  (0x49<<8)               
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x51<<8)         |(1<<HFlag)      
         .hword  (0x52<<8)         |(1<<HFlag)      
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x54<<8)         |(1<<HFlag)      
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x50<<8)               |(1<<VFlag)
         .hword  (0x51<<8)                  
         .hword  (0x52<<8)                  
         .hword  (0x53<<8)               |(1<<VFlag)
         .hword  (0x54<<8)                  
         .hword  (0x55<<8)               |(1<<VFlag)
         .hword  (0x56<<8)               |(1<<VFlag)
         .hword  (0x57<<8)                  
         .hword  (0x58<<8)               
         .hword  (0x59<<8)            |(1<<VFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x61<<8)      |(1<<HFlag)      
         .hword  (0x62<<8)      |(1<<HFlag)      
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x64<<8)      |(1<<HFlag)      
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x60<<8)            |(1<<VFlag)
         .hword  (0x61<<8)               
         .hword  (0x62<<8)               
         .hword  (0x63<<8)            |(1<<VFlag)
         .hword  (0x64<<8)               
         .hword  (0x65<<8)            |(1<<VFlag)
         .hword  (0x66<<8)            |(1<<VFlag)
         .hword  (0x67<<8)               
         .hword  (0x68<<8)            
         .hword  (0x69<<8)         |(1<<VFlag)
         .hword  (0x70<<8)      |(1<<HFlag)      
         .hword  (0x71<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x72<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x73<<8)      |(1<<HFlag)      
         .hword  (0x74<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x75<<8)      |(1<<HFlag)      
         .hword  (0x70<<8)               
         .hword  (0x71<<8)            |(1<<VFlag)
         .hword  (0x72<<8)            |(1<<VFlag)
         .hword  (0x73<<8)               
         .hword  (0x74<<8)            |(1<<VFlag)
         .hword  (0x75<<8)               
         .hword  (0x76<<8)               
         .hword  (0x77<<8)            |(1<<VFlag)
         .hword  (0x78<<8)         |(1<<VFlag)
         .hword  (0x79<<8)            
         .hword  (0x80<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x81<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x82<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x83<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x84<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x85<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x80<<8)|(1<<SFlag)               
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x83<<8)|(1<<SFlag)               
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x85<<8)|(1<<SFlag)               
         .hword  (0x86<<8)|(1<<SFlag)               
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x89<<8)|(1<<SFlag)            
         .hword  (0x90<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x91<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x92<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x93<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x94<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x95<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x91<<8)|(1<<SFlag)               
         .hword  (0x92<<8)|(1<<SFlag)               
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x94<<8)|(1<<SFlag)               
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x97<<8)|(1<<SFlag)               
         .hword  (0x98<<8)|(1<<SFlag)            
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x02<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x03<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x05<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)                     |(1<<CFlag)
         .hword  (0x02<<8)                     |(1<<CFlag)
         .hword  (0x03<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)                     |(1<<CFlag)
         .hword  (0x05<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x07<<8)                     |(1<<CFlag)
         .hword  (0x08<<8)                  |(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x10<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x10<<8)                     |(1<<CFlag)
         .hword  (0x11<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)                     |(1<<CFlag)
         .hword  (0x14<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)                     |(1<<CFlag)
         .hword  (0x16<<8)                     |(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x19<<8)                  |(1<<CFlag)
         .hword  (0x20<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x20<<8)                  |(1<<CFlag)
         .hword  (0x21<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)                  |(1<<CFlag)
         .hword  (0x24<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)                  |(1<<CFlag)
         .hword  (0x26<<8)                  |(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x29<<8)               |(1<<CFlag)
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x32<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x30<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)                  |(1<<CFlag)
         .hword  (0x32<<8)                  |(1<<CFlag)
         .hword  (0x33<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)                  |(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x37<<8)                  |(1<<CFlag)
         .hword  (0x38<<8)               |(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x40<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x40<<8)                     |(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)                     |(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)                     |(1<<CFlag)
         .hword  (0x46<<8)                     |(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x49<<8)                  |(1<<CFlag)
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x52<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)                     |(1<<CFlag)
         .hword  (0x52<<8)                     |(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)                     |(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x57<<8)                     |(1<<CFlag)
         .hword  (0x58<<8)                  |(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x61<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x62<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x64<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x60<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x61<<8)                  |(1<<CFlag)
         .hword  (0x62<<8)                  |(1<<CFlag)
         .hword  (0x63<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x64<<8)                  |(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x67<<8)                  |(1<<CFlag)
         .hword  (0x68<<8)               |(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x70<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x71<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x72<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x73<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x74<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x75<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x70<<8)                  |(1<<CFlag)
         .hword  (0x71<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x72<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x73<<8)                  |(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x75<<8)                  |(1<<CFlag)
         .hword  (0x76<<8)                  |(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x79<<8)               |(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA0<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA1<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA2<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA3<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA0<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA1<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xA2<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xA3<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA6<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA7<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xA8<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xA9<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB0<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB1<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB2<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB3<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB0<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xB1<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB2<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB3<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xB6<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xB7<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB8<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB9<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xC0<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC1<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC2<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC3<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC0<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC1<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xC2<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xC3<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC6<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC7<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xC8<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xC9<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD0<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD1<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD2<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD3<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD0<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xD1<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD2<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD3<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xD6<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xD7<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD8<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD9<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE0<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE1<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE2<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE3<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE0<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE1<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE2<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE3<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE6<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE7<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE8<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE9<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xF0<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF1<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF2<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF3<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF0<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF1<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xF2<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xF3<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF6<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF7<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xF8<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xF9<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x02<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x03<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x05<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)                     |(1<<CFlag)
         .hword  (0x02<<8)                     |(1<<CFlag)
         .hword  (0x03<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)                     |(1<<CFlag)
         .hword  (0x05<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x07<<8)                     |(1<<CFlag)
         .hword  (0x08<<8)                  |(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x10<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x10<<8)                     |(1<<CFlag)
         .hword  (0x11<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)                     |(1<<CFlag)
         .hword  (0x14<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)                     |(1<<CFlag)
         .hword  (0x16<<8)                     |(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x19<<8)                  |(1<<CFlag)
         .hword  (0x20<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x20<<8)                  |(1<<CFlag)
         .hword  (0x21<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)                  |(1<<CFlag)
         .hword  (0x24<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)                  |(1<<CFlag)
         .hword  (0x26<<8)                  |(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x29<<8)               |(1<<CFlag)
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x32<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x30<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)                  |(1<<CFlag)
         .hword  (0x32<<8)                  |(1<<CFlag)
         .hword  (0x33<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)                  |(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x37<<8)                  |(1<<CFlag)
         .hword  (0x38<<8)               |(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x40<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x40<<8)                     |(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)                     |(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)                     |(1<<CFlag)
         .hword  (0x46<<8)                     |(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x49<<8)                  |(1<<CFlag)
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x52<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)                     |(1<<CFlag)
         .hword  (0x52<<8)                     |(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)                     |(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x57<<8)                     |(1<<CFlag)
         .hword  (0x58<<8)                  |(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x61<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x62<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x64<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)
         .hword  (0x07<<8)                  
         .hword  (0x08<<8)               
         .hword  (0x09<<8)            |(1<<VFlag)
         .hword  (0x0A<<8)            |(1<<VFlag)
         .hword  (0x0B<<8)               
         .hword  (0x0C<<8)            |(1<<VFlag)
         .hword  (0x0D<<8)               
         .hword  (0x0E<<8)               
         .hword  (0x0F<<8)            |(1<<VFlag)
         .hword  (0x10<<8)         |(1<<HFlag)      
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x13<<8)         |(1<<HFlag)      
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x15<<8)         |(1<<HFlag)      
         .hword  (0x16<<8)                  
         .hword  (0x17<<8)               |(1<<VFlag)
         .hword  (0x18<<8)            |(1<<VFlag)
         .hword  (0x19<<8)               
         .hword  (0x1A<<8)               
         .hword  (0x1B<<8)            |(1<<VFlag)
         .hword  (0x1C<<8)               
         .hword  (0x1D<<8)            |(1<<VFlag)
         .hword  (0x1E<<8)            |(1<<VFlag)
         .hword  (0x1F<<8)               
         .hword  (0x20<<8)      |(1<<HFlag)      
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x23<<8)      |(1<<HFlag)      
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x25<<8)      |(1<<HFlag)      
         .hword  (0x26<<8)               
         .hword  (0x27<<8)            |(1<<VFlag)
         .hword  (0x28<<8)         |(1<<VFlag)
         .hword  (0x29<<8)            
         .hword  (0x2A<<8)            
         .hword  (0x2B<<8)         |(1<<VFlag)
         .hword  (0x2C<<8)            
         .hword  (0x2D<<8)         |(1<<VFlag)
         .hword  (0x2E<<8)         |(1<<VFlag)
         .hword  (0x2F<<8)            
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x31<<8)      |(1<<HFlag)      
         .hword  (0x32<<8)      |(1<<HFlag)      
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x34<<8)      |(1<<HFlag)      
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x36<<8)            |(1<<VFlag)
         .hword  (0x37<<8)               
         .hword  (0x38<<8)            
         .hword  (0x39<<8)         |(1<<VFlag)
         .hword  (0x3A<<8)         |(1<<VFlag)
         .hword  (0x3B<<8)            
         .hword  (0x3C<<8)         |(1<<VFlag)
         .hword  (0x3D<<8)            
         .hword  (0x3E<<8)            
         .hword  (0x3F<<8)         |(1<<VFlag)
         .hword  (0x40<<8)         |(1<<HFlag)      
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x43<<8)         |(1<<HFlag)      
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x45<<8)         |(1<<HFlag)      
         .hword  (0x46<<8)                  
         .hword  (0x47<<8)               |(1<<VFlag)
         .hword  (0x48<<8)            |(1<<VFlag)
         .hword  (0x49<<8)               
         .hword  (0x4A<<8)               
         .hword  (0x4B<<8)            |(1<<VFlag)
         .hword  (0x4C<<8)               
         .hword  (0x4D<<8)            |(1<<VFlag)
         .hword  (0x4E<<8)            |(1<<VFlag)
         .hword  (0x4F<<8)               
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x51<<8)         |(1<<HFlag)      
         .hword  (0x52<<8)         |(1<<HFlag)      
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x54<<8)         |(1<<HFlag)      
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x56<<8)               |(1<<VFlag)
         .hword  (0x57<<8)                  
         .hword  (0x58<<8)               
         .hword  (0x59<<8)            |(1<<VFlag)
         .hword  (0x5A<<8)            |(1<<VFlag)
         .hword  (0x5B<<8)               
         .hword  (0x5C<<8)            |(1<<VFlag)
         .hword  (0x5D<<8)               
         .hword  (0x5E<<8)               
         .hword  (0x5F<<8)            |(1<<VFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x61<<8)      |(1<<HFlag)      
         .hword  (0x62<<8)      |(1<<HFlag)      
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x64<<8)      |(1<<HFlag)      
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x66<<8)            |(1<<VFlag)
         .hword  (0x67<<8)               
         .hword  (0x68<<8)            
         .hword  (0x69<<8)         |(1<<VFlag)
         .hword  (0x6A<<8)         |(1<<VFlag)
         .hword  (0x6B<<8)            
         .hword  (0x6C<<8)         |(1<<VFlag)
         .hword  (0x6D<<8)            
         .hword  (0x6E<<8)            
         .hword  (0x6F<<8)         |(1<<VFlag)
         .hword  (0x70<<8)      |(1<<HFlag)      
         .hword  (0x71<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x72<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x73<<8)      |(1<<HFlag)      
         .hword  (0x74<<8)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x75<<8)      |(1<<HFlag)      
         .hword  (0x76<<8)               
         .hword  (0x77<<8)            |(1<<VFlag)
         .hword  (0x78<<8)         |(1<<VFlag)
         .hword  (0x79<<8)            
         .hword  (0x7A<<8)            
         .hword  (0x7B<<8)         |(1<<VFlag)
         .hword  (0x7C<<8)            
         .hword  (0x7D<<8)         |(1<<VFlag)
         .hword  (0x7E<<8)         |(1<<VFlag)
         .hword  (0x7F<<8)            
         .hword  (0x80<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x81<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x82<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x83<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x84<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x85<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x86<<8)|(1<<SFlag)               
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x89<<8)|(1<<SFlag)            
         .hword  (0x8A<<8)|(1<<SFlag)            
         .hword  (0x8B<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x8C<<8)|(1<<SFlag)            
         .hword  (0x8D<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x8E<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x8F<<8)|(1<<SFlag)            
         .hword  (0x90<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x91<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x92<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x93<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x94<<8)|(1<<SFlag)      |(1<<HFlag)      
         .hword  (0x95<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)
         .hword  (0x97<<8)|(1<<SFlag)               
         .hword  (0x98<<8)|(1<<SFlag)            
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x9A<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x9B<<8)|(1<<SFlag)            
         .hword  (0x9C<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x9D<<8)|(1<<SFlag)            
         .hword  (0x9E<<8)|(1<<SFlag)            
         .hword  (0x9F<<8)|(1<<SFlag)         |(1<<VFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x02<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x03<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x05<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x07<<8)                     |(1<<CFlag)
         .hword  (0x08<<8)                  |(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0A<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0B<<8)                  |(1<<CFlag)
         .hword  (0x0C<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0D<<8)                  |(1<<CFlag)
         .hword  (0x0E<<8)                  |(1<<CFlag)
         .hword  (0x0F<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x10<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x16<<8)                     |(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x19<<8)                  |(1<<CFlag)
         .hword  (0x1A<<8)                  |(1<<CFlag)
         .hword  (0x1B<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1C<<8)                  |(1<<CFlag)
         .hword  (0x1D<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1E<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1F<<8)                  |(1<<CFlag)
         .hword  (0x20<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x26<<8)                  |(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x29<<8)               |(1<<CFlag)
         .hword  (0x2A<<8)               |(1<<CFlag)
         .hword  (0x2B<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2C<<8)               |(1<<CFlag)
         .hword  (0x2D<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2E<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2F<<8)               |(1<<CFlag)
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x32<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x37<<8)                  |(1<<CFlag)
         .hword  (0x38<<8)               |(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3A<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3B<<8)               |(1<<CFlag)
         .hword  (0x3C<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3D<<8)               |(1<<CFlag)
         .hword  (0x3E<<8)               |(1<<CFlag)
         .hword  (0x3F<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x40<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x46<<8)                     |(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x49<<8)                  |(1<<CFlag)
         .hword  (0x4A<<8)                  |(1<<CFlag)
         .hword  (0x4B<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4C<<8)                  |(1<<CFlag)
         .hword  (0x4D<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4E<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4F<<8)                  |(1<<CFlag)
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x52<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x57<<8)                     |(1<<CFlag)
         .hword  (0x58<<8)                  |(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5A<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5B<<8)                  |(1<<CFlag)
         .hword  (0x5C<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5D<<8)                  |(1<<CFlag)
         .hword  (0x5E<<8)                  |(1<<CFlag)
         .hword  (0x5F<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x61<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x62<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x64<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x67<<8)                  |(1<<CFlag)
         .hword  (0x68<<8)               |(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x6A<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x6B<<8)               |(1<<CFlag)
         .hword  (0x6C<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x6D<<8)               |(1<<CFlag)
         .hword  (0x6E<<8)               |(1<<CFlag)
         .hword  (0x6F<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x70<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x71<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x72<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x73<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x74<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x75<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x76<<8)                  |(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x79<<8)               |(1<<CFlag)
         .hword  (0x7A<<8)               |(1<<CFlag)
         .hword  (0x7B<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x7C<<8)               |(1<<CFlag)
         .hword  (0x7D<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x7E<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x7F<<8)               |(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x8A<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x8B<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x8C<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x8D<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x8E<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x8F<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x9A<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x9B<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x9C<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x9D<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x9E<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0x9F<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA0<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA1<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA2<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA3<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA6<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xA7<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xA8<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xA9<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xAA<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xAB<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xAC<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xAD<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xAE<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xAF<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB0<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB1<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB2<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB3<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xB6<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xB7<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB8<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xB9<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xBA<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xBB<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xBC<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xBD<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xBE<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xBF<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xC0<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC1<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC2<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC3<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC6<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xC7<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xC8<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xC9<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xCA<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xCB<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xCC<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xCD<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xCE<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xCF<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD0<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD1<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD2<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD3<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xD6<<8)|(1<<SFlag)                  |(1<<CFlag)
         .hword  (0xD7<<8)|(1<<SFlag)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD8<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xD9<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xDA<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xDB<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xDC<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xDD<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xDE<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xDF<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE0<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE1<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE2<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE3<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xE6<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xE7<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE8<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xE9<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xEA<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xEB<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xEC<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xED<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xEE<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xEF<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xF0<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF1<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF2<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF3<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)   |(1<<HFlag)         |(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF6<<8)|(1<<SFlag)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xF7<<8)|(1<<SFlag)               |(1<<CFlag)
         .hword  (0xF8<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xF9<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xFA<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xFB<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xFC<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0xFD<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xFE<<8)|(1<<SFlag)            |(1<<CFlag)
         .hword  (0xFF<<8)|(1<<SFlag)      |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)   |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x01<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x02<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x03<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x04<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x05<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x07<<8)                     |(1<<CFlag)
         .hword  (0x08<<8)                  |(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0A<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0B<<8)                  |(1<<CFlag)
         .hword  (0x0C<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x0D<<8)                  |(1<<CFlag)
         .hword  (0x0E<<8)                  |(1<<CFlag)
         .hword  (0x0F<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x10<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x11<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x12<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x13<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x14<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x15<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x16<<8)                     |(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x19<<8)                  |(1<<CFlag)
         .hword  (0x1A<<8)                  |(1<<CFlag)
         .hword  (0x1B<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1C<<8)                  |(1<<CFlag)
         .hword  (0x1D<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1E<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x1F<<8)                  |(1<<CFlag)
         .hword  (0x20<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x21<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x22<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x23<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x24<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x25<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x26<<8)                  |(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x29<<8)               |(1<<CFlag)
         .hword  (0x2A<<8)               |(1<<CFlag)
         .hword  (0x2B<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2C<<8)               |(1<<CFlag)
         .hword  (0x2D<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2E<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x2F<<8)               |(1<<CFlag)
         .hword  (0x30<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x31<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x32<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x33<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x34<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x35<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x37<<8)                  |(1<<CFlag)
         .hword  (0x38<<8)               |(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3A<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3B<<8)               |(1<<CFlag)
         .hword  (0x3C<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x3D<<8)               |(1<<CFlag)
         .hword  (0x3E<<8)               |(1<<CFlag)
         .hword  (0x3F<<8)         |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x40<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x41<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x42<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x43<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x44<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x45<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x46<<8)                     |(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x49<<8)                  |(1<<CFlag)
         .hword  (0x4A<<8)                  |(1<<CFlag)
         .hword  (0x4B<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4C<<8)                  |(1<<CFlag)
         .hword  (0x4D<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4E<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x4F<<8)                  |(1<<CFlag)
         .hword  (0x50<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x51<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x52<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x53<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x54<<8)         |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x55<<8)         |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x57<<8)                     |(1<<CFlag)
         .hword  (0x58<<8)                  |(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5A<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5B<<8)                  |(1<<CFlag)
         .hword  (0x5C<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x5D<<8)                  |(1<<CFlag)
         .hword  (0x5E<<8)                  |(1<<CFlag)
         .hword  (0x5F<<8)            |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x60<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x61<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x62<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x63<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x64<<8)      |(1<<HFlag)         |(1<<CFlag)
         .hword  (0x65<<8)      |(1<<HFlag)   |(1<<VFlag)   |(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x01<<8)                  |(1<<NFlag)   
         .hword  (0x02<<8)                  |(1<<NFlag)   
         .hword  (0x03<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x04<<8)                  |(1<<NFlag)   
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x07<<8)                  |(1<<NFlag)   
         .hword  (0x08<<8)               |(1<<NFlag)   
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x04<<8)                  |(1<<NFlag)   
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x07<<8)                  |(1<<NFlag)   
         .hword  (0x08<<8)               |(1<<NFlag)   
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x10<<8)                  |(1<<NFlag)   
         .hword  (0x11<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x12<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x13<<8)                  |(1<<NFlag)   
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x15<<8)                  |(1<<NFlag)   
         .hword  (0x16<<8)                  |(1<<NFlag)   
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x19<<8)               |(1<<NFlag)   
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x15<<8)                  |(1<<NFlag)   
         .hword  (0x16<<8)                  |(1<<NFlag)   
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x19<<8)               |(1<<NFlag)   
         .hword  (0x20<<8)               |(1<<NFlag)   
         .hword  (0x21<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x22<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x23<<8)               |(1<<NFlag)   
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x25<<8)               |(1<<NFlag)   
         .hword  (0x26<<8)               |(1<<NFlag)   
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x29<<8)            |(1<<NFlag)   
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x25<<8)               |(1<<NFlag)   
         .hword  (0x26<<8)               |(1<<NFlag)   
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x29<<8)            |(1<<NFlag)   
         .hword  (0x30<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x31<<8)               |(1<<NFlag)   
         .hword  (0x32<<8)               |(1<<NFlag)   
         .hword  (0x33<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x34<<8)               |(1<<NFlag)   
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x37<<8)               |(1<<NFlag)   
         .hword  (0x38<<8)            |(1<<NFlag)   
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x34<<8)               |(1<<NFlag)   
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x37<<8)               |(1<<NFlag)   
         .hword  (0x38<<8)            |(1<<NFlag)   
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x40<<8)                  |(1<<NFlag)   
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x43<<8)                  |(1<<NFlag)   
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x45<<8)                  |(1<<NFlag)   
         .hword  (0x46<<8)                  |(1<<NFlag)   
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x49<<8)               |(1<<NFlag)   
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x45<<8)                  |(1<<NFlag)   
         .hword  (0x46<<8)                  |(1<<NFlag)   
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x49<<8)               |(1<<NFlag)   
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x51<<8)                  |(1<<NFlag)   
         .hword  (0x52<<8)                  |(1<<NFlag)   
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x54<<8)                  |(1<<NFlag)   
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x57<<8)                  |(1<<NFlag)   
         .hword  (0x58<<8)               |(1<<NFlag)   
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x54<<8)                  |(1<<NFlag)   
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x57<<8)                  |(1<<NFlag)   
         .hword  (0x58<<8)               |(1<<NFlag)   
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x61<<8)               |(1<<NFlag)   
         .hword  (0x62<<8)               |(1<<NFlag)   
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x64<<8)               |(1<<NFlag)   
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x67<<8)               |(1<<NFlag)   
         .hword  (0x68<<8)            |(1<<NFlag)   
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x64<<8)               |(1<<NFlag)   
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x67<<8)               |(1<<NFlag)   
         .hword  (0x68<<8)            |(1<<NFlag)   
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x70<<8)               |(1<<NFlag)   
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x73<<8)               |(1<<NFlag)   
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x75<<8)               |(1<<NFlag)   
         .hword  (0x76<<8)               |(1<<NFlag)   
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x79<<8)            |(1<<NFlag)   
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x75<<8)               |(1<<NFlag)   
         .hword  (0x76<<8)               |(1<<NFlag)   
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x79<<8)            |(1<<NFlag)   
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)   
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)   
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)   
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x34<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x37<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x38<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x40<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x43<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x51<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x52<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x61<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x62<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x70<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x73<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA0<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA1<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA2<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA3<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB0<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB1<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB2<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB3<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC0<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC1<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC2<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC3<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC6<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC7<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC8<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC9<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC6<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC7<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC8<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC9<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD0<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD1<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD2<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD3<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD6<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD7<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD8<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD9<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD6<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD7<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD8<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD9<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE0<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE1<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE2<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE3<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF0<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF1<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF2<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF3<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x01<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x02<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x03<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x04<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x07<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x08<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x04<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x07<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x08<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x10<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x11<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x12<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x13<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x15<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x16<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x19<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x15<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x16<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x19<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x20<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x21<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x22<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x23<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x25<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x26<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x29<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x25<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x26<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x29<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x30<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x31<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x32<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x33<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x34<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x37<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x38<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x34<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x37<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x38<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x40<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x43<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x51<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x52<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x61<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x62<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x70<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x73<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xFA<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0xFB<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0xFC<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0xFD<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0xFE<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0xFF<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x01<<8)                  |(1<<NFlag)   
         .hword  (0x02<<8)                  |(1<<NFlag)   
         .hword  (0x03<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x04<<8)                  |(1<<NFlag)   
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x07<<8)                  |(1<<NFlag)   
         .hword  (0x08<<8)               |(1<<NFlag)   
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x0A<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x0B<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x0C<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x0D<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x0E<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x0F<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x10<<8)                  |(1<<NFlag)   
         .hword  (0x11<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x12<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x13<<8)                  |(1<<NFlag)   
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x15<<8)                  |(1<<NFlag)   
         .hword  (0x16<<8)                  |(1<<NFlag)   
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x19<<8)               |(1<<NFlag)   
         .hword  (0x1A<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x1B<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x1C<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x1D<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x1E<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x1F<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x20<<8)               |(1<<NFlag)   
         .hword  (0x21<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x22<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x23<<8)               |(1<<NFlag)   
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x25<<8)               |(1<<NFlag)   
         .hword  (0x26<<8)               |(1<<NFlag)   
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x29<<8)            |(1<<NFlag)   
         .hword  (0x2A<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x2B<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x2C<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x2D<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x2E<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x2F<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x30<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x31<<8)               |(1<<NFlag)   
         .hword  (0x32<<8)               |(1<<NFlag)   
         .hword  (0x33<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x34<<8)               |(1<<NFlag)   
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x37<<8)               |(1<<NFlag)   
         .hword  (0x38<<8)            |(1<<NFlag)   
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x3A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x3B<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x3C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x3D<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x3E<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x3F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x40<<8)                  |(1<<NFlag)   
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x43<<8)                  |(1<<NFlag)   
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x45<<8)                  |(1<<NFlag)   
         .hword  (0x46<<8)                  |(1<<NFlag)   
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x49<<8)               |(1<<NFlag)   
         .hword  (0x4A<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x4B<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x4C<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x4D<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x4E<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x4F<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x51<<8)                  |(1<<NFlag)   
         .hword  (0x52<<8)                  |(1<<NFlag)   
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x54<<8)                  |(1<<NFlag)   
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x57<<8)                  |(1<<NFlag)   
         .hword  (0x58<<8)               |(1<<NFlag)   
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x5A<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x5B<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x5C<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x5D<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x5E<<8)         |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x5F<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x61<<8)               |(1<<NFlag)   
         .hword  (0x62<<8)               |(1<<NFlag)   
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x64<<8)               |(1<<NFlag)   
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x67<<8)               |(1<<NFlag)   
         .hword  (0x68<<8)            |(1<<NFlag)   
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x6A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x6B<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x6C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x6D<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x6E<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x6F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x70<<8)               |(1<<NFlag)   
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x73<<8)               |(1<<NFlag)   
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x75<<8)               |(1<<NFlag)   
         .hword  (0x76<<8)               |(1<<NFlag)   
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x79<<8)            |(1<<NFlag)   
         .hword  (0x7A<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x7B<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x7C<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x7D<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x7E<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x7F<<8)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)   
         .hword  (0x8A<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x8B<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x8C<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x8D<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x8E<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)   
         .hword  (0x8F<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)   
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)   
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)   
         .hword  (0x34<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x37<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x38<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3B<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3D<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3E<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x40<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x43<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4A<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4B<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4C<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4D<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4E<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4F<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x51<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x52<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5A<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5B<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5C<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5D<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5E<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5F<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x61<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x62<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6B<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6D<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6E<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x70<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x73<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7A<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7B<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7C<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7D<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7E<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7F<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8A<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8B<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8C<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8D<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8E<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8F<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x9A<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x9B<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x9C<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x9D<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x9E<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x9F<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA0<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA1<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA2<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA3<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xA7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xA9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xAA<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xAB<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xAC<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xAD<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xAE<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xAF<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB0<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB1<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB2<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB3<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xB7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xB9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xBA<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xBB<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xBC<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xBD<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xBE<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xBF<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC0<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC1<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC2<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC3<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC4<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC5<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC6<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xC7<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC8<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xC9<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xCA<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xCB<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xCC<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xCD<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xCE<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xCF<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD0<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD1<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD2<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD3<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD4<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD5<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD6<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0xD7<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD8<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xD9<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xDA<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xDB<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xDC<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xDD<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xDE<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xDF<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE0<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE1<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE2<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE3<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE4<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE5<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE6<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xE7<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE8<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xE9<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xEA<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xEB<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xEC<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xED<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xEE<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xEF<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF0<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF1<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF2<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF3<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF4<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF5<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF6<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xF7<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF8<<8)|(1<<SFlag)         |(1<<NFlag)|(1<<CFlag)
         .hword  (0xF9<<8)|(1<<SFlag)      |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xFA<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xFB<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xFC<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0xFD<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xFE<<8)|(1<<SFlag)   |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0xFF<<8)|(1<<SFlag)   |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x00<<8)   |(1<<ZFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x01<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x02<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x03<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x04<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x05<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x06<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x07<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x08<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x09<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x0A<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x0B<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x0C<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x0D<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x0E<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x0F<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x10<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x11<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x12<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x13<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x14<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x15<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x16<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x17<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x18<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x19<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x1A<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x1B<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x1C<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x1D<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x1E<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x1F<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x20<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x21<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x22<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x23<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x24<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x25<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x26<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x27<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x28<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x29<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x2A<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x2B<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x2C<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x2D<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x2E<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x2F<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x30<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x31<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x32<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x33<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x34<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x35<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x36<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x37<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x38<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x39<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3B<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x3D<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3E<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x3F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x40<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x41<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x42<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x43<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x44<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x45<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x46<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x47<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x48<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x49<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4A<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4B<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4C<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x4D<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4E<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x4F<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x50<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x51<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x52<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x53<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x54<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x55<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x56<<8)               |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x57<<8)                  |(1<<NFlag)|(1<<CFlag)
         .hword  (0x58<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x59<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5A<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5B<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5C<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x5D<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5E<<8)         |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x5F<<8)         |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x60<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x61<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x62<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x63<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x64<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x65<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x66<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x67<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x68<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x69<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6A<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6B<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6C<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x6D<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6E<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x6F<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x70<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x71<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x72<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x73<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x74<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x75<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x76<<8)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x77<<8)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x78<<8)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x79<<8)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7A<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7B<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7C<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x7D<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7E<<8)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x7F<<8)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x80<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x81<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x82<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x83<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x84<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x85<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x86<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x87<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x88<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x89<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8A<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8B<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8C<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x8D<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8E<<8)|(1<<SFlag)      |(1<<HFlag)|(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x8F<<8)|(1<<SFlag)      |(1<<HFlag)   |(1<<NFlag)|(1<<CFlag)
         .hword  (0x90<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x91<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x92<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x93<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x94<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x95<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x96<<8)|(1<<SFlag)            |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         .hword  (0x97<<8)|(1<<SFlag)               |(1<<NFlag)|(1<<CFlag)
         .hword  (0x98<<8)|(1<<SFlag)            |(1<<NFlag)|(1<<CFlag)
         .hword  (0x99<<8)|(1<<SFlag)         |(1<<VFlag)|(1<<NFlag)|(1<<CFlag)
         
AF_Z80:  .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 0
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 1
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 2
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 3
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 4
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 5
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 6
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 7
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 8
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 9
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 10
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 11
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 12
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 13
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 14
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 15
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 16
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 17
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 18
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 19
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 20
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 21
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 22
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 23
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 24
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 25
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 26
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 27
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 28
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 29
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 30
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 31
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 32
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 33
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 34
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 35
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 36
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 37
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 38
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 39
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 40
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 41
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 42
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 43
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 44
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 45
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 46
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 47
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 48
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 49
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 50
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 51
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 52
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 53
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 54
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 55
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 56
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 57
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 58
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 59
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 60
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 61
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 62
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 63
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 64
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 65
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 66
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 67
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 68
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 69
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 70
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 71
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 72
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 73
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 74
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 75
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 76
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 77
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 78
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 79
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 80
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 81
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 82
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 83
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 84
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 85
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 86
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 87
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 88
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 89
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 90
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 91
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 92
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 93
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 94
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 95
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 96
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 97
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 98
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 99
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 100
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 101
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 102
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 103
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 104
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 105
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 106
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 107
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 108
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 109
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 110
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 111
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 112
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 113
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 114
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 115
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 116
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 117
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 118
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 119
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 120
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 121
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 122
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 123
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 124
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 125
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 126
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 127
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 128
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 129
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 130
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 131
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 132
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 133
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 134
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 135
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 136
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 137
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 138
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 139
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 140
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 141
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 142
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 143
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 144
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 145
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 146
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 147
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 148
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 149
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 150
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 151
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 152
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 153
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 154
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 155
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 156
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 157
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 158
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 159
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 160
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 161
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 162
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 163
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 164
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 165
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 166
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 167
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 168
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 169
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 170
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 171
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 172
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 173
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 174
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 175
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 176
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 177
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 178
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 179
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 180
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 181
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 182
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 183
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 184
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 185
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 186
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 187
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 188
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 189
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 190
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 191
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 192
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 193
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 194
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 195
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 196
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 197
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 198
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 199
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 200
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 201
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 202
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 203
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 204
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 205
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 206
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 207
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 208
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 209
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 210
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 211
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 212
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 213
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 214
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 215
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 216
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 217
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 218
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 219
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 220
         .byte (0<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 221
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 222
         .byte (1<<Z80_CFlag)|(0<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 223
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 224
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 225
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 226
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 227
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 228
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 229
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 230
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 231
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 232
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 233
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 234
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 235
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 236
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 237
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 238
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(0<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 239
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 240
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 241
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 242
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 243
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 244
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 245
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 246
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(0<<Z80_SFlag) ;@ 247
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 248
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 249
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 250
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(0<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 251
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 252
         .byte (0<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 253
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(0<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 254
         .byte (1<<Z80_CFlag)|(1<<Z80_NFlag)|(1<<Z80_VFlag)|(1<<Z80_HFlag)|(1<<Z80_ZFlag)|(1<<Z80_SFlag) ;@ 255

AF_ARM:  .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 0
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 1
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 2
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 3
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 4
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 5
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 6
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 7
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 8
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 9
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 10
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 11
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 12
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 13
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 14
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 15
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 16
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 17
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 18
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 19
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 20
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 21
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 22
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 23
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 24
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 25
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 26
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 27
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 28
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 29
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 30
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 31
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 32
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 33
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 34
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 35
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 36
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 37
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 38
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 39
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 40
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 41
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 42
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 43
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 44
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 45
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 46
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 47
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 48
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 49
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 50
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 51
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 52
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 53
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 54
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 55
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 56
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 57
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 58
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 59
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 60
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 61
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 62
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(0<<SFlag)  ;@ 63
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 64
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 65
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 66
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 67
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 68
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 69
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 70
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 71
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 72
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 73
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 74
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 75
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 76
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 77
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 78
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 79
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 80
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 81
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 82
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 83
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 84
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 85
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 86
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 87
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 88
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 89
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 90
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 91
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 92
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 93
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 94
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 95
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 96
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 97
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 98
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 99
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 100
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 101
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 102
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 103
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 104
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 105
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 106
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 107
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 108
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 109
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 110
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 111
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 112
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 113
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 114
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 115
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 116
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 117
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 118
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 119
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 120
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 121
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 122
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 123
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 124
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 125
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 126
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(0<<SFlag)  ;@ 127
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 128
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 129
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 130
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 131
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 132
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 133
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 134
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 135
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 136
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 137
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 138
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 139
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 140
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 141
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 142
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 143
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 144
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 145
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 146
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 147
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 148
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 149
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 150
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 151
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 152
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 153
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 154
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 155
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 156
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 157
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 158
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 159
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 160
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 161
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 162
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 163
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 164
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 165
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 166
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 167
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 168
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 169
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 170
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 171
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 172
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 173
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 174
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 175
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 176
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 177
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 178
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 179
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 180
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 181
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 182
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 183
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 184
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 185
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 186
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 187
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 188
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 189
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 190
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(0<<ZFlag)|(1<<SFlag)  ;@ 191
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 192
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 193
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 194
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 195
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 196
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 197
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 198
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 199
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 200
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 201
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 202
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 203
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 204
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 205
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 206
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 207
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 208
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 209
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 210
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 211
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 212
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 213
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 214
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 215
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 216
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 217
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 218
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 219
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 220
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 221
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 222
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 223
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 224
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 225
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 226
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 227
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 228
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 229
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 230
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 231
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 232
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 233
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 234
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 235
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 236
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 237
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 238
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(0<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 239
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 240
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 241
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 242
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 243
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 244
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 245
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 246
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 247
         .byte (0<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 248
         .byte (1<<CFlag)|(0<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 249
         .byte (0<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 250
         .byte (1<<CFlag)|(1<<NFlag)|(0<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 251
         .byte (0<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 252
         .byte (1<<CFlag)|(0<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 253
         .byte (0<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 254
         .byte (1<<CFlag)|(1<<NFlag)|(1<<VFlag)|(1<<HFlag)|(1<<ZFlag)|(1<<SFlag)  ;@ 255

PZSTable_data: .byte (1<<ZFlag)|(1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0
	.byte  0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag)
	.byte  0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0
	.byte  0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0
	.byte  (1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag)
	.byte  0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0
	.byte  (1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag)
	.byte  (1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag)
	.byte  0,(1<<VFlag),(1<<VFlag),0,(1<<VFlag),0,0,(1<<VFlag),(1<<VFlag),0,0,(1<<VFlag),0,(1<<VFlag),(1<<VFlag),0
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)|(1<<VFlag),(1<<SFlag)
	.byte  (1<<SFlag)|(1<<VFlag),(1<<SFlag),(1<<SFlag),(1<<SFlag)|(1<<VFlag)       
MAIN_opcodes:	
 	 .word opcode_0_0,opcode_0_1,opcode_0_2,opcode_0_3,opcode_0_4,opcode_0_5,opcode_0_6,opcode_0_7
     .word opcode_0_8,opcode_0_9,opcode_0_A,opcode_0_B,opcode_0_C,opcode_0_D,opcode_0_E,opcode_0_F
     .word opcode_1_0,opcode_1_1,opcode_1_2,opcode_1_3,opcode_1_4,opcode_1_5,opcode_1_6,opcode_1_7
     .word opcode_1_8,opcode_1_9,opcode_1_A,opcode_1_B,opcode_1_C,opcode_1_D,opcode_1_E,opcode_1_F
     .word opcode_2_0,opcode_2_1,opcode_2_2,opcode_2_3,opcode_2_4,opcode_2_5,opcode_2_6,opcode_2_7
     .word opcode_2_8,opcode_2_9,opcode_2_A,opcode_2_B,opcode_2_C,opcode_2_D,opcode_2_E,opcode_2_F
     .word opcode_3_0,opcode_3_1,opcode_3_2,opcode_3_3,opcode_3_4,opcode_3_5,opcode_3_6,opcode_3_7
     .word opcode_3_8,opcode_3_9,opcode_3_A,opcode_3_B,opcode_3_C,opcode_3_D,opcode_3_E,opcode_3_F
     .word opcode_4_0,opcode_4_1,opcode_4_2,opcode_4_3,opcode_4_4,opcode_4_5,opcode_4_6,opcode_4_7
     .word opcode_4_8,opcode_4_9,opcode_4_A,opcode_4_B,opcode_4_C,opcode_4_D,opcode_4_E,opcode_4_F
     .word opcode_5_0,opcode_5_1,opcode_5_2,opcode_5_3,opcode_5_4,opcode_5_5,opcode_5_6,opcode_5_7
     .word opcode_5_8,opcode_5_9,opcode_5_A,opcode_5_B,opcode_5_C,opcode_5_D,opcode_5_E,opcode_5_F
     .word opcode_6_0,opcode_6_1,opcode_6_2,opcode_6_3,opcode_6_4,opcode_6_5,opcode_6_6,opcode_6_7
     .word opcode_6_8,opcode_6_9,opcode_6_A,opcode_6_B,opcode_6_C,opcode_6_D,opcode_6_E,opcode_6_F
     .word opcode_7_0,opcode_7_1,opcode_7_2,opcode_7_3,opcode_7_4,opcode_7_5,opcode_7_6,opcode_7_7
     .word opcode_7_8,opcode_7_9,opcode_7_A,opcode_7_B,opcode_7_C,opcode_7_D,opcode_7_E,opcode_7_F
     .word opcode_8_0,opcode_8_1,opcode_8_2,opcode_8_3,opcode_8_4,opcode_8_5,opcode_8_6,opcode_8_7
     .word opcode_8_8,opcode_8_9,opcode_8_A,opcode_8_B,opcode_8_C,opcode_8_D,opcode_8_E,opcode_8_F
     .word opcode_9_0,opcode_9_1,opcode_9_2,opcode_9_3,opcode_9_4,opcode_9_5,opcode_9_6,opcode_9_7
     .word opcode_9_8,opcode_9_9,opcode_9_A,opcode_9_B,opcode_9_C,opcode_9_D,opcode_9_E,opcode_9_F
     .word opcode_A_0,opcode_A_1,opcode_A_2,opcode_A_3,opcode_A_4,opcode_A_5,opcode_A_6,opcode_A_7
     .word opcode_A_8,opcode_A_9,opcode_A_A,opcode_A_B,opcode_A_C,opcode_A_D,opcode_A_E,opcode_A_F
     .word opcode_B_0,opcode_B_1,opcode_B_2,opcode_B_3,opcode_B_4,opcode_B_5,opcode_B_6,opcode_B_7
     .word opcode_B_8,opcode_B_9,opcode_B_A,opcode_B_B,opcode_B_C,opcode_B_D,opcode_B_E,opcode_B_F
     .word opcode_C_0,opcode_C_1,opcode_C_2,opcode_C_3,opcode_C_4,opcode_C_5,opcode_C_6,opcode_C_7
     .word opcode_C_8,opcode_C_9,opcode_C_A,opcode_C_B,opcode_C_C,opcode_C_D,opcode_C_E,opcode_C_F
     .word opcode_D_0,opcode_D_1,opcode_D_2,opcode_D_3,opcode_D_4,opcode_D_5,opcode_D_6,opcode_D_7
     .word opcode_D_8,opcode_D_9,opcode_D_A,opcode_D_B,opcode_D_C,opcode_D_D,opcode_D_E,opcode_D_F
     .word opcode_E_0,opcode_E_1,opcode_E_2,opcode_E_3,opcode_E_4,opcode_E_5,opcode_E_6,opcode_E_7
     .word opcode_E_8,opcode_E_9,opcode_E_A,opcode_E_B,opcode_E_C,opcode_E_D,opcode_E_E,opcode_E_F
     .word opcode_F_0,opcode_F_1,opcode_F_2,opcode_F_3,opcode_F_4,opcode_F_5,opcode_F_6,opcode_F_7
     .word opcode_F_8,opcode_F_9,opcode_F_A,opcode_F_B,opcode_F_C,opcode_F_D,opcode_F_E,opcode_F_F


;@NOP
opcode_0_0:
;@LD B,B
opcode_4_0:
;@LD C,C
opcode_4_9:
;@LD D,D
opcode_5_2:
;@LD E,E
opcode_5_B:
;@LD H,H
opcode_6_4:
;@LD L,L
opcode_6_D:
;@LD A,A
opcode_7_F:
     fetch 4
;@LD BC,NN
opcode_0_1:
     DAM_FETCH16D r0
     mov z80bc,r0, lsl #16
     fetch 10
;@LD (BC),A
opcode_0_2:
     mov r1,z80bc, lsr #16
     mov r0,z80a, lsr #24
     DAM_WRITE8 Op02
     fetch 7
;@INC BC
opcode_0_3:
     add z80bc,z80bc,#1<<16
     fetch 6
;@INC B
opcode_0_4:
     and r0,z80bc,#0xFF<<24
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 4
;@DEC B
opcode_0_5:
     and r0,z80bc,#0xFF<<24
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 4
;@LD B,N
opcode_0_6:
     DAM_FETCH8D r0
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 7
;@RLCA
opcode_0_7:
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)|(1<<CFlag)
     movs z80a,z80a, lsl #1
     orrcs z80a,z80a,#1<<24
     orrcs z80f,z80f,#1<<CFlag
     fetch 4
;@EX AF,AF'     
opcode_0_8:
     add r1,cpucontext,#z80a2
     swp z80a,z80a,[r1]
     add r1,cpucontext,#z80f2
     swp z80f,z80f,[r1]
     fetch 4
;@ADD HL,BC
opcode_0_9:
     mov r0,z80hl
     adds z80hl,z80hl,z80bc
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     orrcs z80f,z80f,#1<<CFlag
     eor r0,r0,z80bc
     eor r0,r0,z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 11
;@LD A,(BC)
opcode_0_A:
     mov r0,z80bc, lsr #16
     DAM_READ8 Op0A
     mov z80a,r0, lsl #24
     fetch 7
;@DEC BC
opcode_0_B:
     sub z80bc,z80bc,#1<<16
     fetch 6
;@INC C
opcode_0_C:
     mov r2,z80bc, lsl #8
     adds r2,r2,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r2,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r2, lsr #8
     fetch 4
;@DEC C
opcode_0_D:
     mov r0,z80bc, lsl #8
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsr #8
     fetch 4
;@LD C,N
opcode_0_E:
     DAM_FETCH8D r0
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 7
;@RRCA
opcode_0_F:
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)|(1<<CFlag)
     movs z80a,z80a, lsr #25
     orrcs z80a,z80a,#1<<7
     orrcs z80f,z80f,#1<<CFlag
     mov z80a,z80a, lsl #24
     fetch 4
;@DJNZ $+2
;@ ?????
opcode_1_0:
     sub z80bc,z80bc,#1<<24					;@ Dec z80bc
     add z80pc,z80pc,#1
     tst z80bc,#0xFF<<24
     beq opcode_1_0_skip
     ;@ldrsb r1,[z80pc,#-1]
     ;@add z80pc,z80pc,r1
     sub z80pc,z80pc,#1
     DAM_FETCH8D_S 1
     add z80pc,z80pc,r0
opcode_1_0_skip:
     fetch 13
    
;@LD DE,NN
opcode_1_1:
     DAM_FETCH16D r0
     mov z80de,r0, lsl #16
     fetch 10
;@LD (DE),A
opcode_1_2:
     mov r1,z80de, lsr #16
     mov r0,z80a, lsr #24
     DAM_WRITE8 Op12
     fetch 7
;@INC DE
opcode_1_3:
     add z80de,z80de,#1<<16
     fetch 6
;@INC D
opcode_1_4:
     and r0,z80de,#0xFF<<24
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 4
;@DEC D
opcode_1_5:
     and r0,z80de,#0xFF<<24
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 4
;@LD D,N
opcode_1_6:
     DAM_FETCH8D r0
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 7
;@RLA
opcode_1_7:
     tst z80f,#1<<CFlag
     orrne z80a,z80a,#1<<23
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)|(1<<CFlag)
     movs z80a,z80a, lsl #1
     orrcs z80f,z80f,#1<<CFlag
     fetch 4
;@JR $+2
opcode_1_8:
     DAM_FETCH8D_S 1
     add z80pc,z80pc,r0
     fetch 12
;@ADD HL,DE
opcode_1_9:
     mov r0,z80hl
     adds z80hl,z80hl,z80de
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     orrcs z80f,z80f,#1<<CFlag
     eor r0,r0,z80de
     eor r0,r0,z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 11
;@LD A,(DE)
opcode_1_A:
     mov r0,z80de, lsr #16
     DAM_READ8 Op1A
     mov z80a,r0, lsl #24
     fetch 7
;@DEC DE
opcode_1_B:
     sub z80de,z80de,#1<<16
     fetch 6
;@INC E
opcode_1_C:
     mov r2,z80de, lsl #8
     adds r2,r2,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r2,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r2, lsr #8
     fetch 4
;@DEC E
opcode_1_D:
     mov r0,z80de, lsl #8
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsr #8
     fetch 4
;@LD E,N
opcode_1_E:
     DAM_FETCH8D r0
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 7
;@RRA
opcode_1_F:
     mov z80a,z80a, lsr #24
     tst z80f,#1<<CFlag
     orrne z80a,z80a,#1<<8 
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)|(1<<CFlag)  
     movs z80a,z80a, lsr #1
     orrcs z80f,z80f,#1<<CFlag
     mov z80a,z80a, lsl #24
     fetch 4
;@JR NZ,$+2
opcode_2_0:
     tst z80f,#1<<ZFlag
     beq opcode_1_8
     add z80pc,z80pc,#1
     fetch 7
;@LD HL,NN
opcode_2_1:
     DAM_FETCH16D r0
     mov z80hl,r0, lsl #16
     fetch 10
;@LD (NN),HL
opcode_ED_63:
     sub z80_icount,z80_icount,#4
;@LD (NN),HL
opcode_2_2:
     DAM_FETCH16D r1
     mov r0,z80hl, lsr #16
     DAM_WRITE16 Op22
     fetch 16
;@INC HL
opcode_2_3:
     add z80hl,z80hl,#1<<16
     fetch 6
;@INC H
opcode_2_4:
     and r0,z80hl,#0xFF<<24
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 4
;@DEC H
opcode_2_5:
     and r0,z80hl,#0xFF<<24
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 4
;@LD H,N
opcode_2_6:
     DAM_FETCH8D r0
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 7
DAATABLE_LOCAL: .word DAATable
;@DAA
opcode_2_7:
     mov r1,z80a, lsr #24
     tst z80f,#1<<CFlag
     orrne r1,r1,#256
     tst z80f,#1<<HFlag
     orrne r1,r1,#512
     tst z80f,#1<<NFlag
     orrne r1,r1,#1024
     ldr r2,DAATABLE_LOCAL
     add r2,r2,r1, lsl #1
     ldrh r1,[r2]
     and z80f,r1,#0xFF
     and r2,r1,#0xFF<<8
     mov z80a,r2, lsl #16
     fetch 4
;@JR Z,$+2
opcode_2_8:
     tst z80f,#1<<ZFlag
     bne opcode_1_8
     add z80pc,z80pc,#1
     fetch 7
;@ADD HL,HL
opcode_2_9:
     mov r0,z80hl
     adds z80hl,z80hl,z80hl
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     orrcs z80f,z80f,#1<<CFlag
     eor r0,r0,r0
     eor r0,r0,z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 11
;@LD HL,(NN)
opcode_ED_6B:
     sub z80_icount,z80_icount,#4
;@LD HL,(NN)
opcode_2_A:
     DAM_FETCH16D r0
     DAM_READ16 Op2A
     mov z80hl,r0, lsl #16
     fetch 16
;@DEC HL
opcode_2_B:
     sub z80hl,z80hl,#1<<16
     fetch 6
;@INC L
opcode_2_C:
     mov r2,z80hl, lsl #8
     adds r2,r2,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r2,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r2, lsr #8
     fetch 4
;@DEC L
opcode_2_D:
     mov r0,z80hl, lsl #8
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsr #8
     fetch 4
;@LD L,N
opcode_2_E:
     DAM_FETCH8D r0
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 7
;@CPL
opcode_2_F:
     eor z80a,z80a,#0xFF<<24
     orr z80f,z80f,#(1<<NFlag)|(1<<HFlag)
     fetch 4
;@JR NC,$+2
opcode_3_0:
     tst z80f,#1<<CFlag
     beq opcode_1_8
     add z80pc,z80pc,#1
     fetch 7
;@LD SP,NN
opcode_3_1:
     DAM_FETCH16D z80sp
     fetch 10
;@LD (NN),A
opcode_3_2:
     DAM_FETCH16D r1
     mov r0,z80a, lsr #24
     DAM_WRITE8 Op32
     fetch 13
;@INC SP
opcode_3_3:
     add z80sp,z80sp,#1
     fetch 6
;@INC (HL)
opcode_3_4:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op34
     mov r0,r0, lsl #24
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 Op34
     fetch 11
;@DEC (HL)
opcode_3_5:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op35
     mov r0,r0, lsl #24
     subs r0,r0,#1<<24
     mrs r2,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r2, lsr #28
     and r2,r0,#0xF<<24
     teq r2,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 Op35
     fetch 11
;@LD (HL),N
opcode_3_6:
     DAM_FETCH8D r0
     mov r1,z80hl, lsr #16
     DAM_WRITE8 Op36
     fetch 10
;@SCF
opcode_3_7:
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)
     orr z80f,z80f,#1<<CFlag
     fetch 4
;@JR C,$+2
opcode_3_8:
     tst z80f,#1<<CFlag
     bne opcode_1_8
     add z80pc,z80pc,#1
     fetch 7
;@ADD HL,SP
opcode_3_9:
     ;@ldr r1,[cpucontext,#z80sp_base]
     ;@sub r1,z80sp,r1
     mov r1,z80sp
     mov r0,z80hl
     adds z80hl,z80hl,r1, lsl #16
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     orrcs z80f,z80f,#1<<CFlag
     eor r0,r0,r1, lsl #16
     eor r0,r0,z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 11
;@LD A,(NN)
opcode_3_A:
     DAM_FETCH16D r0
     DAM_READ8 Op3A
     mov z80a,r0, lsl #24
     fetch 13
;@DEC SP
opcode_3_B:
     sub z80sp,z80sp,#1
     fetch 6
;@INC A
opcode_3_C:
     adds z80a,z80a,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst z80a,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     fetch 4
 ;@DEC A
opcode_3_D:
     subs z80a,z80a,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,z80a,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@LD A,N
opcode_3_E:
     DAM_FETCH8D r0
     mov z80a,r0, lsl #24
     fetch 7
;@CCF
opcode_3_F:
     bic z80f,z80f,#(1<<NFlag)|(1<<HFlag)
     tst z80f,#1<<CFlag
     orrne z80f,z80f,#1<<HFlag
     eor z80f,z80f,#1<<CFlag
     fetch 4
;@LD B,C
opcode_4_1:
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,z80bc, lsl #8
     fetch 4
;@LD B,D
opcode_4_2:
     and z80bc,z80bc,#0xFF<<16
     and r1,z80de,#0xFF<<24
     orr z80bc,z80bc,r1
     fetch 4
;@LD B,E
opcode_4_3:
     and z80bc,z80bc,#0xFF<<16
     and r1,z80de,#0xFF<<16
     orr z80bc,z80bc,r1, lsl #8
     fetch 4
;@LD B,H
opcode_4_4:
     and z80bc,z80bc,#0xFF<<16
     and r1,z80hl,#0xFF<<24
     orr z80bc,z80bc,r1
     fetch 4
;@LD B,L
opcode_4_5:
     and z80bc,z80bc,#0xFF<<16
     and r1,z80hl,#0xFF<<16
     orr z80bc,z80bc,r1, lsl #8
     fetch 4
;@LD B,(HL)
opcode_4_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op46
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 7
;@LD B,A
opcode_4_7:
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,z80a
     fetch 4
;@LD C,B
opcode_4_8:
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,z80bc, lsr #8
     fetch 4
;@LD C,D
opcode_4_A:
     and z80bc,z80bc,#0xFF<<24
     and r1,z80de,#0xFF<<24
     orr z80bc,z80bc,r1, lsr #8
     fetch 4
;@LD C,E
opcode_4_B:
     and z80bc,z80bc,#0xFF<<24
     and r1,z80de,#0xFF<<16
     orr z80bc,z80bc,r1 
     fetch 4
;@LD C,H
opcode_4_C:
     and z80bc,z80bc,#0xFF<<24
     and r1,z80hl,#0xFF<<24
     orr z80bc,z80bc,r1, lsr #8
     fetch 4
;@LD C,L
opcode_4_D:
     and z80bc,z80bc,#0xFF<<24
     and r1,z80hl,#0xFF<<16
     orr z80bc,z80bc,r1 
     fetch 4
;@LD C,(HL)
opcode_4_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op4E
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 7
;@LD C,A
opcode_4_F:
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,z80a, lsr #8
     fetch 4
;@LD D,B
opcode_5_0:
     and z80de,z80de,#0xFF<<16
     and r1,z80bc,#0xFF<<24
     orr z80de,z80de,r1
     fetch 4
;@LD D,C
opcode_5_1:
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,z80bc, lsl #8
     fetch 4
;@LD D,E
opcode_5_3:
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,z80de, lsl #8
     fetch 4
;@LD D,H
opcode_5_4:
     and z80de,z80de,#0xFF<<16
     and r1,z80hl,#0xFF<<24
     orr z80de,z80de,r1
     fetch 4
;@LD D,L
opcode_5_5:
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,z80hl, lsl #8
     fetch 4
;@LD D,(HL)
opcode_5_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op56
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 7
;@LD D,A
opcode_5_7:
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,z80a
     fetch 4
;@LD E,B
opcode_5_8:
     and z80de,z80de,#0xFF<<24
     and r1,z80bc,#0xFF<<24
     orr z80de,z80de,r1, lsr #8
     fetch 4
;@LD E,C
opcode_5_9:
     and z80de,z80de,#0xFF<<24
     and r1,z80bc,#0xFF<<16
     orr z80de,z80de,r1 
     fetch 4
;@LD E,D
opcode_5_A:
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,z80de, lsr #8
     fetch 4
;@LD E,H
opcode_5_C:
     and z80de,z80de,#0xFF<<24
     and r1,z80hl,#0xFF<<24
     orr z80de,z80de,r1, lsr #8
     fetch 4
;@LD E,L
opcode_5_D:
     and z80de,z80de,#0xFF<<24
     and r1,z80hl,#0xFF<<16
     orr z80de,z80de,r1 
     fetch 4
;@LD E,(HL)
opcode_5_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op5E
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 7
;@LD E,A
opcode_5_F:
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,z80a, lsr #8
     fetch 4
;@LD H,B
opcode_6_0:
     and z80hl,z80hl,#0xFF<<16
     and r1,z80bc,#0xFF<<24
     orr z80hl,z80hl,r1
     fetch 4
;@LD H,C
opcode_6_1:
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,z80bc, lsl #8
     fetch 4
;@LD H,D
opcode_6_2:
     and z80hl,z80hl,#0xFF<<16
     and r1,z80de,#0xFF<<24
     orr z80hl,z80hl,r1
     fetch 4
;@LD H,E
opcode_6_3:
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,z80de, lsl #8
     fetch 4
;@LD H,L
opcode_6_5:
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,z80hl, lsl #8
     fetch 4
;@LD H,(HL)
opcode_6_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op66
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 7
;@LD H,A
opcode_6_7:
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,z80a
     fetch 4
;@LD L,B
opcode_6_8:
     and z80hl,z80hl,#0xFF<<24
     and r1,z80bc,#0xFF<<24
     orr z80hl,z80hl,r1, lsr #8
     fetch 4
;@LD L,C
opcode_6_9:
     and z80hl,z80hl,#0xFF<<24
     and r1,z80bc,#0xFF<<16
     orr z80hl,z80hl,r1 
     fetch 4
;@LD L,D
opcode_6_A:
     and z80hl,z80hl,#0xFF<<24
     and r1,z80de,#0xFF<<24
     orr z80hl,z80hl,r1, lsr #8
     fetch 4
;@LD L,E
opcode_6_B:
     and z80hl,z80hl,#0xFF<<24
     and r1,z80de,#0xFF<<16
     orr z80hl,z80hl,r1 
     fetch 4
;@LD L,H
opcode_6_C:
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,z80hl, lsr #8
     fetch 4
;@LD L,(HL)
opcode_6_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op6E
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 7
;@LD L,A
opcode_6_F:
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,z80a, lsr #8
     fetch 4

;@LD (HL),B
opcode_7_0:
     mov r1,z80hl, lsr #16
     mov r0,z80bc, lsr #24
     DAM_WRITE8 Op70
     fetch 7
;@LD (HL),C
opcode_7_1:
     mov r1,z80hl, lsr #16
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     DAM_WRITE8 Op71
     fetch 7
;@LD (HL),D
opcode_7_2:
     mov r1,z80hl, lsr #16
     mov r0,z80de, lsr #24
     DAM_WRITE8 Op72
     fetch 7
;@LD (HL),E
opcode_7_3:
     mov r1,z80hl, lsr #16
     mov r0,z80de, lsr #16
     and r0,r0,#0xFF
     DAM_WRITE8 Op73
     fetch 7
;@LD (HL),H
opcode_7_4:
     mov r1,z80hl, lsr #16
     mov r0,z80hl, lsr #24
     DAM_WRITE8 Op74
     fetch 7
;@LD (HL),L
opcode_7_5:
     mov r1,z80hl, lsr #16
     and r0,r1,#0xFF
     DAM_WRITE8 Op75
     fetch 7
;@HALT
opcode_7_6:
     sub z80pc,z80pc,#1
     
     ;@ldrb r0,[cpucontext,#z80if]
     ;@orr r0,r0,#Z80_HALT
     ;@strb r0,[cpucontext,#z80if]
     ;@b z80_execute_end
     
     ;@Reduce cycle counter to 1,2,3 or 4
     and z80_icount,z80_icount,#3
     fetch 4
     
;@LD (HL),A
opcode_7_7:
     mov r1,z80hl, lsr #16
     mov r0,z80a, lsr #24
     DAM_WRITE8 Op77
     fetch 7
;@LD A,B
opcode_7_8:
     and z80a,z80bc,#0xFF<<24
     fetch 4
;@LD A,C
opcode_7_9:
     mov z80a,z80bc, lsl #8
     fetch 4
;@LD A,D
opcode_7_A:
     and z80a,z80de,#0xFF<<24
     fetch 4
;@LD A,E
opcode_7_B:
     mov z80a,z80de, lsl #8
     fetch 4
;@LD A,H
opcode_7_C:
     and z80a,z80hl,#0xFF<<24
     fetch 4
;@LD A,L
opcode_7_D:
     mov z80a,z80hl, lsl #8
     fetch 4
;@LD A,(HL)
opcode_7_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op7E
     mov z80a,r0, lsl #24
     fetch 7
;@ADD A,B
opcode_8_0:
     and r1,z80bc,#0xFF<<24
     mov r0,z80a
     adds z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,C
opcode_8_1:
     mov r0,z80a     
     adds z80a,z80a,z80bc, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,z80bc, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,D
opcode_8_2:
     and r1,z80de,#0xFF<<24
     mov r0,z80a
     adds z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,E
opcode_8_3:
     mov r0,z80a
     adds z80a,z80a,z80de, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,z80de, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,H
opcode_8_4:
     and r1,z80hl,#0xFF<<24
     mov r0,z80a
     adds z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,L
opcode_8_5:
     mov r0,z80a
     adds z80a,z80a,z80hl, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,z80hl, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADD A,(HL)
opcode_8_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op86
     mov r1,z80a
     adds z80a,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r1,r1,r0, lsl #24
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 7
;@ADD A,A
opcode_8_7:
     mov r0,z80a
     adds z80a,z80a,z80a
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r0
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,B
opcode_8_8:
     and r1,z80bc,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,C
opcode_8_9:
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,z80bc, lsl #8
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,D
opcode_8_A:
     and r1,z80de,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,E
opcode_8_B:
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,z80de, lsl #8
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,H
opcode_8_C:
     and r1,z80hl,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,L
opcode_8_D:
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,z80hl, lsl #8
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4
;@ADC A,(HL)
opcode_8_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op8E
     mov r1,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r0, lsl #24
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r1,r1,r2
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 7
;@ADC A,A
opcode_8_F:
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,z80a
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 4

;@SUB B
opcode_9_0:
     and r1,z80bc,#0xFF<<24
     mov r0,z80a
     subs z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB C
opcode_9_1:
     mov r0,z80a
     subs z80a,z80a,z80bc, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,z80bc, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB D
opcode_9_2:
     and r1,z80de,#0xFF<<24
     mov r0,z80a
     subs z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB E
opcode_9_3:
     mov r0,z80a
     subs z80a,z80a,z80de, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,z80de, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB H
opcode_9_4:
     mov r0,z80a
     and r1,z80hl,#0xFF<<24
     subs z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB L
opcode_9_5:
     mov r0,z80a
     subs z80a,z80a,z80hl, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,z80hl, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SUB (HL)
opcode_9_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op96
     mov r1,z80a
     subs z80a,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1,r1,r0, lsl #24
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 7
;@SUB A
opcode_9_7:
     mov r0,z80a
     subs z80a,z80a,z80a
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r0
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC B 
opcode_9_8:
     and r1,z80bc,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC C
opcode_9_9:
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,z80bc, lsl #8
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC D
opcode_9_A:
     and r1,z80de,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC E
opcode_9_B:
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,z80de, lsl #8
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC H
opcode_9_C:
     and r1,z80hl,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC L
opcode_9_D:
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,z80hl, lsl #8
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@SBC (HL)
opcode_9_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 Op9E
     mov r1,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r0, lsl #24
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1,r1,r2
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 7
;@SBC A
opcode_9_F:
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,z80a
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4

;@AND B 
opcode_A_0:
     ands z80a,z80a,z80bc
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND C
opcode_A_1:
     ands z80a,z80a,z80bc, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND D
opcode_A_2:
     ands z80a,z80a,z80de
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND E
opcode_A_3:
     ands z80a,z80a,z80de, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND H
opcode_A_4:
     ands z80a,z80a,z80hl
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND L
opcode_A_5:
     ands z80a,z80a,z80hl, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@AND (HL)
opcode_A_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpA6
     ands z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 7
;@AND A
opcode_A_7:
     ands z80a,z80a,z80a
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 4
;@XOR B
opcode_A_8:
     and r1,z80bc,#0xFF<<24
     eor z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR C
opcode_A_9:
     eor z80a,z80a,z80bc, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR D
opcode_A_A:
     and r1,z80de,#0xFF<<24
     eor z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR E
opcode_A_B:
     eor z80a,z80a,z80de, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR H
opcode_A_C:
     and r1,z80hl,#0xFF<<24
     eor z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR L
opcode_A_D:
     eor z80a,z80a,z80hl, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@XOR (HL)
opcode_A_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpAE
     eor z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 7
;@XOR A
opcode_A_F:
     eor z80a,z80a,z80a
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4

;@OR B
opcode_B_0:
     and r1,z80bc,#0xFF<<24
     orrs z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR C
opcode_B_1:
     orrs z80a,z80a,z80bc, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR D
opcode_B_2:
     and r1,z80de,#0xFF<<24
     orrs z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR E
opcode_B_3:
     orrs z80a,z80a,z80de, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR H
opcode_B_4:
     and r1,z80hl,#0xFF<<24
     orrs z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR L
opcode_B_5:
     orrs z80a,z80a,z80hl, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@OR (HL)
opcode_B_6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpB6
     orrs z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 7
;@OR A
opcode_B_7:
     orrs z80a,z80a,z80a
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 4
;@CP B
opcode_B_8:
     and r1,z80bc,#0xFF<<24
     subs r2,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP C
opcode_B_9:
     subs r2,z80a,z80bc, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,z80bc, lsl #8
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP D
opcode_B_A:
     and r1,z80de,#0xFF<<24
     subs r2,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP E
opcode_B_B:
     subs r2,z80a,z80de, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,z80de, lsl #8
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP H
opcode_B_C:
     and r1,z80hl,#0xFF<<24
     subs r2,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP L
opcode_B_D:
     subs r2,z80a,z80hl, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,z80hl, lsl #8
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@CP (HL)
opcode_B_E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpBE
     subs r2,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1,z80a,r0, lsl #24
     eor r1,r1,r2
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 7
;@CP A
opcode_B_F:
     subs r2,z80a,z80a
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,z80a
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 4
;@RET NZ
opcode_C_0:
     tst z80f,#1<<ZFlag
     beq opcode_C_9    ;@unconitional RET
     fetch 5

;@POP BC
;@ ??????
opcode_C_1:
     ;@ldrb r1,[z80sp],#1
     ;@ldrb r2,[z80sp],#1
     ;@orr z80bc,r1,r2, lsl #8
     ;@mov z80bc,z80bc, lsl #16
     
     POP_r0 2
     mov z80bc,r0, lsl #16
     
     fetch 10
;@JP NZ,$+3
opcode_C_2:
     tst z80f,#1<<ZFlag
     beq opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@JP $+3
opcode_C_3:
     DAM_FETCH16D r0
     REBASE_PC
     fetch 10
;@CALL NZ,NN
opcode_C_4:
     tst z80f,#1<<ZFlag
     beq opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
        
;@PUSH BC
opcode_C_5:
     ;@mov r1,z80bc, lsr #24
     ;@strb r1,[z80sp,#-1]!
     ;@mov r1,z80bc, lsr #16
     ;@strb r1,[z80sp,#-1]!
     
     mov r0,z80bc,lsr#16
     PUSH_r0 2
     
     fetch 11
;@ADD A,N
opcode_C_6:
     DAM_FETCH8D r1
     mov r0,z80a
     adds z80a,z80a,r1, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1, lsl #24
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@RST 0
opcode_C_7:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2

     mov r0,#0
     REBASE_PC

     fetch 11
;@RET Z
opcode_C_8:
     tst z80f,#1<<ZFlag
     bne opcode_C_9    ;@unconitional RET
     fetch 5
;@RET
opcode_C_9:
     ;@ldrb r0,[z80sp],#1
     ;@ldrb r1,[z80sp],#1
     ;@orr r0,r0,r1, lsl #8
     
     POP_r0 2
     REBASE_PC

     fetch 10
;@JP Z,$+3
opcode_C_A:
     tst z80f,#1<<ZFlag
     bne opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@This reads this opcodes_CB lookup table to find the location of
;@the CB sub for the intruction and then branches to that location
opcode_C_B:
     ;@DAM_FETCH8
     ldrb r0,[z80pc],#1
     ldr pc,[pc,r0, lsl #2]
opcodes_CB:  .word 0x00000000
            .word opcode_CB_00,opcode_CB_01,opcode_CB_02,opcode_CB_03,opcode_CB_04,opcode_CB_05,opcode_CB_06,opcode_CB_07
            .word opcode_CB_08,opcode_CB_09,opcode_CB_0A,opcode_CB_0B,opcode_CB_0C,opcode_CB_0D,opcode_CB_0E,opcode_CB_0F
            .word opcode_CB_10,opcode_CB_11,opcode_CB_12,opcode_CB_13,opcode_CB_14,opcode_CB_15,opcode_CB_16,opcode_CB_17
            .word opcode_CB_18,opcode_CB_19,opcode_CB_1A,opcode_CB_1B,opcode_CB_1C,opcode_CB_1D,opcode_CB_1E,opcode_CB_1F
            .word opcode_CB_20,opcode_CB_21,opcode_CB_22,opcode_CB_23,opcode_CB_24,opcode_CB_25,opcode_CB_26,opcode_CB_27
            .word opcode_CB_28,opcode_CB_29,opcode_CB_2A,opcode_CB_2B,opcode_CB_2C,opcode_CB_2D,opcode_CB_2E,opcode_CB_2F
            .word opcode_CB_30,opcode_CB_31,opcode_CB_32,opcode_CB_33,opcode_CB_34,opcode_CB_35,opcode_CB_36,opcode_CB_37
            .word opcode_CB_38,opcode_CB_39,opcode_CB_3A,opcode_CB_3B,opcode_CB_3C,opcode_CB_3D,opcode_CB_3E,opcode_CB_3F
            .word opcode_CB_40,opcode_CB_41,opcode_CB_42,opcode_CB_43,opcode_CB_44,opcode_CB_45,opcode_CB_46,opcode_CB_47
            .word opcode_CB_48,opcode_CB_49,opcode_CB_4A,opcode_CB_4B,opcode_CB_4C,opcode_CB_4D,opcode_CB_4E,opcode_CB_4F
            .word opcode_CB_50,opcode_CB_51,opcode_CB_52,opcode_CB_53,opcode_CB_54,opcode_CB_55,opcode_CB_56,opcode_CB_57
            .word opcode_CB_58,opcode_CB_59,opcode_CB_5A,opcode_CB_5B,opcode_CB_5C,opcode_CB_5D,opcode_CB_5E,opcode_CB_5F
            .word opcode_CB_60,opcode_CB_61,opcode_CB_62,opcode_CB_63,opcode_CB_64,opcode_CB_65,opcode_CB_66,opcode_CB_67
            .word opcode_CB_68,opcode_CB_69,opcode_CB_6A,opcode_CB_6B,opcode_CB_6C,opcode_CB_6D,opcode_CB_6E,opcode_CB_6F
            .word opcode_CB_70,opcode_CB_71,opcode_CB_72,opcode_CB_73,opcode_CB_74,opcode_CB_75,opcode_CB_76,opcode_CB_77
            .word opcode_CB_78,opcode_CB_79,opcode_CB_7A,opcode_CB_7B,opcode_CB_7C,opcode_CB_7D,opcode_CB_7E,opcode_CB_7F
            .word opcode_CB_80,opcode_CB_81,opcode_CB_82,opcode_CB_83,opcode_CB_84,opcode_CB_85,opcode_CB_86,opcode_CB_87
            .word opcode_CB_88,opcode_CB_89,opcode_CB_8A,opcode_CB_8B,opcode_CB_8C,opcode_CB_8D,opcode_CB_8E,opcode_CB_8F
            .word opcode_CB_90,opcode_CB_91,opcode_CB_92,opcode_CB_93,opcode_CB_94,opcode_CB_95,opcode_CB_96,opcode_CB_97
            .word opcode_CB_98,opcode_CB_99,opcode_CB_9A,opcode_CB_9B,opcode_CB_9C,opcode_CB_9D,opcode_CB_9E,opcode_CB_9F
            .word opcode_CB_A0,opcode_CB_A1,opcode_CB_A2,opcode_CB_A3,opcode_CB_A4,opcode_CB_A5,opcode_CB_A6,opcode_CB_A7
            .word opcode_CB_A8,opcode_CB_A9,opcode_CB_AA,opcode_CB_AB,opcode_CB_AC,opcode_CB_AD,opcode_CB_AE,opcode_CB_AF
            .word opcode_CB_B0,opcode_CB_B1,opcode_CB_B2,opcode_CB_B3,opcode_CB_B4,opcode_CB_B5,opcode_CB_B6,opcode_CB_B7
            .word opcode_CB_B8,opcode_CB_B9,opcode_CB_BA,opcode_CB_BB,opcode_CB_BC,opcode_CB_BD,opcode_CB_BE,opcode_CB_BF
            .word opcode_CB_C0,opcode_CB_C1,opcode_CB_C2,opcode_CB_C3,opcode_CB_C4,opcode_CB_C5,opcode_CB_C6,opcode_CB_C7
            .word opcode_CB_C8,opcode_CB_C9,opcode_CB_CA,opcode_CB_CB,opcode_CB_CC,opcode_CB_CD,opcode_CB_CE,opcode_CB_CF
            .word opcode_CB_D0,opcode_CB_D1,opcode_CB_D2,opcode_CB_D3,opcode_CB_D4,opcode_CB_D5,opcode_CB_D6,opcode_CB_D7
            .word opcode_CB_D8,opcode_CB_D9,opcode_CB_DA,opcode_CB_DB,opcode_CB_DC,opcode_CB_DD,opcode_CB_DE,opcode_CB_DF
            .word opcode_CB_E0,opcode_CB_E1,opcode_CB_E2,opcode_CB_E3,opcode_CB_E4,opcode_CB_E5,opcode_CB_E6,opcode_CB_E7
            .word opcode_CB_E8,opcode_CB_E9,opcode_CB_EA,opcode_CB_EB,opcode_CB_EC,opcode_CB_ED,opcode_CB_EE,opcode_CB_EF
            .word opcode_CB_F0,opcode_CB_F1,opcode_CB_F2,opcode_CB_F3,opcode_CB_F4,opcode_CB_F5,opcode_CB_F6,opcode_CB_F7
            .word opcode_CB_F8,opcode_CB_F9,opcode_CB_FA,opcode_CB_FB,opcode_CB_FC,opcode_CB_FD,opcode_CB_FE,opcode_CB_FF

;@CALL Z,NN
opcode_C_C:
     tst z80f,#1<<ZFlag
     bne opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
;@CALL NN
opcode_C_D:

     ;@DAM_FETCH16D r2
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     ;@mov r0,r2
     ;@REBASE_PC

;@DAM_FETCH16D r0						;@ fetch call addr
ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
sub r2,z80pc,r2
ldr r1,[cpucontext,#ppMemFetchData]	;@ r1 point to ppMemFetchData[0]
mov r0,r2,lsr#8						
ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]

ldrb r0,[r1,r2]
add r2,r2,#1
ldrb r1,[r1,r2]
orr r0,r0,r1, lsl #8
add z80pc,z80pc,#2

     stmdb sp!,{r0}							;@ push it (new pc) to r0

     ldr r0,[cpucontext,#z80pc_base]		;@ calc Z80 PC -> r1
     sub r0,z80pc,r0
     PUSH_r0 2

     ldmia sp!,{r0}     					;@ pop new pc
     REBASE_PC

     fetch 17
;@ADC A,N
opcode_C_E:
     DAM_FETCH8D r1
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1, lsl #24
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@RST 8H
opcode_C_F:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2

     mov r0,#8
     REBASE_PC

     fetch 11
;@RET NC
opcode_D_0:
     tst z80f,#1<<CFlag
     beq opcode_C_9    ;@unconitional RET
     fetch 5
;@POP DE
opcode_D_1:
     ;@ldrb r1,[z80sp],#1
     ;@ldrb r2,[z80sp],#1
     ;@orr z80de,r1,r2, lsl #8
     ;@mov z80de,z80de, lsl #16

     POP_r0 2
     mov z80de,r0,lsl #16
     
     fetch 10
;@JP NC, $+3
opcode_D_2 :
     tst z80f,#1<<CFlag
     beq opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@OUT (N),A
opcode_D_3:
     DAM_FETCH8D r0
     orr r0,r0,z80a,lsr#16
     mov r1,z80a, lsr #24
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 11
;@CALL NC,NN
opcode_D_4:
     tst z80f,#1<<CFlag
     beq opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
;@PUSH DE
opcode_D_5:
     ;@mov r1,z80de, lsr #24
     ;@strb r1,[z80sp,#-1]!
     ;@mov r1,z80de, lsr #16
     ;@strb r1,[z80sp,#-1]!
     
     mov r0,z80de,lsr#16
     PUSH_r0 2
     
     fetch 11
;@SUB N
opcode_D_6:
     DAM_FETCH8D r1
     mov r0,z80a
     subs z80a,z80a,r1, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1, lsl #24
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8

;@RST 10H
opcode_D_7:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2
     
     mov r0,#0x10
     REBASE_PC

     fetch 11
;@RET C
opcode_D_8:
     tst z80f,#1<<CFlag
     bne opcode_C_9    ;@unconitional RET
     fetch 5
;@EXX
opcode_D_9:
     add r1,cpucontext,#z80bc2
     swp z80bc,z80bc,[r1]
     add r1,cpucontext,#z80de2
     swp z80de,z80de,[r1]
     add r1,cpucontext,#z80hl2
     swp z80hl,z80hl,[r1]
     fetch 4
;@JP C,$+3
opcode_D_A:
     tst z80f,#1<<CFlag
     bne opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@IN A,(N)
opcode_D_B:
     DAM_FETCH8D r0
     orr r0,r0,z80a,lsr#16
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     mov z80a,r0, lsl #24      ;@ r0 = data read
     fetch 11
;@CALL C,NN
opcode_D_C:
     tst z80f,#1<<CFlag
     bne opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10

;@opcodes_DD
opcode_D_D:
     mov z80xx,#z80ix
     b opcode_D_D_F_D
opcode_F_D:
     mov z80xx,#z80iy
opcode_D_D_F_D:
     ldrb r1,[z80pc],#1
     ;@ DAM_FETCH8
     ldr pc,[pc,r1, lsl #2]                       
opcodes_DD:  .word 0x00000000
            .word opcode_0_0,  opcode_0_1,  opcode_0_2,  opcode_0_3,  opcode_0_4,  opcode_0_5,  opcode_0_6,  opcode_0_7
            .word opcode_0_8,  opcode_DD_09,opcode_0_A,  opcode_0_B,  opcode_0_C,  opcode_0_D,  opcode_0_E,  opcode_0_F
            .word opcode_1_0,  opcode_1_1,  opcode_1_2,  opcode_1_3,  opcode_1_4,  opcode_1_5,  opcode_1_6,  opcode_1_7
            .word opcode_1_8,  opcode_DD_19,opcode_1_A,  opcode_1_B,  opcode_1_C,  opcode_1_D,  opcode_1_E,  opcode_1_F
            .word opcode_2_0,  opcode_DD_21,opcode_DD_22,opcode_DD_23,opcode_DD_24,opcode_DD_25,opcode_DD_26,opcode_2_7
            .word opcode_2_8,  opcode_DD_29,opcode_DD_2A,opcode_DD_2B,opcode_DD_2C,opcode_DD_2D,opcode_DD_2E,opcode_2_F
            .word opcode_3_0,  opcode_3_1,  opcode_3_2,  opcode_3_3,  opcode_DD_34,opcode_DD_35,opcode_DD_36,opcode_3_7
            .word opcode_3_8,  opcode_DD_39,opcode_3_A,  opcode_3_B,  opcode_3_C,  opcode_3_D,  opcode_3_E,  opcode_3_F
            .word opcode_4_0,  opcode_4_1,  opcode_4_2,  opcode_4_3,  opcode_DD_44,opcode_DD_45,opcode_DD_46,opcode_4_7
            .word opcode_4_8,  opcode_4_9,  opcode_4_A,  opcode_4_B,  opcode_DD_4C,opcode_DD_4D,opcode_DD_4E,opcode_4_F
            .word opcode_5_0,  opcode_5_1,  opcode_5_2,  opcode_5_3,  opcode_DD_54,opcode_DD_55,opcode_DD_56,opcode_5_7
            .word opcode_5_8,  opcode_5_9,  opcode_5_A,  opcode_5_B,  opcode_DD_5C,opcode_DD_5D,opcode_DD_5E,opcode_5_F
            .word opcode_DD_60,opcode_DD_61,opcode_DD_62,opcode_DD_63,opcode_DD_64,opcode_DD_65,opcode_DD_66,opcode_DD_67
            .word opcode_DD_68,opcode_DD_69,opcode_DD_6A,opcode_DD_6B,opcode_DD_6C,opcode_DD_6D,opcode_DD_6E,opcode_DD_6F
            .word opcode_DD_70,opcode_DD_71,opcode_DD_72,opcode_DD_73,opcode_DD_74,opcode_DD_75,opcode_7_6,  opcode_DD_77
            .word opcode_7_8,  opcode_7_9,  opcode_7_A,  opcode_7_B,  opcode_DD_7C,opcode_DD_7D,opcode_DD_7E,opcode_7_F
            .word opcode_8_0,  opcode_8_1,  opcode_8_2,  opcode_8_3,  opcode_DD_84,opcode_DD_85,opcode_DD_86,opcode_8_7
            .word opcode_8_8,  opcode_8_9,  opcode_8_A,  opcode_8_B,  opcode_DD_8C,opcode_DD_8D,opcode_DD_8E,opcode_8_F
            .word opcode_9_0,  opcode_9_1,  opcode_9_2,  opcode_9_3,  opcode_DD_94,opcode_DD_95,opcode_DD_96,opcode_9_7
            .word opcode_9_8,  opcode_9_9,  opcode_9_A,  opcode_9_B,  opcode_DD_9C,opcode_DD_9D,opcode_DD_9E,opcode_9_F
            .word opcode_A_0,  opcode_A_1,  opcode_A_2,  opcode_A_3,  opcode_DD_A4,opcode_DD_A5,opcode_DD_A6,opcode_A_7
            .word opcode_A_8,  opcode_A_9,  opcode_A_A,  opcode_A_B,  opcode_DD_AC,opcode_DD_AD,opcode_DD_AE,opcode_A_F
            .word opcode_B_0,  opcode_B_1,  opcode_B_2,  opcode_B_3,  opcode_DD_B4,opcode_DD_B5,opcode_DD_B6,opcode_B_7
            .word opcode_B_8,  opcode_B_9,  opcode_B_A,  opcode_B_B,  opcode_DD_BC,opcode_DD_BD,opcode_DD_BE,opcode_B_F
            .word opcode_C_0,  opcode_C_1,  opcode_C_2,  opcode_C_3,  opcode_C_4,  opcode_C_5,  opcode_C_6,  opcode_C_7
            .word opcode_C_8,  opcode_C_9,  opcode_C_A,  opcode_DD_CB,opcode_C_C,  opcode_C_D,  opcode_C_E,  opcode_C_F
            .word opcode_D_0,  opcode_D_1,  opcode_D_2,  opcode_D_3,  opcode_D_4,  opcode_D_5,  opcode_D_6,  opcode_D_7
            .word opcode_D_8,  opcode_D_9,  opcode_D_A,  opcode_D_B,  opcode_D_C,  opcode_D_D,  opcode_D_E,  opcode_D_F
            .word opcode_E_0,  opcode_DD_E1,opcode_E_2,  opcode_DD_E3,opcode_E_4,  opcode_DD_E5,opcode_E_6,  opcode_E_7
            .word opcode_E_8,  opcode_DD_E9,opcode_E_A,  opcode_E_B,  opcode_E_C,  opcode_E_D,  opcode_E_E,  opcode_E_F
            .word opcode_F_0,  opcode_F_1,  opcode_F_2,  opcode_F_3,  opcode_F_4,  opcode_F_5,  opcode_F_6,  opcode_F_7
            .word opcode_F_8,  opcode_DD_F9,opcode_F_A,  opcode_F_B,  opcode_F_C,  opcode_F_D,  opcode_F_E,  opcode_F_F

;@SBC A,N 
opcode_D_E:
     DAM_FETCH8D r1
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1, lsl #24
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@RST 18H
opcode_D_F:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2

     mov r0,#0x18
     REBASE_PC

     fetch 11
;@RET PO
opcode_E_0:
     tst z80f,#1<<VFlag
     beq opcode_C_9    ;@unconitional RET
     fetch 5
;@POP HL
opcode_E_1:
     ;@ldrb r1,[z80sp],#1
     ;@ldrb r2,[z80sp],#1
     ;@orr z80hl,r1,r2, lsl #8
     ;@mov z80hl,z80hl, lsl #16
     
     POP_r0 2
     mov z80hl,r0, lsl #16
     
     fetch 10
;@JP PO,$+3
opcode_E_2:
     tst z80f,#1<<VFlag
     beq opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@EX (SP),HL
opcode_E_3:
     ;@ldrb r0,[z80sp]
     ;@ldrb r1,[z80sp,#1]
     ;@orr r0,r0,r1, lsl #8
     ;@mov r1,z80hl, lsr #24
     ;@strb r1,[z80sp,#1]
     ;@mov r1,z80hl, lsr #16
     ;@strb r1,[z80sp]
     ;@mov z80hl,r0, lsl #16

     POP_r0 0
     stmdb sp!,{r0}
     mov r0,z80hl,lsr #16
     PUSH_r0 0
     ldmia sp!,{r0}
     mov z80hl,r0,lsl #16

     fetch 19
;@CALL PO,NN
opcode_E_4:
     tst z80f,#1<<VFlag
     beq opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
;@PUSH HL
opcode_E_5:
     ;@mov r1,z80hl, lsr #24
     ;@strb r1,[z80sp,#-1]!
     ;@mov r1,z80hl, lsr #16
     ;@strb r1,[z80sp,#-1]!
     
     mov r0,z80hl,lsr #16
     PUSH_r0 2
     
     fetch 11
;@AND N
opcode_E_6:
     DAM_FETCH8D r1
     and z80a,z80a,r1, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 8
;@RST 20H
opcode_E_7:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2
     
     mov r0,#0x20
     REBASE_PC

     fetch 11
;@RET PE
opcode_E_8:
     tst z80f,#1<<VFlag
     bne opcode_C_9    ;@unconditional RET
     fetch 5
;@JP (HL)
opcode_E_9:

     mov r0,z80hl, lsr #16
     REBASE_PC

     fetch 4
;@JP PE,$+3
opcode_E_A:
     tst z80f,#1<<VFlag
     bne opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@EX DE,HL
opcode_E_B:
     mov r1,z80de
     mov z80de,z80hl
     mov z80hl,r1
     fetch 4
;@CALL PE,NN
opcode_E_C:
     tst z80f,#1<<VFlag
     bne opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
;@This should be caught at start
opcode_E_D:
     ldrb r1,[z80pc],#1
     ;@ DAM_FETCH8
     ldr pc,[pc,r1, lsl #2]
     
opcodes_ED:  .word 0x00000000
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_40,opcode_ED_41,opcode_ED_42,opcode_ED_43,opcode_ED_44,opcode_ED_45,opcode_ED_46,opcode_ED_47
			.word opcode_ED_48,opcode_ED_49,opcode_ED_4A,opcode_ED_4B,opcode_ED_44,opcode_ED_4D,opcode_ED_46,opcode_ED_4F
			.word opcode_ED_50,opcode_ED_51,opcode_ED_52,opcode_ED_53,opcode_ED_44,opcode_ED_45,opcode_ED_56,opcode_ED_57
			.word opcode_ED_58,opcode_ED_59,opcode_ED_5A,opcode_ED_5B,opcode_ED_44,opcode_ED_45,opcode_ED_5E,opcode_ED_5F
			.word opcode_ED_60,opcode_ED_61,opcode_ED_62,opcode_ED_63,opcode_ED_44,opcode_ED_45,opcode_ED_46,opcode_ED_67
			.word opcode_ED_68,opcode_ED_69,opcode_ED_6A,opcode_ED_6B,opcode_ED_44,opcode_ED_45,opcode_ED_46,opcode_ED_6F
			.word opcode_ED_70,opcode_ED_71,opcode_ED_72,opcode_ED_73,opcode_ED_44,opcode_ED_45,opcode_ED_56,opcode_ED_NF
			.word opcode_ED_78,opcode_ED_79,opcode_ED_7A,opcode_ED_7B,opcode_ED_44,opcode_ED_45,opcode_ED_5E,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_A0,opcode_ED_A1,opcode_ED_A2,opcode_ED_A3,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_A8,opcode_ED_A9,opcode_ED_AA,opcode_ED_AB,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_B0,opcode_ED_B1,opcode_ED_B2,opcode_ED_B3,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_B8,opcode_ED_B9,opcode_ED_BA,opcode_ED_BB,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
			.word opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF,opcode_ED_NF
     
;@XOR N
opcode_E_E:
     DAM_FETCH8D r1
     eor z80a,z80a,r1, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@RST 28H
opcode_E_F:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2

     mov r0,#0x28
     REBASE_PC

     fetch 11
;@RET P
opcode_F_0:
     tst z80f,#1<<SFlag
     beq opcode_C_9    ;@unconitional RET
     fetch 5
;@POP AF
opcode_F_1:
     ;@ldrb z80f,[z80sp],#1
     ;@sub r0,opcodes,#0x200
     ;@ldrb z80f,[r0,z80f]
     ;@ldrb z80a,[z80sp],#1
     ;@mov z80a,z80a, lsl #24
     
     POP_r0_r1
     mov z80a,r1,lsl #24
     
     sub r1,opcodes,#0x200
     ldrb z80f,[r1,r0]
     
     fetch 10
;@JP P,$+3
opcode_F_2:
     tst z80f,#1<<SFlag
     beq opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10
;@DI
opcode_F_3:
     ldrb r1,[cpucontext,#z80if]
     bic r1,r1,#(Z80_IF1)|(Z80_IF2)
     strb r1,[cpucontext,#z80if]
     fetch 4
;@CALL P,NN
opcode_F_4:
     tst z80f,#1<<SFlag
     beq opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10
;@PUSH AF
opcode_F_5:
     ;@mov r1,z80a, lsr #24
     ;@strb r1,[z80sp,#-1]!
     ;@sub r0,opcodes,#0x300
     ;@ldrb r1,[r0,z80f]
     ;@strb r1,[z80sp,#-1]!
     
     mov r1,z80a, lsr #24
     
     sub r0,opcodes,#0x300
     ldrb r0,[r0,z80f]
     
     orr r0,r0,r1,lsl #8
     PUSH_r0 2
     
     fetch 11
;@OR N
opcode_F_6:
     DAM_FETCH8D r1
     orr z80a,z80a,r1, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@RST 30H
opcode_F_7:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2

     mov r0,#0x30
     REBASE_PC

     fetch 11
;@RET M
opcode_F_8:
     tst z80f,#1<<SFlag
     bne opcode_C_9    ;@unconitional RET
     fetch 5
;@LD SP,HL
opcode_F_9:
     mov z80sp,z80hl, lsr #16
     fetch 6
;@JP M,$+3
opcode_F_A:
     tst z80f,#1<<SFlag
     bne opcode_C_3  ;@unconditional JP
     add z80pc,z80pc,#2
     fetch 10

MAIN_opcodes_POINTER: .word MAIN_opcodes

;@EI
opcode_F_B:
     
     ldr r1,[cpucontext,#nEI]
     ;@tst r1, #1
     ;@beq EiContinue
     cmp r1, #1
     bne EiContinue
     
     ldrb r1,[cpucontext,#z80if]
     cmp r1,#(Z80_IF1)|(Z80_IF2)
     beq EiContinue
     
     mov r1,#(Z80_IF1)|(Z80_IF2)
     strb r1,[cpucontext,#z80if]
     mov r1,#2
     str r1,[cpucontext,#nEI]
     sub z80_icount,z80_icount,#4

     b z80_execute_end

EiContinue:
     mov r1,#(Z80_IF1)|(Z80_IF2)
     strb r1,[cpucontext,#z80if]

     fetch 4
     

;@CALL M,NN
opcode_F_C:
     tst z80f,#1<<SFlag
     bne opcode_C_D   ;@unconditional CALL
     add z80pc,z80pc,#2
     fetch 10

;@SHOULD BE CAUGHT AT START - FD SECTION

;@CP N
opcode_F_E:
     DAM_FETCH8D r1
     subs r2,z80a,r1, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@RST 38H
opcode_F_F:
     ;@ldr r1,[cpucontext,#z80pc_base]
     ;@sub z80pc,z80pc,r1
     ;@mov r0,z80pc, lsr #8
     ;@strb r0,[z80sp,#-1]!
     ;@strb z80pc,[z80sp,#-1]!

     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     PUSH_r0 2
     
     mov r0,#0x38
     REBASE_PC

     fetch 11

     
;@##################################
;@##################################
;@###  opcodes CB  #########################
;@##################################
;@##################################


;@RLC B
opcode_CB_00:
     and r0,z80bc,#0xFF<<24
     movs r0,r0, lsl #1
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 8

;@RLC C
opcode_CB_01:
     movs r0,z80bc, lsl #9
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsr #8
     fetch 8
;@RLC D
opcode_CB_02:
     and r0,z80de,#0xFF<<24
     movs r0,r0, lsl #1
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 8
;@RLC E
opcode_CB_03:
     movs r0,z80de, lsl #9
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsr #8
     fetch 8
;@RLC H
opcode_CB_04:
     and r0,z80hl,#0xFF<<24
     movs r0,r0, lsl #1
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 8
;@RLC L
opcode_CB_05:
     movs r0,z80hl, lsl #9
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsr #8
     fetch 8
;@RLC (HL)
opcode_CB_06:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB06
     movs r0,r0, lsl #25
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB06
     fetch 15
;@RLC A
opcode_CB_07:
     movs z80a,z80a, lsl #1
     orrcs z80a,z80a,#1<<24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     fetch 8
;@RRC B
opcode_CB_08:
     movs r0,z80bc, lsr #25
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 8
;@RRC C
opcode_CB_09:
     and r0,z80bc,#0xFF<<16     
     movs r0,r0, lsr #17
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 8
;@RRC D
opcode_CB_0A:
     movs r0,z80de, lsr #25
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 8
;@RRC E
opcode_CB_0B:
     and r0,z80de,#0xFF<<16     
     movs r0,r0, lsr #17
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 8
;@RRC H
opcode_CB_0C:
     movs r0,z80hl, lsr #25
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 8
;@RRC L
opcode_CB_0D:
     and r0,z80hl,#0xFF<<16     
     movs r0,r0, lsr #17
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 8
;@RRC (HL)
opcode_CB_0E :
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB0E
     movs r0,r0, lsr #1
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB0E
     fetch 15
;@RRC A
opcode_CB_0F:
     movs z80a,z80a, lsr #25
     orrcs z80a,z80a,#1<<7
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a]
     orrcs z80f,z80f,#1<<CFlag
     mov z80a,z80a, lsl #24 
     fetch 8
;@RL B
opcode_CB_10:
     and r0,z80bc,#0xFF<<24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<23
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 8
;@RL C
opcode_CB_11:
     and r0,z80bc,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<15
     movs r0,r0, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsr #8
     fetch 8
;@RL D
opcode_CB_12:
     and r0,z80de,#0xFF<<24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<23
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 8
;@RL E
opcode_CB_13:
     and r0,z80de,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<15
     movs r0,r0, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsr #8
     fetch 8
;@RL H
opcode_CB_14:
     and r0,z80hl,#0xFF<<24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<23
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 8
;@RL L
opcode_CB_15:
     and r0,z80hl,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<15
     movs r0,r0, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsr #8
     fetch 8
;@RL (HL)
opcode_CB_16:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB16
     mov r0,r0, lsl #24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<23
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB16
     fetch 15
;@RL A
opcode_CB_17:
     tst z80f,#1<<CFlag
     orrne z80a,z80a,#1<<23
     movs z80a,z80a, lsl #1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     fetch 8
;@RR B 
opcode_CB_18:
     mov r0,z80bc, lsr #24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<8
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
    fetch 8
;@RR C
opcode_CB_19:
     and r0,z80bc,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<24
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 8
;@RR D
opcode_CB_1A:
     mov r0,z80de, lsr #24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<8
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 8
;@RR E
opcode_CB_1B:
     and r0,z80de,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<24
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 8
;@RR H
opcode_CB_1C:
     mov r0,z80hl, lsr #24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<8
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 8
;@RR L
opcode_CB_1D:
     and r0,z80hl,#0xFF<<16
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<24
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 8
;@RR (HL)
opcode_CB_1E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCD1E
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<8
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB1E
     fetch 15
;@RR A
opcode_CB_1F:
     mov z80a,z80a, lsr #24
     tst z80f,#1<<CFlag
     orrne z80a,z80a,#1<<8
     movs z80a,z80a, lsr #1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a]
     orrcs z80f,z80f,#1<<CFlag 
     mov z80a,z80a, lsl #24
     fetch 8
;@SLA B
opcode_CB_20:
     and r0,z80bc,#0xFF<<24
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 8
;@SLA C
opcode_CB_21:
     movs r0,z80bc, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsr #8
     fetch 8
;@SLA D
opcode_CB_22:
     and r0,z80de,#0xFF<<24
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 8
;@SLA E
opcode_CB_23:
     movs r0,z80de, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsr #8
     fetch 8
;@SLA H
opcode_CB_24:
     and r0,z80hl,#0xFF<<24  
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 8
;@SLA L
opcode_CB_25:
     movs r0,z80hl, lsl #9
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsr #8
     fetch 8
;@SLA (HL)
opcode_CB_26:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB26
     movs r0,r0, lsl #25
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB26
     fetch 15
;@SLA A
opcode_CB_27:
     movs z80a,z80a, lsl #1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     fetch 8
;@SRA B
opcode_CB_28:
     movs r0,z80bc, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 8
;@SRA C
opcode_CB_29:
     mov r0,z80bc, lsl #8
     movs r0,r0, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 8
;@SRA D
opcode_CB_2A:
     movs r0,z80de, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 8
;@SRA E
opcode_CB_2B:
     mov r0,z80de, lsl #8
     movs r0,r0, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag
     and z80de,z80de,#0xFF<<24 
     orr z80de,z80de,r0, lsl #16
     fetch 8
;@SRA H
opcode_CB_2C:
     movs r0,z80hl, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 8
;@SRA L
opcode_CB_2D:
     mov r0,z80hl, lsl #8
     movs r0,r0, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 8
;@SRA (HL)
opcode_CB_2E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB2E
     mov r0,r0, lsl #24
     movs r0,r0, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB2E
     fetch 15
;@SRA A
opcode_CB_2F:
     movs z80a,z80a, asr #25
     and z80a,z80a,#0xFF
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a]
     orrcs z80f,z80f,#1<<CFlag 
     mov z80a,z80a, lsl #24
     fetch 8

;@SLL B
opcode_CB_30:
     and r0,z80bc,#0xFF<<24
     movs r0,r0, lsl #1
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0
     fetch 8
;@SLL C
opcode_CB_31:
     movs r0,z80bc, lsl #9
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsr #8
     fetch 8
;@SLL D
opcode_CB_32:
     and r0,z80de,#0xFF<<24
     movs r0,r0, lsl #1
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0
     fetch 8
;@SLL E
opcode_CB_33:
     movs r0,z80de, lsl #9
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsr #8
     fetch 8
;@SLL H
opcode_CB_34:
     and r0,z80hl,#0xFF<<24
     movs r0,r0, lsl #1
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0
     fetch 8
;@SLL L
opcode_CB_35:
     movs r0,z80hl, lsl #9
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsr #8
     fetch 8
;@SLL (HL)
opcode_CB_36:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB36
     movs r0,r0, lsl #25
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     mov r0,r0, lsr #24
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB36
     fetch 15
;@SLL A
opcode_CB_37:
     movs z80a,z80a, lsl #1
     orr z80a,z80a,#1<<24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     fetch 8
;@SRL B
opcode_CB_38:
     movs r0,z80bc, lsr #25
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 8
;@SRL C
opcode_CB_39:
     and r0,z80bc,#0xFF<<16
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 8
;@SRL D
opcode_CB_3A:
     movs r0,z80de, lsr #25
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 8
;@SRL E
opcode_CB_3B:
     and r0,z80de,#0xFF<<16
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 8
;@SRL H
opcode_CB_3C:
     movs r0,z80hl, lsr #25
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 8
;@SRL L
opcode_CB_3D:
     and r0,z80hl,#0xFF<<16
     movs r0,r0, lsr #17
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 8
;@SRL (HL)
opcode_CB_3E:   
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB3E
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB3E
     fetch 15
;@SRL A
opcode_CB_3F:
     movs z80a,z80a, lsr #25
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a]
     orrcs z80f,z80f,#1<<CFlag 
     mov z80a,z80a, lsl #24
     fetch 8
;@BIT 0,B
opcode_CB_40:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<24
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,C
opcode_CB_41:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<16
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,D
opcode_CB_42:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<24
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,E
opcode_CB_43:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<16
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,H
opcode_CB_44:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<24
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,L
opcode_CB_45:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<16
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 0,(HL)
opcode_CB_46:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB46
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<0
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 0,A
opcode_CB_47:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<24
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,B
opcode_CB_48:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<25
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,C
opcode_CB_49:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<17
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,D
opcode_CB_4A:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<25
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,E
opcode_CB_4B:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<17
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,H
opcode_CB_4C:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<25
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,L
opcode_CB_4D:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<17
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 1,(HL)
opcode_CB_4E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB4E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<1
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 1,A
opcode_CB_4F:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<25
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,B
opcode_CB_50:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<26
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,C
opcode_CB_51:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<18
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,D
opcode_CB_52:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<26
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,E
opcode_CB_53:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<18
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,H
opcode_CB_54:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<26
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,L
opcode_CB_55:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<18
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 2,(HL)
opcode_CB_56:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB56
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<2
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 2,A
opcode_CB_57:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<26
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,B
opcode_CB_58:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<27
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,C
opcode_CB_59:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<19
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,D
opcode_CB_5A:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<27
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,E
opcode_CB_5B:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<19
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,H
opcode_CB_5C:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<27
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,L
opcode_CB_5D:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<19
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 3,(HL)
opcode_CB_5E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB5E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<3
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 3,A
opcode_CB_5F:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<27
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,B
opcode_CB_60:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<28
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,C
opcode_CB_61:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<20
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,D
opcode_CB_62:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<28
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,E
opcode_CB_63:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<20
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,H
opcode_CB_64:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<28
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,L
opcode_CB_65:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<20
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 4,(HL)
opcode_CB_66:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB66
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<4
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 4,A
opcode_CB_67:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<28
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,B
opcode_CB_68:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<29
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,C
opcode_CB_69:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<21
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,D
opcode_CB_6A:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<29
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,E
opcode_CB_6B:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<21
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,H
opcode_CB_6C:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<29
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,L
opcode_CB_6D:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<21
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 5,(HL)
opcode_CB_6E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB6E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<5
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 5,A
opcode_CB_6F:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<29
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,B
opcode_CB_70:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<30
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,C
opcode_CB_71:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<22
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,D
opcode_CB_72:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<30
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,E
opcode_CB_73:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<22
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,H
opcode_CB_74:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<30
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,L
opcode_CB_75:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<22
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 6,(HL)
opcode_CB_76:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB76
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<6
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 15
;@BIT 6,A
opcode_CB_77:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<30
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 8
;@BIT 7,B
opcode_CB_78:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<31
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,C
opcode_CB_79:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80bc,#1<<23
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,D
opcode_CB_7A:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<31
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,E
opcode_CB_7B:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80de,#1<<23
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,H
opcode_CB_7C:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<31
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,L
opcode_CB_7D:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80hl,#1<<23
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8
;@BIT 7,(HL)
opcode_CB_7E:   
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB7E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<7
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 15
;@BIT 7,A
opcode_CB_7F:
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst z80a,#1<<31
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 8

;@RES 0,B
opcode_CB_80:
     bic z80bc,z80bc,#1<<24
     fetch 8
;@RES 0,C
opcode_CB_81:
     bic z80bc,z80bc,#1<<16
     fetch 8
;@RES 0,D
opcode_CB_82:
     bic z80de,z80de,#1<<24
     fetch 8
;@RES 0,E
opcode_CB_83:
     bic z80de,z80de,#1<<16
     fetch 8
;@RES 0,H
opcode_CB_84:
     bic z80hl,z80hl,#1<<24
     fetch 8
;@RES 0,L
opcode_CB_85:
     bic z80hl,z80hl,#1<<16
     fetch 8
;@RES 0,(HL)
opcode_CB_86:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB86
     bic r0,r0,#1<<0
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB86
     fetch 15
;@RES 0,A
opcode_CB_87:
     bic z80a,z80a,#1<<24
     fetch 8
;@RES 1,B
opcode_CB_88:
     bic z80bc,z80bc,#1<<25
     fetch 8
;@RES 1,C
opcode_CB_89:
     bic z80bc,z80bc,#1<<17
     fetch 8
;@RES 1,D
opcode_CB_8A:
     bic z80de,z80de,#1<<25
     fetch 8
;@RES 1,E
opcode_CB_8B:
     bic z80de,z80de,#1<<17
     fetch 8
;@RES 1,H
opcode_CB_8C:
     bic z80hl,z80hl,#1<<25
     fetch 8
;@RES 1,L
opcode_CB_8D:
     bic z80hl,z80hl,#1<<17
     fetch 8
;@RES 1,(HL)
opcode_CB_8E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB8E
     bic r0,r0,#1<<1
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB8E
     fetch 15
;@RES 1,A
opcode_CB_8F:
     bic z80a,z80a,#1<<25
     fetch 8
;@RES 2,B
opcode_CB_90:
     bic z80bc,z80bc,#1<<26
     fetch 8
;@RES 2,C
opcode_CB_91:
     bic z80bc,z80bc,#1<<18
     fetch 8
;@RES 2,D
opcode_CB_92:
     bic z80de,z80de,#1<<26
     fetch 8
;@RES 2,E
opcode_CB_93:
     bic z80de,z80de,#1<<18
     fetch 8
;@RES 2,H
opcode_CB_94:
     bic z80hl,z80hl,#1<<26
     fetch 8
;@RES 2,L
opcode_CB_95:
     bic z80hl,z80hl,#1<<18
     fetch 8

;@RES 2,(HL)
opcode_CB_96:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB96
     bic r0,r0,#1<<2
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB96
     fetch 15
;@RES 2,A
opcode_CB_97:
     bic z80a,z80a,#1<<26
     fetch 8
;@RES 3,B
opcode_CB_98:
     bic z80bc,z80bc,#1<<27
     fetch 8
;@RES 3,C
opcode_CB_99:
     bic z80bc,z80bc,#1<<19
     fetch 8
;@RES 3,D
opcode_CB_9A:
     bic z80de,z80de,#1<<27
     fetch 8
;@RES 3,E
opcode_CB_9B:
     bic z80de,z80de,#1<<19
     fetch 8
;@RES 3,H
opcode_CB_9C:
     bic z80hl,z80hl,#1<<27
     fetch 8
;@RES 3,L
opcode_CB_9D:
     bic z80hl,z80hl,#1<<19
     fetch 8
;@RES 3,(HL)
opcode_CB_9E:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCB9E
     bic r0,r0,#1<<3
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCB9E
     fetch 15
;@RES 3,A
opcode_CB_9F:
     bic z80a,z80a,#1<<27
     fetch 8

;@RES 4,B
opcode_CB_A0:
     bic z80bc,z80bc,#1<<28
     fetch 8
;@RES 4,C
opcode_CB_A1:
     bic z80bc,z80bc,#1<<20
     fetch 8
;@RES 4,D
opcode_CB_A2:
     bic z80de,z80de,#1<<28
     fetch 8
;@RES 4,E
opcode_CB_A3:
     bic z80de,z80de,#1<<20
     fetch 8
;@RES 4,H
opcode_CB_A4:
     bic z80hl,z80hl,#1<<28
     fetch 8
;@RES 4,L
opcode_CB_A5:
     bic z80hl,z80hl,#1<<20
     fetch 8
;@RES 4,(HL)
opcode_CB_A6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBA6
     bic r0,r0,#1<<4
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBA6
     fetch 15
;@RES 4,A
opcode_CB_A7:
     bic z80a,z80a,#1<<28
     fetch 8
;@RES 5,B
opcode_CB_A8:
     bic z80bc,z80bc,#1<<29
     fetch 8
;@RES 5,C
opcode_CB_A9:
     bic z80bc,z80bc,#1<<21
     fetch 8
;@RES 5,D
opcode_CB_AA:
     bic z80de,z80de,#1<<29
     fetch 8
;@RES 5,E
opcode_CB_AB:
     bic z80de,z80de,#1<<21
     fetch 8
;@RES 5,H
opcode_CB_AC:
     bic z80hl,z80hl,#1<<29
     fetch 8
;@RES 5,L
opcode_CB_AD:
     bic z80hl,z80hl,#1<<21
     fetch 8
;@RES 5,(HL)
opcode_CB_AE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBAE
     bic r0,r0,#1<<5
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBAE
     fetch 15
;@RES 5,A
opcode_CB_AF:
     bic z80a,z80a,#1<<29
     fetch 8

;@RES 6,B
opcode_CB_B0:
     bic z80bc,z80bc,#1<<30
     fetch 8
;@RES 6,C
opcode_CB_B1:
     bic z80bc,z80bc,#1<<22
     fetch 8
;@RES 6,D
opcode_CB_B2:
     bic z80de,z80de,#1<<30
     fetch 8
;@RES 6,E
opcode_CB_B3:
     bic z80de,z80de,#1<<22
     fetch 8
;@RES 6,H
opcode_CB_B4:
     bic z80hl,z80hl,#1<<30
     fetch 8
;@RES 6,L
opcode_CB_B5:
     bic z80hl,z80hl,#1<<22
     fetch 8
;@RES 6,(HL)
opcode_CB_B6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBB6
     bic r0,r0,#1<<6
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBB6
     fetch 15
;@RES 6,A
opcode_CB_B7:
     bic z80a,z80a,#1<<30
     fetch 8
;@RES 7,B
opcode_CB_B8:
     bic z80bc,z80bc,#1<<31
     fetch 8
;@RES 7,C
opcode_CB_B9:
     bic z80bc,z80bc,#1<<23
     fetch 8
;@RES 7,D
opcode_CB_BA:
     bic z80de,z80de,#1<<31
     fetch 8
;@RES 7,E
opcode_CB_BB:
     bic z80de,z80de,#1<<23
     fetch 8
;@RES 7,H
opcode_CB_BC:
     bic z80hl,z80hl,#1<<31
     fetch 8
;@RES 7,L
opcode_CB_BD:
     bic z80hl,z80hl,#1<<23
     fetch 8
;@RES 7,(HL)
opcode_CB_BE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBBE
     bic r0,r0,#1<<7
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBBE
     fetch 15
;@RES 7,A
opcode_CB_BF:
     bic z80a,z80a,#1<<31
     fetch 8

;@SET 0,B
opcode_CB_C0:
     orr z80bc,z80bc,#1<<24
     fetch 8
;@SET 0,C
opcode_CB_C1:
     orr z80bc,z80bc,#1<<16
     fetch 8
;@SET 0,D
opcode_CB_C2:
     orr z80de,z80de,#1<<24
     fetch 8
;@SET 0,E
opcode_CB_C3:
     orr z80de,z80de,#1<<16
     fetch 8
;@SET 0,H
opcode_CB_C4:
     orr z80hl,z80hl,#1<<24
     fetch 8
;@SET 0,L
opcode_CB_C5:
     orr z80hl,z80hl,#1<<16
     fetch 8
;@SET 0,(HL)
opcode_CB_C6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBC6
     orr r0,r0,#1<<0
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBC6
     fetch 15
;@SET 0,A
opcode_CB_C7:
     orr z80a,z80a,#1<<24
     fetch 8
;@SET 1,B
opcode_CB_C8:
     orr z80bc,z80bc,#1<<25
     fetch 8
;@SET 1,C
opcode_CB_C9:
     orr z80bc,z80bc,#1<<17
     fetch 8
;@SET 1,D
opcode_CB_CA:
     orr z80de,z80de,#1<<25
     fetch 8
;@SET 1,E
opcode_CB_CB:
     orr z80de,z80de,#1<<17
     fetch 8
;@SET 1,H
opcode_CB_CC:
     orr z80hl,z80hl,#1<<25
     fetch 8
;@SET 1,L
opcode_CB_CD:
     orr z80hl,z80hl,#1<<17
     fetch 8
;@SET 1,(HL)
opcode_CB_CE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBCE
     orr r0,r0,#1<<1
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBCE
     fetch 15
;@SET 1,A
opcode_CB_CF:
     orr z80a,z80a,#1<<25
     fetch 8

;@SET 2,B
opcode_CB_D0:
     orr z80bc,z80bc,#1<<26
     fetch 8
;@SET 2,C
opcode_CB_D1:
     orr z80bc,z80bc,#1<<18
     fetch 8
;@SET 2,D
opcode_CB_D2:
     orr z80de,z80de,#1<<26
     fetch 8
;@SET 2,E
opcode_CB_D3:
     orr z80de,z80de,#1<<18
     fetch 8
;@SET 2,H
opcode_CB_D4:
     orr z80hl,z80hl,#1<<26
     fetch 8
;@SET 2,L
opcode_CB_D5:
     orr z80hl,z80hl,#1<<18
     fetch 8
;@SET 2,(HL)
opcode_CB_D6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBD6
     orr r0,r0,#1<<2
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBD6
     fetch 15
;@SET 2,A
opcode_CB_D7:
     orr z80a,z80a,#1<<26
     fetch 8
;@SET 3,B
opcode_CB_D8:
     orr z80bc,z80bc,#1<<27
     fetch 8
;@SET 3,C
opcode_CB_D9:
     orr z80bc,z80bc,#1<<19
     fetch 8
;@SET 3,D
opcode_CB_DA:
     orr z80de,z80de,#1<<27
     fetch 8
;@SET 3,E
opcode_CB_DB:
     orr z80de,z80de,#1<<19
     fetch 8
;@SET 3,H
opcode_CB_DC:
     orr z80hl,z80hl,#1<<27
     fetch 8
;@SET 3,L
opcode_CB_DD:
     orr z80hl,z80hl,#1<<19
     fetch 8
;@SET 3,(HL)
opcode_CB_DE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBDE
     orr r0,r0,#1<<3
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBDE
     fetch 15
;@SET 3,A
opcode_CB_DF:
     orr z80a,z80a,#1<<27
     fetch 8

;@SET 4,B
opcode_CB_E0:
     orr z80bc,z80bc,#1<<28
     fetch 8
;@SET 4,C
opcode_CB_E1:
     orr z80bc,z80bc,#1<<20
     fetch 8
;@SET 4,D
opcode_CB_E2:
     orr z80de,z80de,#1<<28
     fetch 8
;@SET 4,E
opcode_CB_E3:
     orr z80de,z80de,#1<<20
     fetch 8
;@SET 4,H
opcode_CB_E4:
     orr z80hl,z80hl,#1<<28
     fetch 8
;@SET 4,L
opcode_CB_E5:
     orr z80hl,z80hl,#1<<20
     fetch 8
;@SET 4,(HL)
opcode_CB_E6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBE6
     orr r0,r0,#1<<4
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBE6
     fetch 15
;@SET 4,A
opcode_CB_E7:
     orr z80a,z80a,#1<<28
     fetch 8
;@SET 5,B
opcode_CB_E8:
     orr z80bc,z80bc,#1<<29
     fetch 8
;@SET 5,C
opcode_CB_E9:
     orr z80bc,z80bc,#1<<21
     fetch 8
;@SET 5,D
opcode_CB_EA:
     orr z80de,z80de,#1<<29
     fetch 8
;@SET 5,E
opcode_CB_EB:
     orr z80de,z80de,#1<<21
     fetch 8
;@SET 5,H
opcode_CB_EC:
     orr z80hl,z80hl,#1<<29
     fetch 8
;@SET 5,L
opcode_CB_ED:
     orr z80hl,z80hl,#1<<21
     fetch 8
;@SET 5,(HL)
opcode_CB_EE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBEE
     orr r0,r0,#1<<5
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBEE
     fetch 15
;@SET 5,A
opcode_CB_EF:
     orr z80a,z80a,#1<<29
     fetch 8

;@SET 6,B
opcode_CB_F0:
     orr z80bc,z80bc,#1<<30
     fetch 8
;@SET 6,C
opcode_CB_F1:
     orr z80bc,z80bc,#1<<22
     fetch 8
;@SET 6,D
opcode_CB_F2:
     orr z80de,z80de,#1<<30
     fetch 8
;@SET 6,E
opcode_CB_F3:
     orr z80de,z80de,#1<<22
     fetch 8
;@SET 6,H
opcode_CB_F4:
     orr z80hl,z80hl,#1<<30
     fetch 8
;@SET 6,L
opcode_CB_F5:
     orr z80hl,z80hl,#1<<22
     fetch 8
;@SET 6,(HL)
opcode_CB_F6:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBF6
     orr r0,r0,#1<<6
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBF6
     fetch 15
;@SET 6,A
opcode_CB_F7:
     orr z80a,z80a,#1<<30
     fetch 8
;@SET 7,B
opcode_CB_F8:
     orr z80bc,z80bc,#1<<31
     fetch 8
;@SET 7,C
opcode_CB_F9:
     orr z80bc,z80bc,#1<<23
     fetch 8
;@SET 7,D
opcode_CB_FA:
     orr z80de,z80de,#1<<31
     fetch 8
;@SET 7,E
opcode_CB_FB:
     orr z80de,z80de,#1<<23
     fetch 8
;@SET 7,H
opcode_CB_FC:
     orr z80hl,z80hl,#1<<31
     fetch 8
;@SET 7,L
opcode_CB_FD:
     orr z80hl,z80hl,#1<<23
     fetch 8
;@SET 7,(HL)
opcode_CB_FE:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpCBFE
     orr r0,r0,#1<<7
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpCBFE
     fetch 15
;@SET 7,A
opcode_CB_FF:
     orr z80a,z80a,#1<<31
     fetch 8



;@##################################
;@##################################
;@###  opcodes DD  #########################
;@##################################
;@##################################
;@Because the DD opcodes are not a complete range from 00-FF I have
;@created this sub routine that will catch any undocumented ops
;@halt the emulator and mov the current intruction to r0
;@at a later stage I may change to display a text message on the screen
opcode_DD_NF:
     ldrb r0,[z80pc],#1
     ldr pc,[opcodes,r0, lsl #2]
     mov r2,#0x10*4
     cmp r2,z80xx
     bne opcode_FD_NF
     mov r0,#0xDD00
     orr r0,r0,r1
     b end_loop
opcode_FD_NF:
     mov r0,#0xFD00
     orr r0,r0,r1
     b end_loop
opcode_DD_NF2:
     mov r0,#0xDD0000
     orr r0,r0,#0xCB00
     orr r0,r0,r1
     b end_loop
;@ADD IX,BC
opcode_DD_09:
     ldr r0,[cpucontext,z80xx]
     mov r1,r0
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     adds r0,r0,z80bc
     orrcs z80f,z80f,#1<<CFlag
     eor r1,r1,z80bc
     eor r1,r1,r0
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     str r0,[cpucontext,z80xx]
     fetch 15
;@ADD IX,DE
opcode_DD_19:
     ldr r0,[cpucontext,z80xx]
     mov r1,r0
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     adds r0,r0,z80de
     orrcs z80f,z80f,#1<<CFlag
     eor r1,r1,z80de
     eor r1,r1,r0
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     str r0,[cpucontext,z80xx]
     fetch 15
;@LD IX,NN
opcode_DD_21:
     DAM_FETCH16D r0
     mov r0,r0, lsl #16
     str r0,[cpucontext,z80xx]
     fetch 10
;@LD (NN),IX
opcode_DD_22:
     DAM_FETCH16D r1
     ldr r0,[cpucontext,z80xx]
     mov r0,r0, lsr #16
     DAM_WRITE16 OpDD22
     fetch 20
;@INC IX
opcode_DD_23:
     ldr r0,[cpucontext,z80xx]
     add r0,r0,#1<<16
     str r0,[cpucontext,z80xx]
     fetch 10
;@INC I  (IX)
opcode_DD_24:
     ldr r2,[cpucontext,z80xx]
     and r0,r2,#0xFF<<24
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and r2,r2,#0xFF<<16
     orr r2,r2,r0
     str r2,[cpucontext,z80xx]
     fetch 8
;@DEC I   (IX)
opcode_DD_25:
     ldr r2,[cpucontext,z80xx]
     and r0,r2,#0xFF<<24
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and r2,r2,#0xFF<<16
     orr r2,r2,r0
     str r2,[cpucontext,z80xx]
     fetch 8
;@LD I,N  (IX)
opcode_DD_26:
     DAM_FETCH8D r1
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     orr r0,r0,r1, lsl #24
     str r0,[cpucontext,z80xx]
     fetch 15
;@ADD IX,IX
opcode_DD_29:
     ldr r0,[cpucontext,z80xx]
     mov r1,r0
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     adds r0,r0,r0
     orrcs z80f,z80f,#1<<CFlag
     eor r1,r1,r1
     eor r1,r1,r0
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     str r0,[cpucontext,z80xx]
     fetch 15
;@LD IX,(NN)
opcode_DD_2A:
     DAM_FETCH16D r0
     
     ;@stmdb sp!,{r3,r12,lr}
     ;@mov lr,pc
     ;@ldr pc,[cpucontext,#z80_read16] ;@ r0=addr - data returned in r0
     ;@ldmia sp!,{r3,r12,lr} 
     
     stmdb sp!,{lr}
     DAM_READ16 OpDD2A
     ldmia sp!,{lr} 
     
     mov r1,r0, lsl #16
     str r1,[cpucontext,z80xx]
     fetch 20
;@DEC IX
opcode_DD_2B:
     ldr r0,[cpucontext,z80xx]
     sub r0,r0,#1<<16
     str r0,[cpucontext,z80xx]
     fetch 10
;@INC I  (IX)
opcode_DD_2C:
     ldr r2,[cpucontext,z80xx]
     mov r0,r2, lsl #8
     adds r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     and r2,r2,#0xFF<<24
     orr r2,r2,r0, lsr #8
     str r2,[cpucontext,z80xx]
     fetch 10
;@DEC X   (IX)
opcode_DD_2D:
     ldr r2,[cpucontext,z80xx]
     mov r0,r2, lsl #8
     subs r0,r0,#1<<24
     mrs r1,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r1, lsr #28
     and r1,r0,#0xF<<24
     teq r1,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     and r2,r2,#0xFF<<24
     orr r2,r2,r0, lsr #8
     str r2,[cpucontext,z80xx]
     fetch 10
;@LD X,N  (IX)
opcode_DD_2E:
     DAM_FETCH8D r1
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     orr r0,r0,r1, lsl #16
     str r0,[cpucontext,z80xx]
     fetch 15
;@INC (IX+N)
opcode_DD_34:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDD34
     mov r0,r0, lsl #24
     adds r0,r0,#1<<24
     mrs r2,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r2, lsr #28
     tst r0,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDD34
     fetch 23
;@DEC (IX+N)
opcode_DD_35:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDD35
     mov r0,r0, lsl #24
     subs r0,r0,#1<<24
     mrs r2,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,r2, lsr #28
     and r2,r0,#0xF<<24
     teq r2,#0xF<<24
     orreq z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDD35
     fetch 23
;@LD (IX+N),N
opcode_DD_36:
     ;@ ldrsb r2,[z80pc],#1
     ;@ ldrb r0,[z80pc],#1
     ;@ OopsWare
     DAM_FETCH8D_S 1
     stmdb sp!,{r0}
     DAM_FETCH8D r0
     ldmia sp!,{r2}
     
     ldr r1,[cpucontext,z80xx]
     add r1,r2,r1, lsr #16
     DAM_WRITE8 OpDD36
     fetch 19
;@ADD IX,SP
opcode_DD_39:
     ;@ldr r2,[cpucontext,#z80sp_base]
     ;@sub r2,z80sp,r2
     
     mov r2,z80sp
     
     ldr r0,[cpucontext,z80xx]
     mov r1,r0
     bic z80f,z80f,#(1<<NFlag)|(1<<CFlag)|(1<<HFlag)
     adds r0,r0,r2, lsl #16
     orrcs z80f,z80f,#1<<CFlag
     eor r1,r1,r2, lsl #16
     eor r1,r1,r0
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     str r0,[cpucontext,z80xx]
     fetch 15
;@LD B,I ( IX )
opcode_DD_44:
     and z80bc,z80bc,#0xFF<<16
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<24
     orr z80bc,z80bc,r1
     fetch 8
;@LD B,X ( IX )
opcode_DD_45:
     and z80bc,z80bc,#0xFF<<16
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<16
     orr z80bc,z80bc,r1, lsl #8
     fetch 8
;@LD B,(IX,N)
opcode_DD_46:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD46
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 19
;@LD C,I   (IX)
opcode_DD_4C:
     and z80bc,z80bc,#0xFF<<24
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<24
     orr z80bc,z80bc,r1, lsr #8
     fetch 8
;@LD C,X   (IX)
opcode_DD_4D:
     and z80bc,z80bc,#0xFF<<24
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<16
     orr z80bc,z80bc,r1 
     fetch 8
;@LD C,(IX,N)
opcode_DD_4E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD4E
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 19

;@LD D,I  ( IX)
opcode_DD_54:
     and z80de,z80de,#0xFF<<16
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<24
     orr z80de,z80de,r1
     fetch 8
;@LD D,X  (IX)
opcode_DD_55:
     and z80de,z80de,#0xFF<<16
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<16
     orr z80de,z80de,r1, lsl #8
     fetch 8
;@LD D,(IX,N)
opcode_DD_56:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD56
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 19
;@LD E,I  ( IX)
opcode_DD_5C:
     and z80de,z80de,#0xFF<<24
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<24
     orr z80de,z80de,r1, lsr #8
     fetch 8
;@LD E,X  ( IX)
opcode_DD_5D:
     and z80de,z80de,#0xFF<<24
     ldr r0,[cpucontext,z80xx]
     and r1,r0,#0xFF<<16
     orr z80de,z80de,r1
     fetch 8
;@LD E,(IX,N)
opcode_DD_5E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD5E
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 19
;@LD I,B  ( IX)
opcode_DD_60:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     and r1,z80bc,#0xFF<<24
     orr r0,r0,r1
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD I,C  ( IX)
opcode_DD_61:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     and r1,z80bc,#0xFF<<16
     orr r0,r0,r1, lsl #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD I,D  ( IX)
opcode_DD_62:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     and r1,z80de,#0xFF<<24
     orr r0,r0,r1
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD I,E  ( IX)
opcode_DD_63:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     and r1,z80de,#0xFF<<16
     orr r0,r0,r1, lsl #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD I,I  ( IX)
opcode_DD_64:
     fetch 8
;@LD I,X  ( IX)
opcode_DD_65:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     orr r0,r0,r0, lsl #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD H,(IX,N)
opcode_DD_66:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD66
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 19
;@LD I,A  ( IX)
opcode_DD_67:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<16
     orr r0,r0,z80a
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,B    (IX)
opcode_DD_68:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     and r1,z80bc,#0xFF<<24
     orr r0,r0,r1, lsr #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,C    (IX)
opcode_DD_69:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     and r1,z80bc,#0xFF<<16
     orr r0,r0,r1
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,D    (IX)
opcode_DD_6A:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     and r1,z80de,#0xFF<<24
     orr r0,r0,r1, lsr #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,E    (IX)
opcode_DD_6B:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     and r1,z80de,#0xFF<<16
     orr r0,r0,r1
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,I    (IX)
opcode_DD_6C:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     orr r0,r0,r0, lsr #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD X,X    (IX)
opcode_DD_6D:
     fetch 8
;@LD L,(IX,N)
opcode_DD_6E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD6E
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 19
;@LD X,A  (IX)
opcode_DD_6F:
     ldr r0,[cpucontext,z80xx]
     and r0,r0,#0xFF<<24
     orr r0,r0,z80a, lsr #8
     str r0,[cpucontext,z80xx]
     fetch 8
;@LD (IX,N),B
opcode_DD_70:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80bc, lsr #24
     DAM_WRITE8 OpDD70
     fetch 19
;@LD (IX,N),C
opcode_DD_71:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     DAM_WRITE8 OpDD71
     fetch 19
;@LD (IX,N),D
opcode_DD_72:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80de, lsr #24
     DAM_WRITE8 OpDD72
     fetch 19
;@LD (IX,N),E
opcode_DD_73:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80de, lsr #16
     and r0,r0,#0xFF
     DAM_WRITE8 OpDD73
     fetch 19
;@LD (IX,N),H
opcode_DD_74:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80hl, lsr #24
     DAM_WRITE8 OpDD74
     fetch 19
;@LD (IX,N),L
opcode_DD_75:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80hl, lsr #16
     and r0,r0,#0xFF
     DAM_WRITE8 OpDD75
     fetch 19
;@LD (IX,N),A
opcode_DD_77:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r1,r0,r1, lsr #16
     mov r0,z80a, lsr #24
     DAM_WRITE8 OpDD77
     fetch 19
;@LD A,I  from (IX)
opcode_DD_7C:
     ldr r0,[cpucontext,z80xx]
     and z80a,r0,#0xFF<<24
     fetch 8
;@LD A,X  from (IX)
opcode_DD_7D:
     ldr r0,[cpucontext,z80xx]
     mov z80a,r0, lsl #8
     fetch 8
;@LD A,(IX,N)
opcode_DD_7E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD7E
     mov z80a,r0, lsl #24
     fetch 19
;@ADD A,I   ( IX)
opcode_DD_84:
     ldr r1,[cpucontext,z80xx] 
     and r1,r1,#0xFF<<24
     mov r0,z80a
     adds z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@ADD A,X   ( IX)
opcode_DD_85:
     ldr r1,[cpucontext,z80xx]
     mov r0,z80a
     adds z80a,z80a,r1, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@ADD A,(IX+N)
opcode_DD_86:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD86
     mov r1,z80a
     adds z80a,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r1,r1,r0, lsl #24
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 19
;@ADC A,I    (IX)
opcode_DD_8C:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@ADC A,X    (IX)
opcode_DD_8D:
     ldr r1,[cpucontext,z80xx]
     mov r0,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r1, lsl #8
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
;@ADC A,(IX+N)
opcode_DD_8E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD8E
     mov r1,z80a
     eor r2,r2,r2
     movs z80f,z80f, lsr #2
     mvncs r2,#0xFF<<24
     orr r2,r2,r0, lsl #24
     adcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor r1,r1,r2
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 19
;@SUB A,I  (IX)
opcode_DD_94:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     mov r0,z80a
     subs z80a,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@SUB A,X  (IX)
opcode_DD_95:
     ldr r1,[cpucontext,z80xx]
     mov r0,z80a
     subs z80a,z80a,r1, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r1, lsl #8
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@SUB A,(IX+N)
opcode_DD_96:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD96
     mov r1,z80a
     subs z80a,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1,r1,r0, lsl #24
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 19
;@SBC A,I   (IX)
opcode_DD_9C:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@SBC A,X   (IX)
opcode_DD_9D:
     ldr r1,[cpucontext,z80xx]
     mov r0,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r1, lsl #8
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,r0,r2
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@SBC A,(IX+N)
opcode_DD_9E:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDD9E
     mov r1,z80a
     eor r2,r2,r2
     eor z80f,z80f,#1<<CFlag
     movs z80f,z80f, lsr #2
     mvncc r2,#0xFF<<24
     orr r2,r2,r0, lsl #24
     sbcs z80a,z80a,r2
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1,r1,r2
     eor r1,r1,z80a
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 19
;@AND I   (IX)
opcode_DD_A4:
     ldr r1,[cpucontext,z80xx]
     and z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 8
;@AND X   (IX)
opcode_DD_A5:
     ldr r1,[cpucontext,z80xx]
     and z80a,z80a,r1, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 8
;@AND (IX+N)
opcode_DD_A6:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDA6
     and z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     orr z80f,z80f,#1<<HFlag
     fetch 19
;@XOR I    (IX)
opcode_DD_AC:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     eor z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@XOR X    (IX)
opcode_DD_AD:
     ldr r1,[cpucontext,z80xx]
     eor z80a,z80a,r1, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@XOR (IX+N)
opcode_DD_AE:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDAE
     eor z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 19
;@OR I    (IX)
opcode_DD_B4:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     orr z80a,z80a,r1
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@OR X    (IX)
opcode_DD_B5:
     ldr r1,[cpucontext,z80xx]
     orr z80a,z80a,r1, lsl #8
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 8
;@OR (IX+N)
opcode_DD_B6:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDB6
     orr z80a,z80a,r0, lsl #24
     sub r0,opcodes,#0x100
     ldrb z80f,[r0,z80a, lsr #24]
     fetch 19
;@CP I    (IX)
opcode_DD_BC:
     ldr r1,[cpucontext,z80xx]
     and r1,r1,#0xFF<<24
     subs r2,z80a,r1
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@CP X    (IX)
opcode_DD_BD:
     ldr r1,[cpucontext,z80xx]
     subs r2,z80a,r1, lsl #8
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r1, lsl #8
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 8
;@CP (IX+N)
opcode_DD_BE:
     DAM_FETCH8D_S 1
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDBE
     subs r2,z80a,r0, lsl #24
     mrs z80f,CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r0,z80a,r0, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#1<<NFlag
     fetch 19


opcodes_DD_CB_LOCAL: .word opcodes_DD_CB
opcode_DD_CB:
;@Looks up the opcode on the opcodes_DD_CB table and then 
;@moves the PC to the location of the subroutine
     ;@ldrb r1,[z80pc,#1]
     
     ldr r2,[cpucontext,#z80pc_base]		;@ r2 = z80 pc
     sub r2,z80pc,r2
     add r2,r2,#1
     ldr r1,[cpucontext,#ppMemFetchData]	;@ r1 point to ppMemFetchData[0]
     mov r0,r2,lsr#8						
     ldr r1,[r1,r0,lsl#2]					;@ r1 = ppMemFetchData[addr >> 8]
     ldrb r1,[r1,r2]
     
     ;@add z80pc,z80pc,#1
     ;@DAM_FETCH8D r1
     ;@sub z80pc,z80pc,#2

     ldr pc,[pc,r1, lsl #2]
     
        .word 0x00
opcodes_DD_CB:  
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_06,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_0E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_16,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_1E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_26,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_2E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_36,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_3E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_46,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_4E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_56,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_5E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_66,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_6E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_76,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_7E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_86,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_8E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_96,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_9E,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_A6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_AE,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_B6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_BE,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_C6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_CE,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_D6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_DE,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_E6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_EE,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_F6,opcode_DD_NF2
        .word opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_NF2,opcode_DD_CB_FE,opcode_DD_NF2

;@RLC (IX+N) 
opcode_DD_CB_06:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB06
     movs r0,r0, lsl #25
     orrcs r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDDCB06
     fetch 23
;@RRC (IX+N) 
opcode_DD_CB_0E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB0E
     movs r0,r0, lsr #1
     orrcs r0,r0,#1<<7
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     DAM_WRITE8 OpDDCB0E
     fetch 23
;@RL (IX+N) 
opcode_DD_CB_16:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB16
     mov r0,r0, lsl #24
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<23       
     movs r0,r0, lsl #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDDCB16
     fetch 23
;@RR (IX+N) 
opcode_DD_CB_1E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB1E
     tst z80f,#1<<CFlag
     orrne r0,r0,#1<<8
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     DAM_WRITE8 OpDDCB1E
     fetch 23

;@SLA (IX+N) 
opcode_DD_CB_26:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB26
     movs r0,r0, lsl #25
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag 
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDDCB26
     fetch 23
;@SRA (IX+N) 
opcode_DD_CB_2E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB2E
     mov r0,r0, lsl #24
     movs r0,r0, asr #25
     and r0,r0,#0xFF
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     DAM_WRITE8 OpDDCB2E
     fetch 23
;@SLL (IX+N) 
opcode_DD_CB_36:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB36
     movs r0,r0, lsl #25
     orr r0,r0,#1<<24
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0, lsr #24]
     orrcs z80f,z80f,#1<<CFlag
     mov r0,r0, lsr #24
     DAM_WRITE8 OpDDCB36
     fetch 23
;@SRL (IX+N)
opcode_DD_CB_3E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB3E
     movs r0,r0, lsr #1
     sub r2,opcodes,#0x100
     ldrb z80f,[r2,r0]
     orrcs z80f,z80f,#1<<CFlag 
     DAM_WRITE8 OpDDCB3E
     fetch 23

;@BIT 0,(IX+N) 
opcode_DD_CB_46:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB46
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<0
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 1,(IX+N) 
opcode_DD_CB_4E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB4E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<1
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 2,(IX+N) 
opcode_DD_CB_56:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB56
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<2
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 3,(IX+N) 
opcode_DD_CB_5E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB5E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<3
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 4,(IX+N) 
opcode_DD_CB_66:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB66
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<4
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 5,(IX+N) 
opcode_DD_CB_6E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB6E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<5
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 6,(IX+N) 
opcode_DD_CB_76:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB76
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<6
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     fetch 20
;@BIT 7,(IX+N) 
opcode_DD_CB_7E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8 OpDDCB7E
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<HFlag
     tst r0,#1<<7
     orreq z80f,z80f,#(1<<ZFlag)|(1<<VFlag)
     orrne z80f,z80f,#1<<SFlag
     fetch 20
;@RES 0,(IX+N) 
opcode_DD_CB_86:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16

     ;@stmdb sp!,{r3,r12}  
     ;@stmdb sp!,{r0} ;@ save addr as well
     ;@mov lr,pc
     ;@ldr pc,[cpucontext,#z80_read8] ;@ r0=addr - data returned in r0
     ;@bic r0,r0,#1<<0
     ;@ldmia sp!,{r1}  ;@ restore addr into r1
     ;@mov lr,pc
     ;@ldr pc,[cpucontext,#z80_write8] ;@ r0=data r1=addr
     ;@ldmia sp!,{r3,r12}
     
     DAM_READ8R1 OpDDCB86
     bic r0,r0,#1<<0
     DAM_WRITE8 OpDDCB86
     fetch 23
;@RES 1,(IX+N) 
opcode_DD_CB_8E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB8E
     bic r0,r0,#1<<1
     DAM_WRITE8 OpDDCB8E
     fetch 23
;@RES 2,(IX+N) 
opcode_DD_CB_96:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB96
     bic r0,r0,#1<<2
     DAM_WRITE8 OpDDCB96
     fetch 23
;@RES 3,(IX+N) 
opcode_DD_CB_9E:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCB9E
     bic r0,r0,#1<<3
     DAM_WRITE8 OpDDCB9E
     fetch 23
;@RES 4,(IX+N) 
opcode_DD_CB_A6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBA6
     bic r0,r0,#1<<4
     DAM_WRITE8 OpDDCBA6
     fetch 23
;@RES 5,(IX+N) 
opcode_DD_CB_AE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBAE
     bic r0,r0,#1<<5
     DAM_WRITE8 OpDDCBAE
     fetch 23
;@RES 6,(IX+N) 
opcode_DD_CB_B6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBB0
     bic r0,r0,#1<<6
     DAM_WRITE8 OpDDCBB0
     fetch 23
;@RES 7,(IX+N) 
opcode_DD_CB_BE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBBE
     bic r0,r0,#1<<7
     DAM_WRITE8 OpDDCBBE
     fetch 23
;@SET 0,(IX+N) 
opcode_DD_CB_C6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBC6
     orr r0,r0,#1<<0
     DAM_WRITE8 OpDDCBC6
     fetch 23
;@SET 1,(IX+N) 
opcode_DD_CB_CE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBCE
     orr r0,r0,#1<<1
     DAM_WRITE8 OpDDCBCE
     fetch 23
;@SET 2,(IX+N) 
opcode_DD_CB_D6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBD6
     orr r0,r0,#1<<2
     DAM_WRITE8 OpDDCBD6
     fetch 23
;@SET 3,(IX+N) 
opcode_DD_CB_DE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBDE
     orr r0,r0,#1<<3
     DAM_WRITE8 OpDDCBDE
     fetch 23
;@SET 4,(IX+N) 
opcode_DD_CB_E6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBE6
     orr r0,r0,#1<<4
     DAM_WRITE8 OpDDCBE6
     fetch 23
;@SET 5,(IX+N) 
opcode_DD_CB_EE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBEE
     orr r0,r0,#1<<5
     DAM_WRITE8 OpDDCBEE
     fetch 23
;@SET 6,(IX+N) 
opcode_DD_CB_F6:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBF6
     orr r0,r0,#1<<6
     DAM_WRITE8 OpDDCBF6
     fetch 23
;@SET 7,(IX+N) 
opcode_DD_CB_FE:
     DAM_FETCH8D_S 2
     ldr r1,[cpucontext,z80xx]
     add r0,r0,r1, lsr #16
     DAM_READ8R1 OpDDCBFE
     orr r0,r0,#1<<7
     DAM_WRITE8 OpDDCBFE
     fetch 23

;@POP IX
opcode_DD_E1:
     ;@ldrb r1,[z80sp],#1
     ;@ldrb r2,[z80sp],#1
     ;@orr r0,r1,r2, lsl #8
     POP_r0 2
     mov r0,r0, lsl #16
     str r0,[cpucontext,z80xx]
     fetch 10
;@EX (SP),IX
opcode_DD_E3:
     ;@ldrb r0,[z80sp]
     ;@ldrb r1,[z80sp,#1]
     ;@orr r2,r0,r1, lsl #8
     ;@ldr r1,[cpucontext,z80xx]
     ;@mov r0,r1, lsr #24
     ;@strb r0,[z80sp,#1]
     ;@mov r0,r1, lsr #16
     ;@strb r0,[z80sp]
     ;@mov r2,r2, lsl #16
     ;@str r2,[cpucontext,z80xx]
     
     POP_r0 0
     stmdb sp!,{r0}
     ldr r0,[cpucontext,z80xx]
     mov r0,r0, lsr #16
     PUSH_r0 0
     ldmia sp!,{r0}
     mov r0,r0,lsl #16     
     str r0,[cpucontext,z80xx]
     
     fetch 23
;@PUSH IX
opcode_DD_E5:
     ldr r0,[cpucontext,z80xx]
     
     ;@mov r1,r0, lsr #24
     ;@strb r1,[z80sp,#-1]!
     ;@mov r1,r0, lsr #16
     ;@strb r1,[z80sp,#-1]!
     
     mov r0,r0,lsr #16
     PUSH_r0 2
     
     fetch 15
;@JP (IX)
opcode_DD_E9:
     ldr r0,[cpucontext,z80xx]

     mov r0,r0, lsr #16
     REBASE_PC

     fetch 8
;@LD SP,IX
opcode_DD_F9:
     ldr r0,[cpucontext,z80xx]
     mov z80sp,r0, lsr #16

     fetch 10

;@##################################
;@##################################
;@###  opcodes ED  #########################
;@##################################
;@##################################

opcode_ED_NF:
     ldrb r0,[z80pc],#1
     ldr pc,[opcodes,r0, lsl #2]
     mov r0,#0xED00
     orr r0,r0,r1
     b end_loop

;@IN B,(C)
opcode_ED_40:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80bc,z80bc,#0xFF<<16
     orr z80bc,z80bc,r0, lsl #24
     fetch 12
;@OUT (C),B
opcode_ED_41:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80bc, lsr #24
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12

;@SBC HL,BC
opcode_ED_42:
     mov r0, z80bc
     eor z80f, z80f, #(1<<CFlag)
     tst r0, z80f, lsl #(32-CFlag)
     orrcc r0, r0, #0xFF
     orrcc r0, r0, #0xFF<<8
     eor r1, z80hl, r0
     sbcs z80hl, z80hl, r0
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1, r1, z80hl
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f, z80f, #1<<NFlag
     fetch 15

;@LD (NN),BC
opcode_ED_43:
     DAM_FETCH16D r1
     mov r0,z80bc, lsr #16
     DAM_WRITE16 OpED43
     fetch 16
;@NEG
opcode_ED_44:
     mov r0,z80a
     rsbs z80a, z80a, #0
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     orr z80f,z80f,#1<<NFlag
     eor r0,r0,#0
     eor r0,r0,z80a
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 8
 
;@RETN
opcode_ED_45:
     ;@ldrb r0,[z80sp],#1
     ;@ldrb r1,[z80sp],#1
     ;@orr r0,r0,r1, lsl #8
     
     POP_r0 2

     REBASE_PC

     ldrb r0,[cpucontext,#z80if]
     tst r0,#Z80_IF2
     orrne r0,r0,#Z80_IF1
     biceq r0,r0,#Z80_IF1
     strb r0,[cpucontext,#z80if]
     fetch 14

;@IM 0
opcode_ED_46:
     mov r0,#0
     strb r0,[cpucontext,#z80im]
     fetch 8
;@LD I,A
opcode_ED_47:
     str z80a,[cpucontext,#z80i]
     fetch 8
;@IN C,(C)
opcode_ED_48:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80bc,z80bc,#0xFF<<24
     orr z80bc,z80bc,r0, lsl #16
     fetch 12
;@OUT (C),C
opcode_ED_49:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     ;@mov r1,r0
     and r1,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@ADC HL,BC
opcode_ED_4A:
     tst r0, z80f, lsl #(32-CFlag)
     orrcs z80hl, z80hl, #0xFF
     orrcs z80hl, z80hl, #0xFF<<8
     eor r0, z80hl, z80bc
     adcs z80hl, z80hl, z80bc
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor r0, r0, z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 15
;@LD BC,(NN)
opcode_ED_4B:
     DAM_FETCH16D r0
     DAM_READ16 OpED4B
     mov z80bc,r0, lsl #16
     fetch 20
;@RETI
opcode_ED_4D:
     ;@ldrb r0,[z80sp],#1
     ;@ldrb r1,[z80sp],#1
     ;@orr r0,r0,r1, lsl #8
     
     POP_r0 2
     
     REBASE_PC

     fetch 14

;@LD R,A
;@??????
opcode_ED_4F:
     fetch 8


;@IN D,(C)
opcode_ED_50:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80de,z80de,#0xFF<<16
     orr z80de,z80de,r0, lsl #24
     fetch 12
;@OUT (C),D
opcode_ED_51:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80de, lsr #24
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@SBC HL,DE
opcode_ED_52:
     mov r0, z80de
     eor z80f, z80f, #(1<<CFlag)
     tst r0, z80f, lsl #(32-CFlag)
     orrcc r0, r0, #0xFF
     orrcc r0, r0, #0xFF<<8
     eor r1, z80hl, r0
     sbcs z80hl, z80hl, r0
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1, r1, z80hl
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f, z80f, #1<<NFlag
     fetch 15
;@LD (NN),DE
opcode_ED_53:
     DAM_FETCH16D r1
     mov r0,z80de, lsr #16
     DAM_WRITE16 OpED53
     fetch 16
;@IM 1
opcode_ED_56:
     mov r0,#1
     strb r0,[cpucontext,#z80im]
     fetch 8
;@LD A,I
opcode_ED_57:
     ldr z80a,[cpucontext,#z80i]
     bic z80f,z80f,#(1<<HFlag)|(1<<NFlag)|(1<<VFlag)|(1<<ZFlag)
     orreq z80f,z80f,#1<<ZFlag
     ldrb r0,[cpucontext,#z80if]
     tst r0,#Z80_IF2
     orrne z80f,z80f,#(1<<VFlag)
     fetch 8
;@IN E,(C)
opcode_ED_58:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80de,z80de,#0xFF<<24
     orr z80de,z80de,r0, lsl #16
     fetch 12
;@OUT (C),E
opcode_ED_59:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80de, lsr #16
     and r1,r1,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@ADC HL,DE
opcode_ED_5A:
     tst r0, z80f, lsl #(32-CFlag)
     orrcs z80hl, z80hl, #0xFF
     orrcs z80hl, z80hl, #0xFF<<8
     eor r0, z80hl, z80de
     adcs z80hl, z80hl, z80de
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor r0, r0, z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 15
;@LD DE,(NN)
opcode_ED_5B:
     DAM_FETCH16D r0
     DAM_READ16 OpED5B
     mov z80de,r0, lsl #16
     fetch 15
;@IM 2
opcode_ED_5E:
     mov r0,#2
     strb r0,[cpucontext,#z80im]
     fetch 8
;@LD A,R
opcode_ED_5F:
     mov z80a,z80_icount, lsl #24
     sub r0,opcodes,#0x100
     ldrb r0,[r0,z80a, lsr #24]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r0
     ldrb r0,[cpucontext,#z80if]
     tst r0,#Z80_IF2
     biceq z80f,z80f,#(1<<VFlag)
     orrne z80f,z80f,#(1<<VFlag)
     fetch 8
;@IN H,(C)
opcode_ED_60:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80hl,z80hl,#0xFF<<16
     orr z80hl,z80hl,r0, lsl #24
     fetch 12
;@OUT (C),H
opcode_ED_61:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80hl, lsr #24
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@SBC HL,HL
opcode_ED_62:
     mov r0, z80hl
     eor z80f, z80f, #(1<<CFlag)
     tst r0, z80f, lsl #(32-CFlag)
     orrcc r0, r0, #0xFF
     orrcc r0, r0, #0xFF<<8
     eor r1, z80hl, r0
     sbcs z80hl, z80hl, r0
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1, r1, z80hl
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f, z80f, #1<<NFlag
     fetch 15
;@RRD
opcode_ED_67:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpED67
     and r1,z80a,#0xF<<24
     orr r0,r0,r1, lsr #16
     and r1,r0,#0xF
     bic z80a,z80a,#0xF<<24
     orr z80a,z80a,r1, lsl #24
     mov r0,r0, lsr #4
     and z80f,z80f,#1<<CFlag
     sub r1,opcodes,#0x100
     ldrb r2,[r1,z80a, lsr #24]
     orr z80f,z80f,r2
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpED67
     fetch 18
;@IN L,(C)
opcode_ED_68:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     and z80hl,z80hl,#0xFF<<24
     orr z80hl,z80hl,r0, lsl #16
     fetch 12
;@OUT (C),L
opcode_ED_69:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80hl, lsr #16
     and r1,r1,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@ADC HL,HL
opcode_ED_6A:
     mov r1,z80hl
     tst r0, z80f, lsl #(32-CFlag)
     orrcs z80hl, z80hl, #0xFF
     orrcs z80hl, z80hl, #0xFF<<8
     eor r0, z80hl, r1
     adcs z80hl, z80hl, r1
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor r0, r0, z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 15
;@RLD
opcode_ED_6F:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpED6F
     mov r0,r0, lsl #4
     and r1,z80a,#0xF<<24
     orr r0,r0,r1, lsr #24
     and r1,r0,#0xF<<8
     and z80a,z80a,#0xF<<28
     orr z80a,z80a,r1, lsl #16
     and z80f,z80f,#1<<CFlag
     sub r1,opcodes,#0x100
     ldrb r2,[r1,z80a, lsr #24]
     orr z80f,z80f,r2
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpED6F
     fetch 18

;@IN F,(C)
opcode_ED_70:
	mov r0,z80bc, lsr #16
	stmdb sp!,{r3,r12}
	mov lr,pc
	ldr pc,[cpucontext,#z80_in]				;@ r0=port - data returned in r0
	ldmia sp!,{r3,r12}

	and z80f,z80f,#1<<CFlag
	sub r1,opcodes,#0x100
	ldrb r0,[r1,r0]
	orr z80f,z80f,r0
	fetch 12
;@OUT (C),0
opcode_ED_71:
	mov r1,#0
	mov r0,z80bc, lsr #16
	stmdb sp!,{r3,r12}
	mov lr,pc
	ldr pc,[cpucontext,#z80_out]			;@ r0=port r1=data
	ldmia sp!,{r3,r12}
	fetch 12
     
;@SBC HL,SP
opcode_ED_72:
     ;@ldr r0,[cpucontext,#z80sp_base]
     ;@sub r0,z80sp,r0
     
     mov r0,z80sp
     
     mov r0, r0, lsl #16
     eor z80f, z80f, #(1<<CFlag)
     tst r0, z80f, lsl #(32-CFlag)
     orrcc r0, r0, #0xFF
     orrcc r0, r0, #0xFF<<8
     eor r1, z80hl, r0
     sbcs z80hl, z80hl, r0
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor z80f,z80f,#1<<CFlag
     eor r1, r1, z80hl
     tst r1,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f, z80f, #1<<NFlag
     fetch 15
;@LD (NN),SP
opcode_ED_73:
     DAM_FETCH16D r1
     ;@ldr r0,[cpucontext,#z80sp_base]
     ;@sub r0,z80sp,r0
     
     mov r0,z80sp
     
     DAM_WRITE16 OpED73
     fetch 16
;@IN A,(C)
opcode_ED_78:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     sub r2,opcodes,#0x100
     ldrb r1,[r2,r0]
     and z80f,z80f,#1<<CFlag
     orr z80f,z80f,r1
     mov z80a,r0, lsl #24
     fetch 12
;@OUT (C),A
opcode_ED_79:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     mov r1,z80a, lsr #24
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     fetch 12
;@ADC HL,SP
opcode_ED_7A:
     ;@ldr r1,[cpucontext,#z80sp_base]
     ;@sub r1,z80sp,r1
     
     mov r1,z80sp
     
     tst r0, z80f, lsl #(32-CFlag)
     orrcs z80hl, z80hl, #0xFF
     orrcs z80hl, z80hl, #0xFF<<8
     eor r0, z80hl, r1, lsl #16
     adcs z80hl, z80hl, r1, lsl #16
     mrs z80f, CPSR
     mov z80f,z80f, lsr #28
     eor r0, r0, z80hl
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     fetch 15
;@LD SP,(NN)
opcode_ED_7B:
     DAM_FETCH16D r0
     DAM_READ16 OpED7B
     mov z80sp,r0

     fetch 20
;@LDI
opcode_ED_A0:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDA0
     
   do_handler_ED_A0_end1:
     mov r1,z80de, lsr #16
     DAM_WRITE8 OpEDA0
   do_handler_ED_A0_end2:
     add z80hl,z80hl,#1<<16
     add z80de,z80de,#1<<16
     bic z80f,z80f,#(1<<VFlag)|(1<<NFlag)|(1<<HFlag)
     subs z80bc,z80bc,#1<<16
     orrne z80f,z80f,#1<<VFlag
     fetch 16
;@CPI
opcode_ED_A1:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDA1
     subs r2,z80a,r0, lsl #24
     mrs lr,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,lr, lsr #28
     eor r0,z80a,r0, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#(1<<NFlag)|(1<<VFlag)
     add z80hl,z80hl,#1<<16
     subs z80bc,z80bc,#1<<16
     biceq z80f,z80f,#1<<VFlag
     fetch 16
;@INI
opcode_ED_A2:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpEDA2
     add z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     fetch 16
;@OUTI
opcode_ED_A3:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDA3
     add z80hl,z80hl,#1<<16
     mov r1,r0
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     fetch 16
;@LDD
opcode_ED_A8:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDA8
   do_handler_ED_A8_end1:
     mov r1,z80de, lsr #16
     DAM_WRITE8 OpEDA8
   do_handler_ED_A8_end2:
     sub z80hl,z80hl,#1<<16
     sub z80de,z80de,#1<<16
     bic z80f,z80f,#(1<<VFlag)|(1<<NFlag)|(1<<HFlag)
     subs z80bc,z80bc,#1<<16
     orrne z80f,z80f,#1<<VFlag
     fetch 16
;@CPD
opcode_ED_A9:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDA9
     subs r2,z80a,r0, lsl #24
     mrs lr,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,lr, lsr #28
     eor r0,z80a,r0, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#(1<<NFlag)|(1<<VFlag)
     sub z80hl,z80hl,#1<<16
     subs z80bc,z80bc,#1<<16
     biceq z80f,z80f,#1<<VFlag
     fetch 16
;@IND
opcode_ED_AA:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpEDAA
     sub z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     orreq z80f,z80f,#1<<ZFlag
     bicne z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     fetch 16
;@OUTD
opcode_ED_AB:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDAB
     mov r1,r0
     sub z80hl,z80hl,#1<<16
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     fetch 16

;@LDIR
;@(DE)=(HL), HL=HL+1, till BC=0
opcode_ED_B0:
     mov r0,z80hl, lsr #16
;@DAM_READ8 OpEDB0						;@ read8 from (HL)
;@ r0 = addr
stmdb sp!,{r3,r12}

;@str z80pc,[cpucontext,#z80pc_pointer]	;@ save pc for debug only

ldr r3,[cpucontext,#ppMemRead]			;@ r3 point to ppMemRead[0]
mov r2,r0,lsr#8						
ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemRead[addr >> 8]

cmp r3,#0
ldrneb r0,[r3,r0]
bne read8_end_OpEDB0
mov lr,pc								;@ call z80_read8(r0, r1)
ldr pc,[cpucontext,#z80_read8]
read8_end_OpEDB0:
ldmia sp!,{r3,r12}

     mov r1,z80de, lsr #16
;@DAM_WRITE8	OpEDB0						;@ write to (DE)
;@ r0 = data, r1 = addr
stmdb sp!,{r3,r12}
ldr r3,[cpucontext,#ppMemWrite]		;@ r3 point to ppMemWrite[0]
mov r2,r1,lsr#8						
ldr r3,[r3,r2,lsl#2]					;@ r3 = ppMemWrite[addr >> 8]

cmp r3,#0
strneb r0,[r3,r1]
bne write8_end_OpEDB0

mov r2,r1								;@ swp r1, r0
mov r1,r0
mov r0,r2

;@str z80_icount,[cpucontext,#nCyclesLeft]

mov lr,pc								;@ call z80_write8(r0, r1)
ldr pc,[cpucontext,#z80_write8]

write8_end_OpEDB0:
ldmia sp!,{r3,r12}

     bic z80f,z80f,#(1<<VFlag)|(1<<NFlag)|(1<<HFlag)
     add z80hl,z80hl,#1<<16
     add z80de,z80de,#1<<16
     subs z80bc,z80bc,#1<<16
     subne z80pc,z80pc,#2					;@ loop until BC=0
     fetch 21

;@CPIR
opcode_ED_B1:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDB1
     subs r2,z80a,r0, lsl #24
     mrs lr,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,lr, lsr #28
     eor r0,z80a,r0, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#(1<<NFlag)|(1<<VFlag)
     add z80hl,z80hl,#1<<16    
     subs z80bc,z80bc,#1<<16
     bne opcode_ED_B1_decpc
     bic z80f,z80f,#1<<VFlag
     fetch 21
opcode_ED_B1_decpc:
     tst z80f,#1<<ZFlag
     subeq z80pc,z80pc,#2
     fetch 21
;@INIR
opcode_ED_B2:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpEDB2
     add z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     subne z80pc,z80pc,#2
     fetch 16
;@OTIR
opcode_ED_B3:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDB3
     mov r1,r0
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     add z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     subne z80pc,z80pc,#2
     orreq z80f,z80f,#1<<ZFlag
     bicne z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     fetch 21
;@LDDR
opcode_ED_B8:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDB8
   do_handler_ED_B8_end1:
     mov r1,z80de, lsr #16
     DAM_WRITE8 OpEDB8
   do_handler_ED_B8_end2:
     bic z80f,z80f,#(1<<VFlag)|(1<<NFlag)|(1<<HFlag)
     sub z80hl,z80hl,#1<<16
     sub z80de,z80de,#1<<16
     subs z80bc,z80bc,#1<<16
     subne z80pc,z80pc,#2
     fetch 21

;@CPDR
opcode_ED_B9:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDB9
     subs r2,z80a,r0, lsl #24
     mrs lr,CPSR
     and z80f,z80f,#1<<CFlag
     eorcs z80f,z80f,#1<<CFlag
     eor z80f,z80f,lr, lsr #28
     eor r0,z80a,r0, lsl #24
     eor r0,r0,r2
     tst r0,#0x10<<24
     orrne z80f,z80f,#1<<HFlag
     orr z80f,z80f,#(1<<NFlag)|(1<<VFlag)
     sub z80hl,z80hl,#1<<16
     subs z80bc,z80bc,#1<<16
     bne opcode_ED_B9_decpc
     bic z80f,z80f,#1<<VFlag
     fetch 21
opcode_ED_B9_decpc:
     tst z80f,#1<<ZFlag
     subeq z80pc,z80pc,#2
     fetch 21
;@INDR
opcode_ED_BA:
     mov r0,z80bc, lsr #16
     ;@and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_in] ;@ r0=port - data returned in r0
     ldmia sp!,{r3,r12}
     mov r1,z80hl, lsr #16
     DAM_WRITE8 OpEDBA
     sub z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     subne z80pc,z80pc,#2
     fetch 16
;@OTDR
opcode_ED_BB:
     mov r0,z80hl, lsr #16
     DAM_READ8 OpEDBB
     mov r1,r0
     mov r0,z80bc, lsr #16
     and r0,r0,#0xFF
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#z80_out] ;@ r0=port r1=data
     ldmia sp!,{r3,r12}
     sub z80hl,z80hl,#1<<16
     sub z80bc,z80bc,#1<<24
     tst z80bc,#0xFF<<24
     bicne z80f,z80f,#1<<ZFlag
     orreq z80f,z80f,#1<<ZFlag
     orr z80f,z80f,#1<<NFlag
     subne z80pc,z80pc,#2
     fetch 21
;@##################################
;@##################################
;@###  opcodes FD  #########################
;@##################################
;@##################################
;@Since DD and FD opcodes are all the same apart from the address
;@register they use.  When a FD intruction the program runs the code
;@from the DD location but the address of the IY reg is passed instead
;@of IX

end_loop:
     ;@b end_loop
     
     
     ldrb r0,[z80pc,#1]

     ldrb r1,[z80pc]
     orr r0,r0,r1,lsl#8

     ldrb r1,[z80pc,#-1]
     orr r0,r0,r1,lsl#16

     ldrb r1,[z80pc,#-2]
     orr r1,r0,r1,lsl#24
     
     ldr r0,[cpucontext,#z80pc_base]
     sub r0,z80pc,r0
     
     stmdb sp!,{r3,r12}
     mov lr,pc
     ldr pc,[cpucontext,#debugCallback]
     ldmia sp!,{r3,r12}     
     
end_loop2:  
     b end_loop2
