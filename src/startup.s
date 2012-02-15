	move.l #stack_top,%a7
	
	/* clear bss */
    lea.l   __s_bss,%a0    
    move.l  #__e_bss,%d0
1:  cmp.l   %d0,%a0
    beq.s   2f
    clr.b   (%a0)+
    bra.s   1b
2:	
	jmp c_entry
