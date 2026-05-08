#define __LIBRARY__
#include <unistd.h>
#include <stdio.h>

_syscall2(int, CreateSharedMemory, int, key, int, size);
_syscall1(void *, ShareMemoryWith, int, shmid);

int main()
{
    char *base;
    int shmid;
    int i;

    printf("------------------The Server Processor is Startup---------------\n");
    printf("The server processor’s id=%d\n", getpid());

    shmid = CreateSharedMemory(1, 4096);
    base = (char *)ShareMemoryWith(shmid);

    while (1) {
        printf("The server will sleep 1 minute\n");
        sleep(60);

        i = 0;
        while (base[i] != '$' && i < 4095) {
            putchar(base[i]);
            i++;
        }
        putchar('\n');
        fflush(stdout);
    }

    return 0;
}

