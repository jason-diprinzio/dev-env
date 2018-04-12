#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define BUFSIZE 256
int main(int argc, char **argv)
{
    
    char buf[BUFSIZE];
    char left = '\0';
    char *ptr = 0;

    if(argc <= 1) {
        while( fgets(buf, BUFSIZE, stdin) != NULL ){
            printf("%s", &left);
            int len = strlen(buf) - 1;
            ptr = buf + len;
            left = *ptr;
            char fmt[20];
            sprintf(fmt, "%%%d.%ds", len, len);
            printf(fmt, buf);
        }
    }

    return 0;
}

