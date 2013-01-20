.global alphaBlend_neon

fg	.req 	r0 	@ rename registers (readability)
bg	.req	r1
dest	.req	r2
y	.req 	r3
x      .req   r4
count  .req   r5

.align 4	
	
.equ 	iter, 65536	@ loop iterations constant
.equ 	iter_div_4, 128 @ loop iterations / 4 constant	
	
.arch armv7-a		@ architecture settings
.fpu  neon
	
alphaBlend_neon:
	stmdb r13!, {r4-r11}			@ save arm registers
	
	@ initialize loop counter
	mov count, #iter
	
	vmov.i32 q5, #0x00ff0000		@ q5 = {0x00ff0000,0x00ff0000,0x00ff0000,0x00ff0000}
	vmov.i32 q8, #0x0000ff00		@ q8 = {0x0000ff00,0x0000ff00,0x0000ff00,0x0000ff00}
	vmov.i32 q9, #0x000000ff		@ q9 = {0x000000ff,0x000000ff,0x000000ff,0x000000ff}
	vmov.i32 q10,#0xff000000		@ q10 = {0xff000000,0xff000000,0xff000000,0xff000000}
	@vmov2 or vdup
	
	
	@ load four entries from fgImage		
	vld1.32 {q0}, [fg]! 			@ q0 = {fgImage[i]-fgImage[i+3]}
	@vld4.8 {d0,d1,d2,d3} , [fg]!	@
	@add bg, bg, #4
	@vld3.8 {d4,d5,d6} , [bg+1]!	@ try to skip upper 8-bit of bg since notneeded
	@vmul.u8 d1,d0,d1
	@vmul.u8 d2,d0,d2
	@vmul.u8 d3,d0,d3
	@vneg d0  or xor with itself??s
	@ 		vmull.u16 q6,d0,d1 
	@       vmull.u16 q7,~d0,d4
	@		vadd.u16 q6,q6,q7
	@		vrev16   q6				//swap making lower half now most significant
	@		vmovn.u8 d0, q6			//replace right shift by 8, select lower half
	@vmul.u8 d4,d0,d4
	@vmul.u8 d5,d0,d5
	@vmul.u8 d6,d0,d6
	@ vmula on last mutliply to combine with add i.e. vmula.u8 d1, d0,d4  or vfma
	@vadd.u8 d1,d1,d4
	@vadd.u8 d2,d2,d5
	@vadd.u8 d3,d3,d6
	@vshr d1,8
	@vshr d2,8
	@vshr d3,8
	@	vzip??
	@ 
	@vst3.8 {d0,d1,d2,d3}, [dest}!	@d0 = 0xff
	
	
	
	@ vmull.u16 q4,d0,d1
	@ vmull.u16 q5, d0,d2
	@ vmull.u16 q6, d0,d3
	@ vneg d0,d0
	@ vumll.u16 q7, d0,d4
	@ vmull.u16 q8, d0,d5
	@ vmull.u16 q9, d0,d6
	@ vadd.u16 q4,q7
	
		
 
	@ load four entries from bgImage				
	vld1.32 {q1} , [bg]!			@ q1 = {bgImage[i]-bgImage[i+3]}
	
.L_mainloop:		
	
	pld [fg, #16]
	pld [bg, #16]

	@ a_fg = A(fgImage[fg_index]);
	vand.i32 q2,q0,q10			@ q2 = q0 & 0xff000000 (UNNEEDED)
	vshr.u32 q2,q2,#24 			@ q2 = q2 >> 24
	
	
	@ 255-a_fg
	vmov.i32 q4, #255			@ q4 = {255,255,255,255}						
	vsub.u32 q4, q4, q2 			@ q4 = q4 - q2
	

	@
	@  dst_r	
	@
	
	@ R(fgImage[index])*a_fg
	vand q6, q0, q5			@ q6 = q0 & q5
	vshr.u32 q6, #16			@ q6 = q6 >>16	
	vmul.u32  q6, q6, q2			@ q6 = q6 * q2

	@ R(bgImage[index])*(255-a_fg)
	vand  q7, q1, q5			@ q7 = q1 & q5
	vshr.u32 q7, #16			@ q7 = q7 >>16	
	vmul.u32 q7, q7, q4			@ q7 = q7 * q4
	
	

	@ dst_r = ((R(fgImage[index]) * a_fg) + (R(bgImage[index]) * (255-a_fg)))/256;
	vadd.u32 q6, q6, q7			@ q6 = q6 + q7
	vshr.u32 q6, #8			@ q6 = q6 >> 8 (q6/256)

	@
	@  dst_g	
	@
	
	@ G(fgImage[index])*a_fg
	vand q11, q0, q8			@ q11 = q0 & q8
	vshr.u32 q11, #8			@ q11 = q11 >> 8	
	vmul.u32  q11, q11, q2		@ q11 = q11 * q2

	@ G(bgImage[index])*(255-a_fg)
	vand q12, q1, q8			@ q12 = q1 & q8
	vshr.u32 q12, #8			@ q12 = q6 >> 8	
	vmul.u32 q12, q12, q4		@ q12 = q12 * q4

	@ dst_g = ((G(fgImage[index]) * a_fg) + (G(bgImage[index]) * (255-a_fg)))/256;
	vadd.u32 q11, q11, q12		@ q11 = q11 + q12
	vshr.u32 q11, #8			@ q11 = q11 >> 8  = (q11/256)


	@
	@  dst_b	
	@
	
	@ B(fgImage[index])*a_fg
	vand q7, q0, q9			@ q7 = q0 & q9
	vmul.u32  q7, q7, q2			@ q11 = q11 * q2

	@ B(bgImage[index])*(255-a_fg)
	vand q12, q1, q9			@ q12 = q1 & q9	
	vmul.u32 q12, q12, q4		@ q12 = q12 * q4


	@ dst_b = ((B(fgImage[index]) * a_fg) + (B(bgImage[index]) * (255-a_fg)))/256;
	vadd.u32 q12, q12, q7		@ q12 = q12 + q7
	vshr.u32 q12, #8			@ q12 = q12 >> 8  = (q12/256)


	@ 0xff000000 |(0x00ff0000 & (dst_r << 16)) |(0x0000ff00 & (dst_g << 8)) | (0x000000ff & (dst_b));
	vshl.u32 q11, #8
	vshl.u32 q6, #16
	vand q12, q12, q9
	vand q11, q11, q8
	vorr q12, q12, q11
	vand q6,q6,q5
	vorr q12,q12,q6
	vorr q12,q12,q10


	@ store result
	vst1.32 {q12}, [r2]!


	@ update outer loop counter and check if done
	subs count,count,#1	
	
	@ load four entries from fgImage		
	vld1.32 {q0}, [fg]! 			@ q0 = {fgImage[i]-fgImage[i+3]}
 
	@ load four entries from bgImage				
	vld1.32 {q1} , [bg]!		@ q1 = {bgImage[i]-bgImage[i+3]}	


	bgt .L_mainloop		

.L_return:
	ldmia sp!, {r4-r11}	@ restore registers
	mov pc, lr
	
message:
    .asciz  "Register Val: %d\n"

