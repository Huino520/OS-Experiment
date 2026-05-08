#include <linux/kernel.h>

int sys_whoami() {
    printk("Hu Jinbo\n");
    return 0;
}

