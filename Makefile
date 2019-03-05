CC=gcc
CPP=g++
CC_OPTS=-std=c99 -Wall -Wextra -Werror -O2 -fomit-frame-pointer -I.
CPP_OPTS=-std=gnu++14 -Wall -Wextra -Werror -O2 -fomit-frame-pointer -I.
STATIC_OPTS=-static -static-libstdc++ 
DYNAMIC_OPTS=
LINK_OPTS=$(STATIC_OPTS)
LIB_OPTS=-shared -fPIC
PROGRAMS=chop watchdir pwcli
WATCHER_OBJ=watcher.o
HEADERS=watcher.h
OBJS=$(WATCHER_OBJ)
LIB_WATCHER=libwatcher.so

all:	$(LIB_WATCHER) $(PROGRAMS)

install:
	./install.sh

uninstall:
	./uninstall.sh

$(LIB_WATCHER):	$(HEADERS) watcher.cpp
	$(CPP) $(LIB_OPTS) $(CPP_OPTS) -o $@ watcher.cpp

watcher.o:	$(HEADERS) watcher.cpp
	$(CPP) $(CPP_OPTS) -c -o $@ watcher.cpp

watchdir:	$(OBJS) watch_dir.cpp
	$(CPP) $(CPP_OPTS) $(LINK_OPTS)  -o $@ $(WATCHER_OBJ) watch_dir.cpp

pwcli:	pw_mgmt.cpp
	$(CPP) $(CPP_OPTS) -o $@ pw_mgmt.cpp

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)
	rm -f $(OBJS)
	rm -f $(LIB_WATCHER)

