#include <stdio.h>
#include <sys/inotify.h>
#include <unistd.h>
#include <errno.h>

#define EVENT_SIZE  (sizeof (struct inotify_event)) 
#define BUF_LEN   (1024 * (EVENT_SIZE + 16))

int main(int argc, char ** argv)
{

    int watcher = inotify_init();

    if( watcher < 0 ) {
        perror("Failed to initialize inotify.");
        return 1;
    }

    inotify_add_watch(watcher, ".", IN_CLOSE_WRITE);

    char buf[BUF_LEN];

    while(1) {
        int len, i = 0;
        len = read (watcher, buf, BUF_LEN);
        if (len < 0) {
            if (errno == EINTR) {
                fprintf(stderr, "Interrupted\n");
                continue;
            } else {
                perror ("read error");
                return 2;
            }
        } else if (!len) {
            fprintf(stderr, "No data from read\n");
            continue;
        }

        while (i < len) {
            struct inotify_event *event;

            event = (struct inotify_event *) &buf[i];

            printf ("wd=%d mask=%u cookie=%u len=%u\n",
                    event->wd, event->mask,
                    event->cookie, event->len);

            if (event->len)
                printf ("name=%s\n", event->name);

            FILE *file = fopen(event->name, "r");
            if(NULL == file) goto BBreak;

            char fbuf[BUF_LEN], fmt[32];
            int bytes = 0;

            while( (bytes = fread(fbuf, sizeof(char), BUF_LEN, file)) != 0) {
                sprintf(fmt, "%%%d.%ds\n", bytes, bytes);
                fprintf(stdout, fmt, fbuf);
            }
            fclose(file);
BBreak:
            i += EVENT_SIZE + event->len;
        }
    } 
    close(watcher);
    return 0;
}

