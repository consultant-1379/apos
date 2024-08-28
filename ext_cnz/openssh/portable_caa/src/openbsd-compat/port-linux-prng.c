/*
 * Copyright (c) 2011 Jan F. Chadima <jchadima@redhat.com>
 *           (c) 2011 Petr Cerny <pcerny@suse.cz>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 * Linux-specific portability code - prng support
 */

#include "includes.h"
#include "defines.h"

#include <errno.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <openssl/rand.h>

#include "log.h"
#include "port-linux.h"
#include "fips.h"

#define RNG_BYTES_DEFAULT	6L
#define RNG_ENV_VAR		"SSH_USE_STRONG_RNG"

long rand_bytes = 0;
char *rand_file = NULL;

static void
linux_seed_init(void)
{
	long elen = 0;
	char *env = getenv(RNG_ENV_VAR);

	if (env) {
		errno = 0;
		elen = strtol(env, NULL, 10);
		if (errno) {
			elen = RNG_BYTES_DEFAULT;
			debug("bogus value in the %s environment variable, "
				"using %li bytes from /dev/random\n",
				RNG_ENV_VAR, RNG_BYTES_DEFAULT);
		}
	}

	if (elen || fips_mode())
		rand_file = "/dev/random";
	else
		rand_file = "/dev/urandom";

	rand_bytes = MAX(elen, RNG_BYTES_DEFAULT);
}

void
linux_seed(void)
{
	long len;
	if (!rand_file)
		linux_seed_init();

	errno = 0;
	len = RAND_load_file(rand_file, rand_bytes);
	if (len != rand_bytes) {
		if (errno)
			fatal ("cannot read from %s, %s", rand_file, strerror(errno));
		else
			fatal ("EOF reading %s", rand_file);
	}
}
