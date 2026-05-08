#define __LIBRARY__
#include <unistd.h>
#include <linux/sched.h>
#include <linux/kernel.h>
#include <asm/segment.h>
#include <asm/system.h>
#include <signal.h>

int table[40]={0};

int sys_CreateSharedMemory(int key,int size){
    int res;

    if(table[key]!=0)
        return table[key];
    if(size>4096)
        return -1;
    res=get_free_page();
    if(!res)
        return -1;
    table[key]=res;
    return res;
}

void *sys_ShareMemoryWith(int shmid){
    if(!shmid)
        return -1;
    put_page(shmid,current->start_code+current->brk);
    return current->brk;
}

