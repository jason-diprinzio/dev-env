CFLAGS+= -std=c99 -Wall -Wextra -Werror -O2 -fomit-frame-pointer -I.
CXXFLAGS+= -std=gnu++20 -Wall -Wextra -Werror -O2 -fomit-frame-pointer -I.
STATIC_OPTS=-static
LDFLAGS+= $(STATIC_OPTS)
LIB_OPTS=-shared -fPIC
PROGRAMS=watchdir
HEADERS=watcher.h
OBJS=watcher.o  watch_dir.o
LIB_WATCHER=libwatcher.so

all:	$(LIB_WATCHER) $(PROGRAMS)

install:
	./install.sh

uninstall:
	./uninstall.sh

$(LIB_WATCHER):	$(HEADERS) watcher.cpp
	$(CXX) $(LIB_OPTS) $(CXXFLAGS) -o $@ watcher.cpp

watcher.o:	$(HEADERS) watcher.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ watcher.cpp

watchdir.o: watch_dir.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ watcher_dir.cpp

watchdir:	$(OBJS)
	$(CXX) -o $@ $(OBJS)

clean:
	rm -f $(PROGRAMS)
	rm -f $(OBJS)
	rm -f $(LIB_WATCHER)

