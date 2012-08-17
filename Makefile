CC=gcc
CC_OPTS=-Wall -O2 -std=c99 -fomit-frame-pointer

PROGRAMS=watchdir chop

all: $(PROGRAMS)

watchdir:	watch_dir.c
	$(CC) $(CC_OPTS) -o watchdir watch_dir.c

chop:	chop.c
	$(CC) $(CC_OPTS) -o chop chop.c

clean:
	rm -f $(PROGRAMS)

