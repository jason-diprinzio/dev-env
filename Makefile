CC=gcc
CC_OPTS=-Wall -O2 -std=c99 -fomit-frame-pointer

# I hear autoconf a knocking
GLIB_HEADER_DIR=/usr/include/glib-2.0
SYS_GLIB_HEADER_DIR=/usr/lib/x86_64-linux-gnu/glib-2.0/include 
GLIB_HEADER=$(GLIB_HEADER_DIR)/glib.h

INCLUDES=-I$(GLIB_HEADER_DIR) -I$(SYS_GLIB_HEADER_DIR)

LIBS=-lglib-2.0

PROGRAMS=chop watchdir watchpath

all:	required $(PROGRAMS)

$(GLIB_HEADER):
	@echo "requires libglib 2.0 and dev libraries"
	@exit 1

required:	$(GLIB_HEADER)

watchdir:	watch_dir.c
	$(CC) $(CC_OPTS) -D_DIR -D_IN_FLAGS=IN_ONLYDIR\|IN_ALL_EVENTS $(INCLUDES) $(LIBS) -o $@ watch_dir.c 

watchpath:	watch_dir.c
	$(CC) $(CC_OPTS) $(INCLUDES) $(LIBS) -o $@ watch_dir.c

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)

