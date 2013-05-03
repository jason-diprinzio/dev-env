#include <sys/inotify.h>

#define IS_DIR_EVENT(mask)\
    (((mask >> 24) & 0xf0) != IN_ISDIR)

typedef const int inotify_handle_t;

typedef struct _path_watcher {
    int wd;
    unsigned int watchpath_len;
    char *watchpath;
} path_watcher_t;

typedef void(watcher_event_callback)(const char *filename, const struct inotify_event *event, const path_watcher_t *watcher, const void *userdata);

enum _watch_options {
    WATCH_OPT_NONE        = 0x00000000,
    WATCH_OPT_RECURSE     = 0x00000001 << 0,
    WATCH_OPT_REQUIRE_DIR = 0x00000001 << 1
};

typedef struct _watch_args {
    int numpaths;
    int options;
    int watch_flags;
    char **paths;
    watcher_event_callback *callback;
    void *userdata;
    volatile unsigned char *run_flag; 
} watch_args_t;

int new_watch_args(watch_args_t ** newwargs, const int numpaths, const int options, const int watch_flags,
        const char **paths, watcher_event_callback *callback, const void *userdata, volatile unsigned char *run_flag);
void free_watch_args(watch_args_t *wargs);
#define FREE_WATCH_ARGS(wargs) \
    free_watch_args(wargs); \
    wargs = 0;

int watch(const watch_args_t *wargs);

