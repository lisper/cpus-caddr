STACK=0x14000

	.global _start
	.global main
_start:
	br	start2
	br	exception
	br	break
	
start2:	
	movhi	sp,%hi(STACK)
	addi	sp,sp,%lo(STACK)

	movhi	gp, %hi(_gp)
	ori	gp, gp, %lo(_gp)
	
	call	main
	
	movhi	r0,0
	jmp	r0

exception:
	br	exception
break:
	br	break
