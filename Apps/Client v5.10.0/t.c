#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <arpa/inet.h>

int main() {
    struct hostent *host_info;
    char *hostname = "hostname.example.com";

    // Call gethostbyname
    host_info = gethostbyname(hostname);
    if (host_info == NULL) {
        fprintf(stderr, "Could not resolve hostname: %s\n", hostname);
        return 1;
    }

    // Iterate over all the addresses associated with this hostname
    for (int i = 0; host_info->h_addr_list[i] != NULL; i++) {
        struct in_addr *address = (struct in_addr *)host_info->h_addr_list[i];
        printf("IP address %d: %s\n", i + 1, inet_ntoa(*address));
    }

    return 0;
}
