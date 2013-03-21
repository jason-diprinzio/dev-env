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

#define EVENT_SIZE  (sizeof (struct inotify_event))
#define BUF_LEN   (1024 * (EVENT_SIZE + 16))

#ifdef _IN_FLAGS
#define NOTIFY_FLAGS _IN_FLAGS
#else
#define NOTIFY_FLAGS IN_ALL_EVENTS
#endif

#define IS_DIR_EVENT(mask)\
    (((mask >> 24) & 0xf0) != IN_ISDIR)

#define DF_BUFLEN 128

static volatile unsigned char RUN_FLAG = 0;

typedef struct _path_watcher {
    int wd;
    char *watchpath;
} path_watcher;

void sig_handler(int sig)
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

static inline void watch_event(const char *msg, const char *filename, const path_watcher *watcher, const struct inotify_event *event)
{
    timestamp();
    fprintf(stdout, "[wd=%d,mask=x%08x,cookie=%u,length=%d] ", event->wd, event->mask, event->cookie, event->len);
    fprintf(stdout, "file [%s] in watched path [%s] event [%s]", filename, watcher->watchpath, msg);
}

static inline int print_file(const char *filename)
{
    FILE *file = fopen(filename, "r");
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

static inline int stat_file(const char *filename)
{
    struct stat statbuf;
    if(stat(filename, &statbuf)) {
        perror("cannot stat file");
        return 1;
    }

    char *type = NULL;
    if(S_ISREG(statbuf.st_mode) )         type = "regular file"; 
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

#ifdef _DIR
static inline int is_dir(const char *path)
{
    struct stat check_buf;
    if(stat(path, &check_buf)){
        perror("error stat");
        return errno;
    }
    if(S_ISDIR(check_buf.st_mode)) {
        return 0;
    }
    return 1;
}

static inline int check_is_dir(const char *path)
{
    if(is_dir(path)) {
        fprintf(stderr, "%s is not a directory\n", path);
        return 1;
    } 
    return 0;
}
#else
static inline int is_dir(const char *path)
{
    return 1;
}

static inline int check_is_dir(const char *path)
{
    return 0;
}
#endif

static inline int check_path(const char *path)
{
    int eval = 0;
    if((eval = access(path, R_OK))) {
        perror("cannot watch path");
        return eval;
    }

    return check_is_dir(path);
}

static inline int new_path_watcher(path_watcher **watcher)
{
    *watcher = (path_watcher *)malloc(sizeof (path_watcher));
    memset(*watcher, 0, sizeof(path_watcher));
    return watcher == NULL;
}

#define free_path_watcher(ref) \
    free(ref); \
    ref = 0;

static void path_watcher_value_removed(gpointer data) 
{
    free_path_watcher(data);
}

static void path_watcher_key_removed(gpointer data)
{
    g_free(data);
}

static inline void remove_watch(const char *msg, GHashTable *watch_table, const struct inotify_event *event, const path_watcher *pw, const int watcher)
{
    fprintf(stderr, "%s - removing notifications for path: %s\n", msg, pw->watchpath);
    g_hash_table_remove(watch_table, &(event->wd));
    inotify_rm_watch(watcher, event->wd);
}

static inline int add_watch(GHashTable *watch_table, const char *filename, const int watcher)
{
    int watch_index = inotify_add_watch(watcher, filename, NOTIFY_FLAGS);
    if(watch_index > 0) {
        fprintf(stderr, "adding watch for path: %s\n", filename);
        path_watcher *pw;
        new_path_watcher(&pw);
        pw->wd = watch_index;
        pw->watchpath = g_strdup(filename);
        gint *g_key = g_new(gint, 1);
        *g_key = watch_index; 
        g_hash_table_insert(watch_table, g_key, pw);
        return watch_index;
    } else {
        fprintf(stderr, "cannot add watch for path: %s\n", filename);
    }
    return 0; 
}

/* TODO: max depth arg */
int recurse_dir(const char* dirname, const int watcher, GHashTable *watch_table)
{
    DIR *dir =0 ;
    dir = opendir(dirname);
    if(!dir){
        return 1;
    }   
    struct dirent *entry = 0;
    while( (entry = readdir(dir)) != NULL ) { 
        char *prefix = entry->d_name;
        if('.' == *prefix ) continue;

        char fullname[entry->d_reclen + strlen(dirname) + 1 ];
        sprintf(fullname, "%s/%s", dirname, entry->d_name);

        if(is_dir(fullname)== 0) {
            recurse_dir(fullname, watcher, watch_table);
            /* TODO: Q these up to avoid notifications while we search for more directories. */
            add_watch(watch_table, fullname, watcher); 
        }
    }   
    closedir(dir);
    return 0;
}

int main(const int argc, const char ** argv)
{
    int watcher = inotify_init();

    if(watcher < 0) {
        perror("Failed to initialize inotify");
        return 1;
    }

    GHashTable *watch_table;
    watch_table = g_hash_table_new_full(g_int_hash, g_int_equal, 
            path_watcher_key_removed, path_watcher_value_removed);

    if(1 < argc) {
        for(int i=1; i<argc; i++){
            if(!check_path(argv[i]))
                add_watch(watch_table, argv[i], watcher); 

            recurse_dir(argv[i], watcher, watch_table);
        }
    } else {
        recurse_dir(".", watcher, watch_table);
        add_watch(watch_table, ".", watcher); 
    }

    char buf[BUF_LEN];

    int retval = 0;

    RUN_FLAG = 1;
    signal(SIGINT, &sig_handler);

    while(g_hash_table_size(watch_table) && RUN_FLAG) {
        int len, i = 0;
        len = read(watcher, buf, BUF_LEN);
        if(len < 0) {
            if(errno == EINTR) {
                continue;
            }else {
                perror("read error");
                retval = errno;
                RUN_FLAG = 0;
                break;
            }
        } else if(!len) {
            fprintf(stderr, "no data from read\n");
            continue;
        }

        while(i<len) {
            struct inotify_event *event;

            event = (struct inotify_event *) &buf[i];
            path_watcher *pw = 0;
            pw = g_hash_table_lookup(watch_table, &(event->wd));

            if(pw) {
                char filename[1024];
                if(event->len > 0) {
                    sprintf(filename, "%s/%s", pw->watchpath, event->name);
                } else {
                    sprintf(filename, "%s", pw->watchpath);
                }
                switch(event->mask & 0x00FFFFFF) {
                    /* General events for directories and files. */
                    case IN_ACCESS :
                        watch_event("accessed", filename, pw, event);
                        break;
                    case IN_ATTRIB :
                        watch_event("metadata modified", filename, pw, event);
                        stat_file(filename);
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
                        add_watch(watch_table, filename, watcher);
                        break;
                    case IN_DELETE :
                        watch_event("removed", filename, pw, event);
                        break;
                    case IN_MOVED_FROM:
                    case IN_MOVED_TO:
                    case IN_MOVE :
                        watch_event("moved", filename, pw, event);
                        break;
                    /* Cases where are watchers become invalid. */
                    case IN_DELETE_SELF :
                        remove_watch("watched path was removed", watch_table, event, pw, watcher);
                        break;
                    case IN_MOVE_SELF :
                        remove_watch("watched path was moved", watch_table, event, pw, watcher);
                        break;
                    case IN_UNMOUNT :
                        remove_watch("NFS partition unmounted", watch_table, event, pw, watcher);
                        break;
                    /* We're not fast enough. */
                    case IN_Q_OVERFLOW :
                        fprintf(stderr, "event queue overflow");
                        break;
                    /* Print the file contents since they changed. */
                    case IN_MODIFY :
                        watch_event("modified", filename, pw, event);
                        if(IS_DIR_EVENT(event->mask)  ) {
                            if(print_file(filename)) {
                                fprintf(stderr, "cannot access %s...\n", filename);
                            }
                        }
                        break;
                }
            }
            i += EVENT_SIZE + event->len;
        }
    }

    fprintf(stderr, "quitting: no active watch descriptors\n");
    close(watcher);
    g_hash_table_destroy(watch_table); 

    return retval;
}

