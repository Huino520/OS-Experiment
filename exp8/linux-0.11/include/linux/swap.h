#ifndef _LINUX_SWAP_H
#define _LINUX_SWAP_H

#include <linux/mm.h>

#define SWAP_DEV     0x305
#define PAGE_SIZE    4096
#define SWAP_SIZE    8192

#define FREE_PAGES_LOW    10
#define FREE_PAGES_HIGH   30
#define CLOCK_SCAN_SPEED  5

#define PAGE_PRESENT   0x01
#define PAGE_RW        0x02
#define PAGE_USER      0x04
#define PAGE_ACCESSED  0x20
#define PAGE_DIRTY     0x40
#define PAGE_SWAPPED   0x80

#define SWAP_BLOCK(entry) ((entry) >> 12)
#define MAKE_SWAP_ENTRY(block) ((block << 12) | PAGE_SWAPPED | PAGE_USER | PAGE_RW)

struct swap_entry {
    unsigned char used;
};

extern struct swap_entry swap_table[];
extern int next_swap_block;

extern unsigned long *clock_hand1;
extern unsigned long *clock_hand2;
extern int clock_scan_cycles;
extern int swap_out_count;

void swap_init(void);
int swap_alloc_block(void);
void swap_free_block(int);
void swap_out_page(unsigned long, int);
void swap_in_page(unsigned long, int);
void clock_scan(void);
int sys_swapinfo(void);

#endif

