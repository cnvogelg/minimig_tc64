SECTIONS
{
	. = 0x2000;
	.code : {
	  BUILD/startup.o (.text)
	  *(.text)
	  *(.rodata)
	  *(.rodata.*)
	  *(.data)
	}
	.extra : {
	  *(.bss)
	}
	.eh_frame : {
	  *(.eh_frame)
	}
	heap_low = .; /* for _sbrk */
	. = . + 0x1000; /* 64kB of heap memory */
	heap_top = .; /* for _sbrk */

	stack_top = 0x1000; /* for startup.s */
}