#include <linux/sched.h>
#include <linux/sem.h>
#include <linux/kernel.h>
#include <asm/segment.h>
#include <string.h>
#include <asm/system.h>

struct semaphore SemaphoreSet[NR_SEMS];

void sem_init(void) {
    int i;
    for (i = 0; i < NR_SEMS; i++) {
        SemaphoreSet[i].s_lock = 0;
        SemaphoreSet[i].s_used = 0;
        SemaphoreSet[i].s_value = 0;
        SemaphoreSet[i].s_wait = NULL;
        memset(SemaphoreSet[i].s_name, 0, SEM_NAME_LEN);
    }
    printk("[%08ld] Semaphore initialized.\n", jiffies);
}

int sys_CreateSemaphore(char *semname) {
    int i;
    char name[SEM_NAME_LEN];

    for (i = 0; i < SEM_NAME_LEN - 1; i++) {
        name[i] = get_fs_byte(semname + i);
        if (name[i] == '\0') break;
    }
    name[i] = '\0';

    for (i = 0; i < NR_SEMS; i++) {
        if (SemaphoreSet[i].s_used && !strcmp(SemaphoreSet[i].s_name, name))
            return i;
    }

    for (i = 0; i < NR_SEMS; i++) {
        if (!SemaphoreSet[i].s_used) {
            SemaphoreSet[i].s_used = 1;
            strcpy(SemaphoreSet[i].s_name, name);
            SemaphoreSet[i].s_value = 0;
            SemaphoreSet[i].s_wait = NULL;
            return i;
        }
    }
    return -1;
}

int sys_SetSemaphore(int semid, int value) {
    if (semid <0 || semid >= NR_SEMS || !SemaphoreSet[semid].s_used)
        return -1;

    cli();
    SemaphoreSet[semid].s_value = value;
    sti();
    return value;
}

int sys_WaitSemaphore(int semid) {
    struct semaphore *sem;

    if (semid <0 || semid >= NR_SEMS || !SemaphoreSet[semid].s_used)
        return -1;

    sem = &SemaphoreSet[semid];
    cli();

    sem->s_value--;
    fprintk(3, "[%08ld] [P] Process %d get sem: %s\n", jiffies, current->pid, sem->s_name);

    if (sem->s_value < 0) {
        fprintk(3, "[%08ld] [P] Process %d sleep on sem: %s\n", jiffies, current->pid, sem->s_name);
        sleep_on(&sem->s_wait);
    }

    sti();
    return 0;
}

int sys_SignalSemaphore(int semid) {
    struct semaphore *sem;

    if (semid <0 || semid >= NR_SEMS || !SemaphoreSet[semid].s_used)
        return -1;

    sem = &SemaphoreSet[semid];
    cli();

    sem->s_value++;
    fprintk(3, "[%08ld] [V] Process %d release sem: %s\n", jiffies, current->pid, sem->s_name);

    if (sem->s_value <= 0) {
        fprintk(3, "[%08ld] [V] Process %d wakeup on sem: %s\n", jiffies, current->pid, sem->s_name);
        wake_up(&sem->s_wait);
    }

    sti();
    return 0;
}
