#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>

#include <cstring>
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <memory>
#include <thread>

#include "watcher.h"

/* Date formatter buffer length */
constexpr uint8_t DF_BUFLEN  = 128;
constexpr uint16_t BUF_LEN = 8096;
constexpr uint32_t NOTIFY_FLAGS = IN_ONLYDIR|IN_ALL_EVENTS;

static volatile bool RUN_FLAG = true;
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
    std::cerr << std::endl << "stopping..." << std::endl;
    RUN_FLAG = false;
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
    fprintf(stdout, "[%s.%ld] ", datebuf, tv.tv_usec);
}

static inline void watch_event(const std::string& msg, const std::string& filename, const path_watcher& , const struct inotify_event *event)
{
    timestamp();
    fprintf(stdout, "[wd=%d,mask=x%08x,cookie=%u,length=%d] ", event->wd, event->mask, event->cookie, event->len);
    std::cout << "path " << filename << " " << msg << std::endl;
}

static inline int print_file(const std::string& filename)
{
    std::ifstream file = std::ifstream(filename, std::ios::binary);
    if(!file) {
        std::cerr << "file '" << filename << "' cannot be read" << std::endl;
        return 1;
    }

    std::cout << std::endl << "==========BEGIN FILE CONTENTS==========" << std::endl;
    std::string buf(BUF_LEN, '\0');
    file.seekg(0);
    while(!file.eof()) {
        file.read(&buf[0], BUF_LEN);
        std::cout << buf;
    }
    std::cout << std::endl << "==========END FILE CONTENTS============" << std::endl;

    return 0;
}

static inline int format_timestamp(const time_t *timestamp, const struct timespec *usec, const int buflen, char *buf)
{
    struct tm *timedata;
    timedata = localtime(timestamp);
    char datebuf[64];
    strftime(datebuf, 64, "%F %T", timedata);
    snprintf(buf, buflen, "%s.%lu", datebuf, usec->tv_sec);
    return 0;
}

static inline int stat_file(const std::string& filename)
{
    struct stat statbuf;
    if(stat(filename.c_str(), &statbuf)) {
        std::cerr << "cannot stat file '" << filename << "' -  " << strerror(errno) << std::endl;
        return 1;
    }

    char *type = NULL;
    if(S_ISREG(statbuf.st_mode) )         type = (char*)"regular file";
    else if(S_ISDIR(statbuf.st_mode) )    type = (char*)"directory";
    else if(S_ISCHR(statbuf.st_mode) )    type = (char*)"character device";
    else if(S_ISBLK(statbuf.st_mode) )    type = (char*)"block device";
    else if(S_ISFIFO(statbuf.st_mode))    type = (char*)"pipe";
    else if(S_ISLNK(statbuf.st_mode) )    type = (char*)"symbolic link";
    else if(S_ISSOCK(statbuf.st_mode))    type = (char*)"socket";

    int sbit    = (statbuf.st_mode >> 9)& 0x00000007;
    int omode   = (statbuf.st_mode >> 6)& 0x00000007;
    int gmode   = (statbuf.st_mode >> 3)& 0x00000007;
    int othmode = (statbuf.st_mode >> 0)& 0x00000007;

    char atime[DF_BUFLEN], mtime[DF_BUFLEN], ctime[DF_BUFLEN];
    format_timestamp(&statbuf.st_atime, &statbuf.st_atim, DF_BUFLEN, atime);
    format_timestamp(&statbuf.st_mtime, &statbuf.st_mtim, DF_BUFLEN, mtime);
    format_timestamp(&statbuf.st_ctime, &statbuf.st_ctim, DF_BUFLEN, ctime);

    fprintf(stdout, "\n==========BEGIN METADATA==========\n");
    fprintf(stdout, "  File: '%s'\n  Size: %ld       Blocks: %ld       Inode: %ld       %s\n",
        filename.c_str(), statbuf.st_size, statbuf.st_blocks, statbuf.st_ino, type);
    fprintf(stdout, "  Mode: %x%x%x%x     Uid: %u       Gid: %u\n",
        sbit,omode, gmode, othmode, statbuf.st_uid, statbuf.st_gid);
    fprintf(stdout, "Access: %s\nModify: %s\nChange: %s\n",
        atime, mtime, ctime);
    fprintf(stdout, "==========END METADATA============\n");
    return 0;
}

void handle_event(const std::string& filename, const struct inotify_event *event, const path_watcher& pw, const void *)
{
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
            break;
        case IN_DELETE :
            watch_event("removed", filename, pw, event);
            break;
        case IN_MOVED_FROM:
        case IN_MOVED_TO:
        case IN_MOVE :
            watch_event("moved", filename, pw, event);
            break;
        case IN_Q_OVERFLOW :
            /* We're not fast enough. */
            fprintf(stderr, "event queue overflow");
            break;
        case IN_MODIFY :
            /* Print the file contents since they changed. */
            watch_event("modified", filename, pw, event);
            if(!IS_DIR_EVENT(event->mask)  ) {
                print_file(filename);
            }
            break;
    }
}

int main(int argc, const char **argv)
{
    signal(SIGINT, &sig_handler);
    std::vector<std::string> paths;

    if(argc > 1) {
        for(auto i=1; i< argc; i++) {
            paths.push_back(argv[i]);
        }
    } else {
        paths.push_back(".");
    }

    watch_args wargs (watch_options_e::WATCH_OPT_RECURSE|watch_options_e::WATCH_OPT_REQUIRE_DIR,
            NOTIFY_FLAGS, NULL, paths, handle_event);

    return watch(wargs, &RUN_FLAG);
}

