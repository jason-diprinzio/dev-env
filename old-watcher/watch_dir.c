#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <glib.h>

#include "watcher.h"

/* Date formatter buffer length */
#define DF_BUFLEN 128
#define BUF_LEN 1024

#ifdef _IN_FLAGS
#define NOTIFY_FLAGS _IN_FLAGS
#else
#define NOTIFY_FLAGS IN_ALL_EVENTS
#endif

static volatile unsigned char RUN_FLAG = 0;
static void sig_handler(int sig)
{

#if _POSIX_C_SOURCE >= 1 || _XOPEN_SOURCE || _POSIX_SOURCE
    sigset_t mask_set;
    sigset_t old_set;
#endif  
    signal(sig, sig_handler);
#if _POSIX_C_SOURCE >= 1 || _XOPEN_SOURCE || _POSIX_SOURCE
    sigfillset(&mask_set);
    sigprocmask(SIG_SETMASK, &mask_set, &old_set);
#endif

    fprintf(stderr, "stopping....\n");
    RUN_FLAG = 0;
}

static inline void timestamp()
{
    struct tm *timedata; 
    struct timeval tv;
    gettimeofday(&tv, NULL);
    time_t now = tv.tv_sec;
    timedata = localtime(&now);
    char datebuf[128];
    strftime(datebuf, 128, "%F %T", timedata);
    fprintf(stdout, "\n[%s.%ld] ", datebuf, tv.tv_usec);
}

static inline void watch_event(const char *msg, const char *filename, const path_watcher_t *watcher, const struct inotify_event *event)
{
    timestamp();
    fprintf(stdout, "[wd=%d,mask=x%08x,cookie=%u,length=%d] ", event->wd, event->mask, event->cookie, event->len);
    fprintf(stdout, "path [%s] in watched path [%s] event [%s]", filename, watcher->watchpath, msg);
}

static inline int print_file(const char *filename, const path_watcher_t *watcher)
{
    char fullpath[2048];
    if(strcmp(watcher->watchpath, filename)) {
        sprintf(fullpath, "%s/%s", watcher->watchpath, filename);
    } else {
        sprintf(fullpath, "%s", filename);
    }

    FILE *file = fopen(fullpath, "r");
    if(NULL == file) return errno;

    char fbuf[BUF_LEN], fmt[32];
    int bytes = 0;

    /* TODO: add tail style option for outputting last N bytes. */
    fprintf(stdout, "\n==========BEGIN FILE CONTENTS==========\n");
    while( (bytes = fread(fbuf, sizeof(char), BUF_LEN, file)) != 0) {
        sprintf(fmt, "%%%d.%ds", bytes, bytes);
        fprintf(stdout, fmt, fbuf);
    }
    fprintf(stdout, "\n==========END FILE CONTENTS============\n");

    fclose(file);
    return 0;
}

static inline int format_timestamp(const time_t *timestamp, const unsigned long *usec, const int buflen, char *buf)
{
    struct tm *timedata; 
    timedata = localtime(timestamp);
    char datebuf[64];
    strftime(datebuf, 64, "%F %T", timedata);
    snprintf(buf, buflen, "%s.%lu", datebuf, *usec);
    return 0;
}

static inline int stat_file(const char *filename, const path_watcher_t *watcher)
{
    char fullpath[2048];
    if(strcmp(watcher->watchpath, filename)) {
        sprintf(fullpath, "%s/%s", watcher->watchpath, filename);
    } else {
        sprintf(fullpath, "%s", filename);
    }

    struct stat statbuf;
    if(stat(fullpath, &statbuf)) {
        perror("cannot stat file");
        return 1;
    }

    char *type = NULL;
    if(S_ISREG(statbuf.st_mode) )         type = (char*)"regular file"; 
    else if(S_ISDIR(statbuf.st_mode) )    type = (char*)"directory"; 
    else if(S_ISCHR(statbuf.st_mode) )    type = (char*)"character device"; 
    else if(S_ISBLK(statbuf.st_mode) )    type = (char*)"block device"; 
    else if(S_ISFIFO(statbuf.st_mode))    type = (char*)"pipe"; 
    else if(S_ISLNK(statbuf.st_mode) )    type = (char*)"symbolic link"; 
    //else if(S_ISSOCK(statbuf.st_mode))    type = "socket"; 

    int sbit    = (statbuf.st_mode >> 9)& 0x00000007;
    int omode   = (statbuf.st_mode >> 6)& 0x00000007;
    int gmode   = (statbuf.st_mode >> 3)& 0x00000007;
    int othmode = (statbuf.st_mode >> 0)& 0x00000007;
    
    char atime[DF_BUFLEN], mtime[DF_BUFLEN], ctime[DF_BUFLEN];
    format_timestamp(&statbuf.st_atime, &statbuf.st_atimensec, DF_BUFLEN, atime);
    format_timestamp(&statbuf.st_mtime, &statbuf.st_mtimensec, DF_BUFLEN, mtime);
    format_timestamp(&statbuf.st_ctime, &statbuf.st_ctimensec, DF_BUFLEN, ctime);

    fprintf(stdout, "\n==========BEGIN METADATA==========\n");
    fprintf(stdout, "  File: '%s'\n  Size: %ld       Blocks: %ld       Inode: %ld       %s\n",
        filename, statbuf.st_size, statbuf.st_blocks, statbuf.st_ino, type);
    fprintf(stdout, "  Mode: %x%x%x%x     Uid: %u       Gid: %u\n", 
        sbit,omode, gmode, othmode, statbuf.st_uid, statbuf.st_gid);
    fprintf(stdout, "Access: %s\nModify: %s\nChange: %s\n",
        atime, mtime, ctime);
    fprintf(stdout, "==========END METADATA============\n");
    return 0;
}

void handle_event(const char *filename, const struct inotify_event *event, const path_watcher_t *pw, const void *data)
{
    switch(event->mask & 0x00FFFFFF) {
        /* General events for directories and files. */
        case IN_ACCESS :
            watch_event("accessed", filename, pw, event);
            break;
        case IN_ATTRIB :
            watch_event("metadata modified", filename, pw, event);
            stat_file(filename, pw);
            break;
        case IN_OPEN :
            watch_event("opened", filename, pw, event);
            break;
        case IN_CLOSE_WRITE :
            watch_event("closed for write", filename, pw, event);
            break;
        case IN_CLOSE_NOWRITE :
            watch_event("close for read", filename, pw, event);
            break;
        case IN_CREATE :
            watch_event("created", filename, pw, event);
        case IN_DELETE :
            watch_event("removed", filename, pw, event);
            break;
        case IN_MOVED_FROM:
        case IN_MOVED_TO:
        case IN_MOVE :
            watch_event("moved", filename, pw, event);
            break;
            /* We're not fast enough. */
        case IN_Q_OVERFLOW :
            fprintf(stderr, "event queue overflow");
            break;
            /* Print the file contents since they changed. */
        case IN_MODIFY :
            watch_event("modified", filename, pw, event);
            if(IS_DIR_EVENT(event->mask)  ) {
                if(print_file(filename, pw)) {
                    fprintf(stderr, "cannot access %s...\n", filename);
                }
            }
            break;
    }
}

int main(int argc, const char **argv)
{
    signal(SIGINT, &sig_handler);
    const char *pwd[] = { "." };
    const char **paths = pwd;
    int numpaths = argc;

    if(argc > 1) {
        paths = &argv[1];
        numpaths = argc-1;
    }

#ifdef _DIR
    watch_args_t wargs = { numpaths, WATCH_OPT_RECURSE|WATCH_OPT_REQUIRE_DIR,
        NOTIFY_FLAGS, (char**)paths, handle_event, NULL, &RUN_FLAG };
#else
    watch_args_t wargs = { numpaths, WATCH_OPT_NONE,
        NOTIFY_FLAGS, (char**)paths, handle_event, NULL, &RUN_FLAG };
#endif
    return watch(&wargs);
}

