// minimal newlib syscalls implementation

#include <sys/stat.h>

int _close_r(int file) { return -1; }
	 
int _fstat_r(int file, struct stat *st) {
	st->st_mode = S_IFCHR;
	return 0;
}
	 
int _isatty_r(int file) { return 1; }
	 
int _lseek_r(int file, int ptr, int dir) { return 0; }
	 
int _open_r(const char *name, int flags, int mode) { return -1; }
	 
int _read_r(int file, char *ptr, int len) { return -1; }
	 
char *heap_end = 0;
caddr_t _sbrk_r(int incr) {
	extern char heap_low; /* Defined by the linker */
	extern char heap_top; /* Defined by the linker */
	char *prev_heap_end;
	 
	if (heap_end == 0) {
		heap_end = &heap_low;
	}
	prev_heap_end = heap_end;
	 
	if (heap_end + incr > &heap_top) {
	  /* Heap and stack collision */
		return (caddr_t)0;
	}
	 
	heap_end += incr;
	return (caddr_t) prev_heap_end;
}

#define TX ((volatile char *)0xda8001)

int _write_r(int file, char *ptr, int len) {
#if 0
	int i;
	for(i=0;i<len;i++) {
		*TX = ptr[i];
	}
#endif
	return len;
}

unsigned long SwapBBBB(unsigned long i)
{
	asm volatile
	(
		"rol.w #8,%0\n\t"
		"swap %0\n\t"
		"rol.w #8,%0\n\t"
	: "=r" (i) /* out */
	: "r" (i) 
	: /* no clobber */
	);	
	return i;
}

unsigned int SwapBB(unsigned int i)
{
	asm volatile
	(
		"rol.w #8,%0\n\t"
	: "=r" (i) /* out */
	: "r" (i) 
	: /* no clobber */
	);	
	return i;
}

unsigned long SwapWW(unsigned long i)
{
	asm volatile
	(
		"swap %0\n\t"
	: "=r" (i) /* out */
	: "r" (i) 
	: /* no clobber */
	);	
	return i;
}
