#ifndef _MM_H
#define _MM_H

#define PAGE_SIZE 4096
#include <linux/swap.h>

extern unsigned long get_free_page(void);
extern unsigned long put_page(unsigned long page,unsigned long address);
extern void free_page(unsigned long addr);

#endif
