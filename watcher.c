#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <glib.h>
#include <sys/stat.h>

#include "watcher.h"

#define EVENT_SIZE  (sizeof (struct inotify_event))
#define BUF_LEN   (1024 * (EVENT_SIZE + 16))

#define IS_DIR_RECURSE(flags)  (flags & WATCH_OPT_RECURSE)
#define IS_DIR_REQUIRED(flags) (flags & WATCH_OPT_REQUIRE_DIR)

int new_watch_args(watch_args_t ** newwargs, const int numpaths, const int options, const int watch_flags,
        const char **paths, watcher_event_callback *callback, const void *userdata, volatile unsigned char *run_flag)
{
    if( sizeof(paths) != numpaths * sizeof(char*) ) {
        return -1;
    }
    watch_args_t *wargs = *newwargs;
    wargs = (watch_args_t*)malloc(sizeof(watch_args_t));
    if(!wargs) {
        return 1;
    }
    memset(wargs, 0, sizeof(watch_args_t));
    wargs->numpaths = numpaths;
    wargs->options = options;
    wargs->watch_flags = watch_flags;
    wargs->paths = malloc(sizeof(char) * numpaths);
    if(!(wargs->paths)) {
        free(wargs);
        return 1;
    }

    for(int i=0; i<numpaths; i++) {
        const char *tmp = paths[i];
        wargs->paths[i] = malloc(sizeof(char) * strlen(tmp) + 1);
        strncpy(wargs->paths[i], tmp, strlen(tmp));
    }

    /* just point these in the right direction */
    wargs->callback = callback;
    wargs->userdata = (void*)userdata;
    wargs->run_flag = run_flag;
    *newwargs = wargs;

    return 0; 
}

void free_watch_args(watch_args_t *wargs)
{
    for(int i=0; i < wargs->numpaths; i++){
        free(wargs->paths[i]);
    }
    free(wargs->paths);
    memset(wargs, 0, sizeof(watch_args_t));
    free(wargs);
}

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

static inline int check_path(const char *path)
{
    int eval = 0;
    if((eval = access(path, R_OK))) {
        perror("cannot watch path");
    }
    return eval;
}

static inline int new_path_watcher(path_watcher_t **watcher, const int wd, const char *filename)
{
    *watcher = (path_watcher_t *)malloc(sizeof (path_watcher_t));
    memset(*watcher, 0, sizeof(path_watcher_t));

    path_watcher_t *pw = *watcher;
    pw->wd = wd;
    pw->watchpath = g_strdup(filename);
    pw->watchpath_len = strlen(pw->watchpath);

    return *watcher == NULL;
}

#define FREE_PATH_WATCHER(ref) \
    free_path_watcher((path_watcher_t*)ref); \
    ref = 0

static void free_path_watcher(path_watcher_t *watcher)
{
    g_free(watcher->watchpath);
    free(watcher);
}

static void path_watcher_value_removed(gpointer data) 
{
    FREE_PATH_WATCHER(data);
}

static void path_watcher_key_removed(gpointer data)
{
    g_free(data);
}

static inline void remove_watch(const char *msg, GHashTable *watch_table, const struct inotify_event *event, 
        const path_watcher_t *watcher, inotify_handle_t in_handle)
{
    fprintf(stderr, "%s - removing notifications for path: %s\n", msg, watcher->watchpath);
    g_hash_table_remove(watch_table, &(event->wd));
    inotify_rm_watch(in_handle, event->wd);
}

static inline int add_watch(GHashTable *watch_table, const char *filename, inotify_handle_t in_handle, const int watch_flags)
{
    int wd = inotify_add_watch(in_handle, filename, watch_flags);
    if(wd > 0) {
        fprintf(stderr, "adding watch for path: %s\n", filename);
        path_watcher_t *pw;
        new_path_watcher(&pw, wd, filename);
        gint *g_key = g_new(gint, 1);
        *g_key = wd; 
        g_hash_table_insert(watch_table, g_key, pw);
        return wd;
    } else {
        fprintf(stderr, "cannot add watch for path: %s\n", filename);
    }
    return 0; 
}

/* TODO: max depth arg */
static int recurse_dir(const char* dirname, inotify_handle_t in_handle, GHashTable *watch_table, const watch_args_t *wargs)
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
            recurse_dir(fullname, in_handle, watch_table, wargs);
            /* TODO: Q these up to avoid notifications while we search for more directories. */
            add_watch(watch_table, fullname, in_handle, wargs->watch_flags); 
        }
    }   
    closedir(dir);
    return 0;
}

static void setup_watches(GHashTable *watch_table, const inotify_handle_t in_handle, const watch_args_t *wargs)
{
    const int numpaths = wargs->numpaths;
    char **paths = wargs->paths;
    if(0 < numpaths) {
        for(int i=0; i<numpaths; i++){
            if(!check_path(paths[i])) {
                if(IS_DIR_REQUIRED(wargs->options) && check_is_dir(paths[i])) {
                        continue;
                }
                add_watch(watch_table, paths[i], in_handle, wargs->watch_flags); 
            }

            if(IS_DIR_RECURSE(wargs->options)){
                recurse_dir(paths[i], in_handle, watch_table, wargs);
            }
        }
    }
}

int watch(const watch_args_t *wargs)
{
    watcher_event_callback *callback = wargs->callback; 
    inotify_handle_t  in_handle = inotify_init();

    if(in_handle < 0) {
        perror("Failed to initialize inotify");
        return 1;
    }

    GHashTable *watch_table;
    watch_table = g_hash_table_new_full(g_int_hash, g_int_equal, 
            path_watcher_key_removed, path_watcher_value_removed);

    setup_watches(watch_table, in_handle, wargs);
    
    char buf[BUF_LEN];
    int retval = 0;
    *(wargs->run_flag) = 1;

    while(g_hash_table_size(watch_table) && *(wargs->run_flag)) {
        int len, i = 0;
        len = read(in_handle, buf, BUF_LEN);
        if(len < 0) {
            if(errno == EINTR) {
                continue;
            }else {
                perror("read error");
                retval = errno;
                *(wargs->run_flag) = 0;
                break;
            }
        } else if(!len) {
            fprintf(stderr, "no data from read\n");
            continue;
        }

        while(i<len) {
            struct inotify_event *event;

            event = (struct inotify_event *) &buf[i];
            path_watcher_t *pw = 0;
            pw = g_hash_table_lookup(watch_table, &(event->wd));

            if(pw) {
                unsigned int flen = 255;
                char filename[flen];
                memset(filename, 0, sizeof(char)*flen);

                if(event->len > 0) {
                    strncpy(filename, event->name, flen);
                } else {
                    strncpy(filename, pw->watchpath, flen);
                }
                /* Just make a callback if one exists. */
                if(NULL!= callback) {
                    /* TODO send back user data */
                    callback(filename, event, pw, NULL);
                }

                switch(event->mask & 0x00FFFFFF) {
                    case IN_CREATE :
                        if(is_dir(filename) == 0)
                            add_watch(watch_table, filename, in_handle, wargs->watch_flags);
                        break;
                        /* Cases where are watchers become invalid. */
                    case IN_DELETE_SELF :
                        remove_watch("watched path was removed", watch_table, event, pw, in_handle);
                        break;
                    case IN_MOVE_SELF :
                        remove_watch("watched path was moved", watch_table, event, pw, in_handle);
                        break;
                    case IN_UNMOUNT :
                        remove_watch("NFS partition unmounted", watch_table, event, pw, in_handle);
                        break;
                }
            }
            i += EVENT_SIZE + event->len;
        }
    }

    fprintf(stderr, "quitting: no active watch descriptors\n");
    close(in_handle);
    g_hash_table_destroy(watch_table); 

    return retval;
}

