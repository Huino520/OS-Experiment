#include <linux/swap.h>
#include <linux/sched.h>
#include <linux/kernel.h>
#include <linux/mm.h>

static int next_swap_block = 0;
static int clock_scan_cycles = 0;
static int swap_out_count = 0;

unsigned long get_page_entry(unsigned long address)
{
	unsigned long *page_table;

	page_table = (unsigned long *) ((address>>20) & 0xffc);
	if ((*page_table)&1) {
		page_table = (unsigned long *) (0xfffff000 & *page_table);
		return page_table[(address>>12) & 0x3ff];
	}
	return 0;
}

void set_page_entry(unsigned long address, unsigned long entry)
{
	unsigned long *page_table;

	page_table = (unsigned long *) ((address>>20) & 0xffc);
	if ((*page_table)&1) {
		page_table = (unsigned long *) (0xfffff000 & *page_table);
		page_table[(address>>12) & 0x3ff] = entry;
	}
}

void swap_init(void)
{
	static struct swap_entry swap_table[SWAP_SIZE];
	int i;
	for (i = 0; i < SWAP_SIZE; i++)
		swap_table[i].used = 0;
}

int swap_alloc_block(void)
{
	static struct swap_entry swap_table[SWAP_SIZE];
	int start = next_swap_block;
	while (1) {
		if (!swap_table[next_swap_block].used) {
			swap_table[next_swap_block].used = 1;
			return next_swap_block;
		}
		next_swap_block = (next_swap_block + 1) % SWAP_SIZE;
		if (next_swap_block == start)
			return -1;
	}
}

void swap_free_block(int block)
{
	static struct swap_entry swap_table[SWAP_SIZE];
	if (block < 0 || block >= SWAP_SIZE) return;
	swap_table[block].used = 0;
}

void swap_out_page(unsigned long addr, int swap_block)
{
	struct buffer_head *bh;
	int sector = swap_block * 8;
	char *from = (char *)addr;
	int i, j;

	for (i = 0; i < 8; i++) {
		bh = getblk(SWAP_DEV, sector + i);
		for (j = 0; j < 512; j++)
			bh->b_data[j] = from[i*512 + j];
		ll_rw_block(WRITE, bh);
		brelse(bh);
	}
}

void swap_in_page(unsigned long addr, int swap_block)
{
	struct buffer_head *bh;
	int sector = swap_block * 8;
	char *to = (char *)addr;
	int i, j;

	for (i = 0; i < 8; i++) {
		bh = bread(SWAP_DEV, sector + i);
		for (j = 0; j < 512; j++)
			to[i*512 + j] = bh->b_data[j];
		brelse(bh);
	}
}

void clock_scan(void)
{
	static int count = 0;
	if (++count < 80) return;
	count = 0;

	if (current->pid == 0 || current->pid == 1 || current->pid == 2)
        	return;
	clock_scan_cycles++;

	unsigned long addr;
	unsigned long start = current->start_code;
	unsigned long end = start + 0x1000000;

	for (addr = start; addr < end; addr += 4096) {
		unsigned long entry = get_page_entry(addr);

		if (!entry) continue;
		if (!(entry & 1)) continue;
		if (!(entry & 4)) continue;
		if (entry & 0x80) continue;

		if (entry & 0x20) {
			set_page_entry(addr, entry & ~0x20);
			continue;
		}

		int blk = swap_alloc_block();
		if (blk < 0) break;

		unsigned long page = entry & 0xFFFFF000;
		swap_out_page(page, blk);

		set_page_entry(addr, (blk << 12) | 0x80 | 4);
		free_page(page);
		swap_out_count++;

		printk("Swap out: 0x%lx -> blk %d\n", addr, blk);
		break;
	}
}

int sys_swapinfo(void)
{
	printk("clock=%d swapout=%d\n", clock_scan_cycles, swap_out_count);
	return 0;
}

