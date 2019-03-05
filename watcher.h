#include <sys/inotify.h>
#include <string>
#include <memory>
#include <vector>
#include <functional>

using inotify_handle = const int32_t;
using watch_descriptor = int;

constexpr bool IS_DIR_EVENT(const uint32_t mask) { return ((mask & 0xFF000000) == IN_ISDIR); }

struct  path_watcher {
    watch_descriptor wd;
    std::string watchpath;
}; 

enum watch_options_e : uint32_t {
    WATCH_OPT_NONE        = 0x00000000,
    WATCH_OPT_RECURSE     = 0x00000001 << 0,
    WATCH_OPT_REQUIRE_DIR = 0x00000001 << 1
};

using watcher_event_callback =
    std::function<void (const std::string& filename, const struct inotify_event *event, 
    const path_watcher& watcher, void *userdata)>;

const watcher_event_callback EMPTY_CALLBACK = [](const std::string&, const struct inotify_event *,
        const path_watcher& , void *) {/*nop*/};

class watch_args {

public:
    uint8_t _options;
    uint32_t _watch_flags;
    const void * const _userdata;
    std::vector<std::string> _paths;
    watcher_event_callback _callback;

    explicit watch_args(const int options, const int watch_flags, 
            const void* const user_data, std::vector<std::string> paths,
            watcher_event_callback callback=EMPTY_CALLBACK) 
        :
             _options(options), _watch_flags(watch_flags), 
             _userdata(user_data), _paths(paths), _callback(callback)
    {}
};

int watch(const watch_args& wargs, volatile bool *run_flag);

