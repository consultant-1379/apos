/*
 *
 * invocation (all of the following are equal):
 * ./ctr-cavstest --algo aes128-ctr --key 987212980144b6a632e864031f52dacc --mode encrypt --data a6deca405eef2e8e4609abf3c3ccf4a6
 * ./ctr-cavstest --algo aes128-ctr --key 987212980144b6a632e864031f52dacc --mode encrypt --data a6deca405eef2e8e4609abf3c3ccf4a6 --iv 00000000000000000000000000000000
 * echo -n a6deca405eef2e8e4609abf3c3ccf4a6 | ./ctr-cavstest --algo aes128-ctr --key 987212980144b6a632e864031f52dacc --mode encrypt
 */

#include "includes.h"

#include <sys/types.h>
#include <sys/param.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "xmalloc.h"
#include "log.h"
#include "cipher.h"

/* compatibility with old or broken OpenSSL versions */
#include "openbsd-compat/openssl-compat.h"

void
usage(void)
{
	fprintf(stderr, "Usage: ctr-cavstest --algo <ssh-crypto-algorithm>\n"
	    "                    --key <hexadecimal-key> --mode <encrypt|decrypt>\n"
	    "                    [--iv <hexadecimal-iv>] --data <hexadecimal-data>\n\n"
	    "Hexadecimal output is printed to stdout.\n"
	    "Hexadecimal input data can be alternatively read from stdin.\n");
	exit(1);
}

void *
fromhex(char *hex, size_t * len)
{
	unsigned char *bin;
	char *p;
	size_t n = 0;
	int shift = 4;
	unsigned char out = 0;
	unsigned char *optr;

	bin = xmalloc(strlen(hex) / 2);
	optr = bin;

	for (p = hex; *p != '\0'; ++p) {
		unsigned char c;

		c = *p;
		if (isspace(c))
			continue;

		if (c >= '0' && c <= '9') {
			c = c - '0';
		} else if (c >= 'A' && c <= 'F') {
			c = c - 'A' + 10;
		} else if (c >= 'a' && c <= 'f') {
			c = c - 'a' + 10;
		} else {
			/* truncate on nonhex cipher */
			break;
		}

		out |= c << shift;
		shift = (shift + 4) % 8;

		if (shift) {
			*(optr++) = out;
			out = 0;
			++n;
		}
	}

	*len = n;
	return bin;
}

#define READ_CHUNK 4096
#define MAX_READ_SIZE 1024*1024*100
char *
read_stdin(void)
{
	char *buf;
	size_t n, total = 0;

	buf = xmalloc(READ_CHUNK);

	do {
		n = fread(buf + total, 1, READ_CHUNK, stdin);
		if (n < READ_CHUNK)	/* terminate on short read */
			break;

		total += n;
		buf = xreallocarray(buf, total + READ_CHUNK, 1);
	} while (total < MAX_READ_SIZE);
	return buf;
}

int
main(int argc, char *argv[])
{

	struct sshcipher *c;
	struct sshcipher_ctx cc;
	char *algo = "aes128-ctr";
	char *hexkey = NULL;
	char *hexiv = "00000000000000000000000000000000";
	char *hexdata = NULL;
	char *p;
	int i;
	int encrypt = 1;
	void *key;
	size_t keylen;
	void *iv;
	size_t ivlen;
	void *data;
	size_t datalen;
	void *outdata;

	for (i = 1; i < argc; ++i) {
		if (strcmp(argv[i], "--algo") == 0) {
			algo = argv[++i];
		} else if (strcmp(argv[i], "--key") == 0) {
			hexkey = argv[++i];
		} else if (strcmp(argv[i], "--mode") == 0) {
			++i;
			if (argv[i] == NULL) {
				usage();
			}
			if (strncmp(argv[i], "enc", 3) == 0) {
				encrypt = 1;
			} else if (strncmp(argv[i], "dec", 3) == 0) {
				encrypt = 0;
			} else {
				usage();
			}
		} else if (strcmp(argv[i], "--iv") == 0) {
			hexiv = argv[++i];
		} else if (strcmp(argv[i], "--data") == 0) {
			hexdata = argv[++i];
		}
	}

	if (hexkey == NULL || algo == NULL) {
		usage();
	}

	SSLeay_add_all_algorithms();

	c = cipher_by_name(algo);
	if (c == NULL) {
		fprintf(stderr, "Error: unknown algorithm\n");
		return 2;
	}

	if (hexdata == NULL) {
		hexdata = read_stdin();
	} else {
		hexdata = xstrdup(hexdata);
	}

	key = fromhex(hexkey, &keylen);

	if (keylen != 16 && keylen != 24 && keylen == 32) {
		fprintf(stderr, "Error: unsupported key length\n");
		return 2;
	}

	iv = fromhex(hexiv, &ivlen);

	if (ivlen != 16) {
		fprintf(stderr, "Error: unsupported iv length\n");
		return 2;
	}

	data = fromhex(hexdata, &datalen);

	if (data == NULL || datalen == 0) {
		fprintf(stderr, "Error: no data to encrypt/decrypt\n");
		return 2;
	}

	cipher_init(&cc, c, key, keylen, iv, ivlen, encrypt);

	free(key);
	free(iv);

	outdata = malloc(datalen);
	if (outdata == NULL) {
		fprintf(stderr, "Error: memory allocation failure\n");
		return 2;
	}

	cipher_crypt(&cc, 0, outdata, data, datalen, 0, 0);

	free(data);

	cipher_cleanup(&cc);

	for (p = outdata; datalen > 0; ++p, --datalen) {
		printf("%02X", (unsigned char) *p);
	}

	free(outdata);

	printf("\n");
	return 0;
}
