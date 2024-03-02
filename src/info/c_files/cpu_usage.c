#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/statvfs.h>

int get_cpu_usage()
{
    FILE* file;
    char* line;
    size_t len = 0;
    ssize_t read;
    int usg;

    file = fopen("/proc/stat", "r");
    if (file == NULL)
        exit(EXIT_FAILURE);

    while ((read = getline(&line, &len, file)) != -1) {
        if (line[0] == 'c' && line[1] == 'p' && line[2] == 'u') {
            char* p = line;
            int user, nice, system, idle;

            while (*p < '0' || *p > '9') ++p;
            user = atoi(p);
            while (*p >= '0' && *p <= '9') ++p;
            nice = atoi(p);
            while (*p < '0' || *p > '9') ++p;
            system = atoi(p);
            while (*p >= '0' && *p <= '9') ++p;
            idle = atoi(p);

            int total = user + nice + system + idle;
            int usage = 100 * (total - idle) / total;
            usg = usage;
            break;
        }
    }

    fclose(file);
    if (line)
        free(line);

    return usg;
}