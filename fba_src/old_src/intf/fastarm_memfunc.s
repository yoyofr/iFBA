//
//  fastarm_memfunc.s
//  iFBA
//
//  Created by Yohann Magnien on 26/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

.fpu neon
.text
.align 4

.global _memcpy_neon
.global _memset_neon
.func   _memcpy_neon
_memcpy_neon: 
push            {r4-r11} 
fstmfdd sp!, {d8, d9, d10, d11, d12, d13, d14}
mov             r3, r0 
toto:      subs            r2, r2, #128 
pld             [r1, #64] 
pld             [r1, #256] 
pld             [r1, #320] 
ldm             r1!, {r4-r11} 
vld1.64         {d0-d3},   [r1,:128]! 
vld1.64         {d4-d7},   [r1,:128]! 
vld1.64         {d16-d19}, [r1,:128]! 
stm             r3!, {r4-r11} 
vst1.64         {d0-d3},   [r3,:128]! 
vst1.64         {d4-d7},   [r3,:128]! 
vst1.64         {d16-d19}, [r3,:128]! 
bgt             toto 
fldmfdd sp!, {d8, d9, d10, d11, d12, d13, d14}
pop             {r4-r11} 
bx              lr 
.endfunc
.func _memset_neon
_memset_neon: 
push            {r4-r11} 
mov             r3,  r0 
vdup.8          q0,  r1 
vmov            q1,  q0 
orr             r4,  r1, r1, lsl #8 
orr             r4,  r4, r4, lsl #16 
mov             r5,  r4 
mov             r6,  r4 
mov             r7,  r4 
mov             r8,  r4 
mov             r9,  r4 
mov             r10, r4 
mov             r11, r4 
add             r12, r3,  r2, lsr #2 
titi:      subs            r2,  r2, #128 
pld             [r3, #64] 
stm             r3!, {r4-r11} 
vst1.64         {d0-d3},   [r12,:128]! 
vst1.64         {d0-d3},   [r12,:128]! 
vst1.64         {d0-d3},   [r12,:128]! 
bgt             titi
pop             {r4-r11} 
bx              lr 
.endfunc
