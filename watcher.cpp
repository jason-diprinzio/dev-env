#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

#include <string>
#include <sstream>
#include <iostream>
#include <map>

#include "watcher.h"

constexpr size_t EVENT_SIZE = sizeof(struct inotify_event);
constexpr size_t BUF_LEN =  (1024 * (EVENT_SIZE + 16));

constexpr bool IS_DIR_RECURSE(const uint8_t flags) { return (flags & WATCH_OPT_RECURSE); }
constexpr bool IS_DIR_REQUIRED(const uint8_t flags) { return (flags & WATCH_OPT_REQUIRE_DIR); }

using watcher_map = std::map<watch_descriptor, path_watcher>;

static inline int is_dir(const std::string& path)
{
    struct stat check_buf;
    if(stat(path.c_str(), &check_buf)){
        perror("error stat");
        return errno;
    }
    if(S_ISDIR(check_buf.st_mode)) {
        return 0;
    }
    return 1;
}

static inline int check_is_dir(const std::string& path)
{
    if(is_dir(path)) {
        std::cerr << path << "is not a directory" << std::endl;
        return 1;
    } 
    return 0;
}

static inline int check_path(const std::string& path)
{
    int eval = 0;
    if((eval = access(path.c_str(), R_OK))) {
        perror("cannot watch path");
    }
    return eval;
}

static inline void remove_watch(watcher_map& watch_table, const std::string& msg, const struct inotify_event *event,
        const path_watcher& watcher, inotify_handle in_handle)
{
    std::cerr << msg << " - removing notifications for path: " << watcher.watchpath << std::endl;
    inotify_rm_watch(in_handle, event->wd);
    watch_table.erase(event->wd);
}

static inline void add_watch(watcher_map& watch_table, const std::string& filename, inotify_handle in_handle, const uint32_t watch_flags)
{
    watch_descriptor wd = inotify_add_watch(in_handle, filename.c_str(), watch_flags);
    if(wd > 0) {
        std::cerr << "adding watch for path: " << filename << std::endl;
        watch_table[wd] = {wd,filename};
    } else {
        std::cerr << "cannot add watch for path: " << filename << std::endl;
    }
}

/* TODO: max depth arg */
static int recurse_dir(watcher_map& watch_table, const std::string& dirname, inotify_handle& in_handle, const watch_args& wargs)
{
    DIR *dir =0 ;
    dir = opendir(dirname.c_str());
    if(!dir){
        return 1;
    }   
    struct dirent *entry = 0;
    while( (entry = readdir(dir)) != NULL ) { 
        char *prefix = entry->d_name;
        if('.' == *prefix ) continue;

        std::stringstream fullname;
        fullname << dirname << "/" << entry->d_name;

        if(is_dir(fullname.str()) == 0) {
            recurse_dir(watch_table, fullname.str(), in_handle, wargs);
            /* TODO: Q these up to avoid notifications while we search for more directories. */
            add_watch(watch_table, fullname.str(), in_handle, wargs._watch_flags);
        }
    }   
    closedir(dir);
    return 0;
}

static void setup_watches(watcher_map& watch_table, const inotify_handle& in_handle, const watch_args& wargs)
{
    for(auto path : wargs._paths) {
        if(!check_path(path)) {
            if(IS_DIR_REQUIRED(wargs._options) && check_is_dir(path)) {
                continue;
            }
            add_watch(watch_table, path, in_handle, wargs._watch_flags); 
        }

        if(IS_DIR_RECURSE(wargs._options)){
            recurse_dir(watch_table, path, in_handle, wargs);
        }
    }
}

template<class closeme>
class auto_close
{
    private:
        closeme _closer;
    public:
        auto_close(closeme closer) : _closer(closer) {}
        virtual ~auto_close() {  close(_closer); }
        const closeme& operator *() { return _closer; }
};

int watch(const watch_args& wargs, volatile bool *run_flag)
{
    auto_close<inotify_handle> in_handle(inotify_init1(IN_NONBLOCK));

    if(*in_handle < 0) {
        perror("failed to initialize inotify");
        return 1;
    }

    watcher_map watch_table;

    setup_watches(watch_table, *in_handle, wargs);
    
    char buf[BUF_LEN];
    int retval = 0;

    while(!watch_table.empty() && *run_flag) {
        int len, i = 0;
        len = read(*in_handle, buf, BUF_LEN);
        if(len < 0) {
            if(errno == EINTR) {
                break;
            } else if(errno == EAGAIN) {
                // pause, there will be data
                usleep(5000);
                continue;
            } else {
                perror("read error");
                retval = errno;
                *run_flag = false;
                break;
            }
        } else if(!len) {
            std::cerr << "no data from read" << std::endl;
            continue;
        }

        while(i<len) {
            const struct inotify_event *event;

            event = (struct inotify_event *) &buf[i];
            try {
                const path_watcher pw = watch_table.at(event->wd);

                std::string filename;
                if(event->len > 0) {
                   filename = std::string(event->name);
                } else {
                   filename = std::string(pw.watchpath);
                }

                wargs._callback(static_cast<const std::string>(filename), event, pw, nullptr);

                switch(event->mask & 0x00FFFFFF) {
                    case IN_CREATE :
                        if(is_dir(filename) == 0)
                            add_watch(watch_table, static_cast<std::string>(filename), *in_handle, wargs._watch_flags);
                        break;
                        /* Cases where are watchers become invalid. */
                    case IN_DELETE_SELF :
                        remove_watch(watch_table, "watched path was removed", event, pw, *in_handle);
                        break;
                    case IN_MOVE_SELF :
                        remove_watch(watch_table, "watched path was moved", event, pw, *in_handle);
                        break;
                    case IN_UNMOUNT :
                        remove_watch(watch_table, "NFS partition unmounted", event, pw, *in_handle);
                        break;
                }
            } catch(std::out_of_range& e) {
                std::cerr << "watcher descriptor is no longer active" << std::endl;
            }
            i += EVENT_SIZE + event->len;
        }
    }

    std::cerr << "quitting: no active watch descriptors" << std::endl;

    return retval;
}

