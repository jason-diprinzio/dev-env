CC=gcc
CC_OPTS=-Wall -O2 -std=c99 -fomit-frame-pointer

# I hear autoconf a knocking 
GLIB_OPTS=$(shell pkg-config --cflags --libs glib-2.0)

PROGRAMS=chop watchdir watchpath

all:	required $(PROGRAMS)

$(GLIB_HEADER):
	@echo "requires libglib 2.0 and dev libraries"
	@exit 1

required:	$(GLIB_HEADER)

watchdir:	watch_dir.c
	$(CC) $(CC_OPTS) -D_DIR -D_IN_FLAGS=IN_ONLYDIR\|IN_ALL_EVENTS -o $@ watch_dir.c $(GLIB_OPTS)

watchpath:	watch_dir.c
	$(CC) $(CC_OPTS) -o $@ watch_dir.c $(GLIB_OPTS)

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)

