#define __LIBRARY__
#include <unistd.h>
#include <stdio.h>
#include <string.h>

_syscall2(int, CreateSharedMemory, int, key, int, size);
_syscall1(void *, ShareMemoryWith, int, shmid);

int main(int argc, char *argv[])
{
    char *base;
    int shmid;
    char *s;
    int i;

    if (argc < 2) {
        printf("usage: ./send string$\n");
        return -1;
    }

    shmid = CreateSharedMemory(1, 4096);
    base = (char *)ShareMemoryWith(shmid);

    for (i = 0; i < 4096; i++)
        base[i] = 0;

    s = argv[1];
    i = 0;
    while (s[i] != '$' && i < 4095) {
        if (s[i] == '#')
            base[i] = ' ';
        else
            base[i] = s[i];
        i++;
    }
    base[i] = '$';

    while (1)
        sleep(100);

    return 0;
}

