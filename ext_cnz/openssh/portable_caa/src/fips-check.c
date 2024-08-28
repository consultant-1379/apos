#include "includes.h"
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "digest.h"
#include "fips.h"

#include <openssl/err.h>

#define PROC_NAME_LEN	64

static const char *argv0;

void
print_help_exit(int ev)
{
	fprintf(stderr, "%s <-c|-w> <file> <checksum_file>\n", argv0);
	fprintf(stderr, "	-c  verify hash of 'file' against hash in 'checksum_file'\n");
	fprintf(stderr, "	-w  write hash of 'file' into 'checksum_file'\n");
	exit(ev);
}

int
main(int argc, char **argv)
{
    fips_ssh_init();
	return 0;
}
