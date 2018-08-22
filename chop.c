#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFSIZE 256
int main(int argc, char **argv)
{
    int cut_len = 1;
    char buf[BUFSIZE];

    if(argc > 2) {
        if(!strcmp("-l", argv[1])){
            cut_len = atoi(argv[2]);
            if(cut_len < 0 || cut_len > BUFSIZE) {
                fprintf(stderr, "http://gph.is/1sDbwUI\n");
                exit(127);
            }
        }
    }

    while( fgets(buf, BUFSIZE, stdin) != NULL ){
        int len = strlen(buf);
        len = (len-cut_len<0 ? 0 : len-cut_len);
        size_t bw = write(1, buf, len);
        while(len -= bw) {
            bw = write(1, buf, len);
        }
    }

    return 0;
}

