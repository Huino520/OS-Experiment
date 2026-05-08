#include <linux/kernel.h>
#include <asm/segment.h> 
#include <errno.h>

char myname[21] = {0};

int sys_iam(const char *name) {
    int i = 0, j = 0;
    char ch;  
    
    for (j = 0; j < 21; j++) {
        myname[j] = '\0';
    }

    while (i < 20) {
        ch = get_fs_byte(name + i);
        if (ch == '\0') {
            break;
        }
        myname[i] = ch;
        i++;
    }

    if (i == 20 && get_fs_byte(name + 20) != '\0') {
        return -EINVAL;
    }

    myname[i] = '\0';
    return i;
}

int sys_whoami(char *name, unsigned int size) {
    int len = 0, i = 0;

    while (myname[len] != '\0') {
        len++;
    }

    if (size <= len) {
        return -EINVAL;
    }

    for (i = 0; i <= len; i++) {
        put_fs_byte(myname[i], name + i);
    }

    return len;
}

