#ifndef _SEM_H
#define _SEM_H

#define NR_SEMS 30
#define SEM_NAME_LEN 20

struct semaphore {
    int s_lock;
    char s_name[SEM_NAME_LEN];
    int s_used;
    int s_value;
    struct task_struct *s_wait;
};

extern struct semaphore SemaphoreSet[NR_SEMS];

void sem_init(void);

int sys_CreateSemaphore(char *semname);
int sys_SetSemaphore(int semid, int value);
int sys_WaitSemaphore(int semid);
int sys_SignalSemaphore(int semid);

#endif
