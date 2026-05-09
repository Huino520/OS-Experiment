#include <linux/fs.h>
#include <linux/sched.h>
#include <stdarg.h>
#include <asm/segment.h>
#include <linux/kernel.h>

struct task_struct *t;
int i,j,x;

int sprintf(char *buf, const char fmt[], ...)
{
    va_list args;
    int i;
    va_start(args, fmt);
    i = vsprintf(buf, fmt, args);
    va_end(args);
    return i;
}

int psinfo_proc_read(char * buf,int count,off_t * f_pos)
{
    char psbuf[2048];
    char *state_str;

    j = sprintf(psbuf,"Processes List:\n");
    j += sprintf(psbuf+j,"pid\texec state\tuid\tfather-id\tstart_time\n");

    for(i=0;i<64;i++)
    {
        t = task[i];
        if(t && t->pid != -1)
        {
            switch(t->state) {
                case 0: state_str = "Running "; break;
                case 1: state_str = "Sleeping"; break;
                case 2: state_str = "Waiting "; break;
                case 3: state_str = "Stopped "; break;
                case 4: state_str = "Zombie  "; break;
                default:state_str = "Unknown "; break;
            }

            j += sprintf(psbuf+j,"%d\t%s\t%d\t%d\t\t%ld\n",
                t->pid,
                state_str,
                t->uid,
                t->father,
                t->start_time);
        }
    }

    j += sprintf(psbuf+j,"\n");

    for(i=0;i<64;i++)
    {
        t = task[i];
        if(t && t->pid != -1)
        {
            j += sprintf(psbuf+j,"Detail of Process ID=%d\n", t->pid);
            j += sprintf(psbuf+j,"Open Files:\n");

            for(x=0;x<NR_OPEN;x++)
            {
                if(t->filp[x])
                {
                    j += sprintf(psbuf+j,"FD(%d): 0x%08x\n",x,(unsigned int)t->filp[x]);
                }
            }
            j += sprintf(psbuf+j,"\n");
        }
    }

    int len = j - *f_pos;
    if (len <= 0) return 0;
    if (len > count) len = count;

    for(x=0;x<len;x++)
        put_fs_byte(psbuf[*f_pos+x], buf+x);

    *f_pos += len;
    return len;
}

proc_ptr proc_table[] = {
    NULL,NULL,NULL,psinfo_proc_read,NULL
};

int proc_read(int dev, char * buf, int count, off_t * pos)
{
    proc_ptr call = proc_table[MINOR(dev)];
    if(!call) return -1;
    return call(buf,count,pos);
}

