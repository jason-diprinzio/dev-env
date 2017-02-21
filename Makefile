CC=gcc
CPP=g++
OPTS=-Wall -Wextra -O2 -fomit-frame-pointer -I./
CC_OPTS+=-std=c99 
CPP_OPTS+=-std=gnu++11
LIB_OPTS=-shared -fPIC

# I hear autoconf a knocking
GLIB_OPTS=$(shell pkg-config --cflags --libs glib-2.0)

PROGRAMS=chop watchdir watchpath pwcli
WATCHER_OBJ=watcher.o
HEADERS=watcher.h
OBJS=$(WATCHER_OBJ)
LIB_WATCHER=libwatcher.so

all:	required $(LIB_WATCHER) $(PROGRAMS)

install:
	./install.sh

uninstall:
	./uninstall.sh

required:
	@echo "checking for glib-2.0 libary"
	@pkg-config --exists glib-2.0

$(LIB_WATCHER):	watcher.h watcher.c
	$(CC) $(LIB_OPTS) $(CC_OPTS) -o $@ watcher.c $(GLIB_OPTS)

watcher.o:	$(HEADERS) watcher.c
	$(CC) $(CC_OPTS) -c -o $@ watcher.c $(GLIB_OPTS)

watchdir:	$(OBJS) watch_dir.c
	$(CC) $(CC_OPTS) -D_DIR -D_IN_FLAGS=IN_ONLYDIR\|IN_ALL_EVENTS -o $@ $(WATCHER_OBJ) watch_dir.c $(GLIB_OPTS)

watchpath:	$(OBJS) watch_dir.c
	$(CC) $(CC_OPTS) -o $@ $(WATCHER_OBJ) watch_dir.c $(GLIB_OPTS)

pwcli:	pw_mgmt.cpp
	$(CPP) $(CPP_OPTS) -o $@ pw_mgmt.cpp

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)
	rm -f $(OBJS)
	rm -f $(LIB_WATCHER)

