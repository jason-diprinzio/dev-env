#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define EVENT_SIZE  (sizeof (struct inotify_event))
#define BUF_LEN   (1024 * (EVENT_SIZE + 16))

#ifdef _IN_FLAGS
#define NOTIFY_FLAGS _IN_FLAGS
#else
#define NOTIFY_FLAGS IN_ALL_EVENTS
#endif

#define IS_DIR_EVENT(mask)\
    (((mask >> 24) & 0xf0) != IN_ISDIR)

typedef struct _path_watcher {
    int wd;
    char *watchpath;
} path_watcher;

inline void remove_watch(const char *msg, const struct inotify_event *event, const int watcher, path_watcher *watches)
{
    fprintf(stderr, "%s - removing notifications for file %s\n", msg, watches[event->wd].watchpath); \
    inotify_rm_watch(watcher, watches[event->wd].wd); \
    watches[event->wd].wd = 0; 
}

inline void timestamp()
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

inline void watch_event(const char *msg, const char *filename, const path_watcher *watches, const struct inotify_event *event)
{
    timestamp();
    fprintf(stdout, "[filename=%s,wd=%d,mask=x%08x,cookie=%u] ", filename, event->wd, event->mask, event->cookie);
    fprintf(stdout, "file [%s] in watched path [%s] event [%s]", filename, watches[event->wd].watchpath, msg);
}

inline int print_file(const char *filename)
{
    FILE *file = fopen(filename, "r");
    if(NULL == file) return errno;

    char fbuf[BUF_LEN], fmt[32];
    int bytes = 0;

    fprintf(stdout, "\n==========BEGIN FILE CONTENTS==========\n");
    while( (bytes = fread(fbuf, sizeof(char), BUF_LEN, file)) != 0) {
        sprintf(fmt, "%%%d.%ds", bytes, bytes);
        fprintf(stdout, fmt, fbuf);
    }
    fprintf(stdout, "\n==========END FILE CONTENTS============\n");

    fclose(file);
    return 0;
}

inline int stat_file(const char *filename)
{
    struct stat statbuf;
    if(stat(filename, &statbuf)) {
        perror("cannot stat file");
        return 1;
    }

    char *type = NULL;
    if(S_ISREG(statbuf.st_mode) )    type = "regular file"; 
    else if(S_ISDIR(statbuf.st_mode) )    type = "directory"; 
    else if(S_ISCHR(statbuf.st_mode) )    type = "character device"; 
    else if(S_ISBLK(statbuf.st_mode) )    type = "block device"; 
    else if(S_ISFIFO(statbuf.st_mode))    type = "pipe"; 
    else if(S_ISLNK(statbuf.st_mode) )    type = "symbolic link"; 
    //else if(S_ISSOCK(statbuf.st_mode))    type = "socket"; 

    int sbit    = (statbuf.st_mode >> 9)& 0x00000007;
    int omode   = (statbuf.st_mode >> 6)& 0x00000007;
    int gmode   = (statbuf.st_mode >> 3)& 0x00000007;
    int othmode = (statbuf.st_mode >> 0)& 0x00000007;
    
    fprintf(stdout, "\nsize: %ld, blocks: %ld, inode: %ld, type: %s\nmode: %x%x%x%x uid: %u, gid: %u\nAccess: %ld\nModify: %ld\nChange: %ld\n",
        statbuf.st_size, statbuf.st_blocks,
        statbuf.st_ino, type, sbit,omode, gmode, othmode,
        statbuf.st_uid, statbuf.st_gid,
        statbuf.st_atimensec, statbuf.st_mtimensec, statbuf.st_ctimensec);
    return 0;
}

#ifdef _DIR
inline int is_dir(const char *path)
{
    struct stat check_buf;
    if(stat(path, &check_buf)){
        perror("error stat");
        return 0;
    }
    if(!S_ISDIR(check_buf.st_mode)) {
        fprintf(stderr, "%s is not a directory\n", path);
        return 0;
    }
    return 1;
}
#define IS_DIR(path) is_dir(path)
#else
#define IS_DIR(path) 1
#endif

inline int check_path(const char *path)
{
    int eval = 0;
    if((eval = access(path, R_OK))) {
        perror("cannot watch file");
        return eval;
    }

    return !IS_DIR(path);
}

int still_watching(const path_watcher *watches, const int count)
{
    for(int i=0; i<count; i++) {
        if(watches[i].wd) return 1;
    }
    return 0;
}

int main(const int argc, const char ** argv)
{

    int watcher = inotify_init();

    if(watcher < 0) {
        perror("Failed to initialize inotify");
        return 1;
    }

    path_watcher watches[argc+1];
    memset(watches, 0, sizeof(path_watcher));

    if(1 < argc) {
        for(int i=1; i<argc; i++){
            check_path(argv[i]);
            int watch_index = inotify_add_watch(watcher, argv[i], NOTIFY_FLAGS);
            if(watch_index > 0) {
                watches[watch_index].wd = watch_index;
                watches[watch_index].watchpath = (char*)argv[i];
            }
        }
    } else {
        int watch_index = inotify_add_watch(watcher, ".", NOTIFY_FLAGS);
        watches[1].wd = watch_index;
        watches[1].watchpath = ".";
    }

    char buf[BUF_LEN];

    while(still_watching(watches, argc+1)) {
        int len, i = 0;
        len = read(watcher, buf, BUF_LEN);
        if(len < 0) {
            if(errno == EINTR) {
                continue;
            }else {
                perror("read error");
                close(watcher);
                return 2;
            }
        } else if(!len) {
            fprintf(stderr, "no data from read\n");
            continue;
        }

        while(i<len) {
            struct inotify_event *event;

            event = (struct inotify_event *) &buf[i];

            char filename[1024];
            if(event->len > 0) {
                sprintf(filename, "%s/%s", watches[event->wd].watchpath, event->name);
            } else {
                sprintf(filename, "%s", watches[event->wd].watchpath);
            }
            switch(event->mask & 0x00FFFFFF) {
                /* General events for directories and files. */
                case IN_ACCESS :
                    watch_event("accessed", filename, watches, event);
                    break;
                case IN_ATTRIB :
                    watch_event("metadata modified", filename, watches, event);
                    stat_file(filename);
                    break;
                case IN_OPEN :
                    watch_event("opened", filename, watches, event);
                    break;
                case IN_CLOSE_WRITE :
                    watch_event("closed for write", filename, watches, event);
                    break;
                case IN_CLOSE_NOWRITE :
                    watch_event("close for read", filename, watches, event);
                    break;
                case IN_CREATE :
                    watch_event("created", filename, watches, event);
                    break;
                case IN_DELETE :
                    watch_event("removed", filename, watches, event);
                    break;
                case IN_MOVED_FROM:
                case IN_MOVED_TO:
                case IN_MOVE :
                    watch_event("moved", filename, watches, event);
                    break;
                /* Cases where are watchers become invalid. */
                case IN_DELETE_SELF :
                    remove_watch("watched path was removed", event, watcher, watches);
                    break;
                case IN_MOVE_SELF :
                    remove_watch("watched path was moved", event, watcher, watches);
                    break;
                case IN_UNMOUNT :
                    remove_watch("NFS partition unmounted", event, watcher, watches);
                    break;
                /* Print the file contents since they changed. */
                case IN_MODIFY :
                    watch_event("modified", filename, watches, event);
                    if(IS_DIR_EVENT(event->mask)  ) {
                        if(print_file(filename)) {
                            fprintf(stderr, "cannot access %s...\n", filename);
                        }
                    }
                    break;
            }
            i += EVENT_SIZE + event->len;
        }
    }
    fprintf(stderr, "quitting: no active watch descriptors\n");
    close(watcher);
    return 0;
}

