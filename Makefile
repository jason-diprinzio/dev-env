CC=gcc
CC_OPTS=-Wall -O2 -std=c99 -fomit-frame-pointer

PROGRAMS=chop watchdir watchpath

all: $(PROGRAMS)

watchdir:	watch_dir.c
	$(CC) $(CC_OPTS) -D_DIR -D_IN_FLAGS=IN_ONLYDIR\|IN_ALL_EVENTS -o $@ watch_dir.c 

watchpath:	watch_dir.c
	$(CC) $(CC_OPTS) -D_IN_FLAGS=IN_ACCESS\|IN_OPEN\|IN_CLOSE_WRITE\|IN_CLOSE_NOWRITE\|IN_ATTRIB\|IN_MODIFY\|IN_DELETE_SELF -o $@ watch_dir.c

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)

