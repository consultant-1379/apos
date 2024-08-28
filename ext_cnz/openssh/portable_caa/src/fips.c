/*
 * Copyright (c) 2012 Petr Cerny.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "includes.h"

#include "fips.h"

#include "cipher.h"
#include "dh.h"
#include "digest.h"
#include "kex.h"
#include "key.h"
#include "mac.h"
#include "log.h"
#include "xmalloc.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/hmac.h>

/* import from dh.c */
extern int dh_grp_min;

static int fips_state = -1;

/* calculates HMAC of contents of a file given by filename using the hash
 * algorithm specified by FIPS_HMAC_EVP in fips.h and placing the result into
 * newly allacated memory - remember to free it when not needed anymore */
static int
hmac_file(const char *filename, u_char **hmac_out)
{
	int check = -1;
	int fd;
	struct stat fs;
	void *hmap;
	unsigned char *hmac;
	unsigned char *hmac_rv = NULL;

	hmac = xmalloc(FIPS_HMAC_LEN);

	fd = open(filename, O_RDONLY);
	if (-1 == fd)
		goto bail_out;

	if (-1 == fstat(fd, &fs))
		goto bail_out;

	hmap = mmap(NULL, fs.st_size, PROT_READ, MAP_SHARED, fd, 0);

	if ((void *)(-1) != hmap) {
		hmac_rv = HMAC(FIPS_HMAC_EVP(), FIPS_HMAC_KEY
		    , strlen(FIPS_HMAC_KEY), hmap, fs.st_size, hmac, NULL);
		check = CHECK_OK;
		munmap(hmap, fs.st_size);
	}
	close(fd);

bail_out:
	if (hmac_rv) {
		check = CHECK_OK;
		*hmac_out = hmac;
	} else {
		check = CHECK_FAIL;
		*hmac_out = NULL;
		free(hmac);
	}
	return check;
}

/* find pathname of binary of process with PID pid. exe is buffer expected to
 * be capable of holding at least max_pathlen characters 
 */
static int
get_executable_path(pid_t pid, char *exe, int max_pathlen)
{
	char exe_sl[PROC_EXE_PATH_LEN];
	int n;
	int rv = -1;

	n = snprintf(exe_sl, sizeof(exe_sl), "/proc/%u/exe", pid);
	if ((n <= 10) || (n >= max_pathlen)) {
		fatal("error compiling filename of link to executable");
	}

	exe[0] = 0;
	n = readlink(exe_sl, exe, max_pathlen);
	/* the file doesn't need to exist - procfs might not be mounted in
	 * chroot */
	if (n == -1) {
		rv = CHECK_MISSING;
	} else {
		if (n < max_pathlen) {
			exe[n] = 0;
			rv = CHECK_OK;
		} else {
			rv = CHECK_FAIL;
		}
	}
	return rv;
}

/* Read HMAC from file chk, allocating enough memory to hold the HMAC and
 * return it in *hmac.
 * Remember to free() it when it's not needed anymore.
 */
static int
read_hmac(const char *chk, u_char **hmac)
{
	int check = -1;
	int fdh, n;
	u_char *hmac_in;

	*hmac = NULL;

	fdh = open(chk, O_RDONLY);
	if (-1 == fdh) {
		switch (errno) {
			case ENOENT:
				check = CHECK_MISSING;
				debug("fips: checksum file %s is missing\n", chk);
				break;
			default:
				check = CHECK_FAIL;
				debug("fips: ckecksum file %s not accessible\n", chk);
				break;

		}
		goto bail_out;
	}

	hmac_in = xmalloc(FIPS_HMAC_LEN);

	n = read(fdh, (void *)hmac_in, FIPS_HMAC_LEN);
	if (FIPS_HMAC_LEN != n) {
		debug("fips: unable to read whole checksum from checksum file\n");
		free (hmac_in);
		check = CHECK_FAIL;
	} else {
		check = CHECK_OK;
		*hmac = hmac_in;
	}
bail_out:
	return check;
}

static int
fips_hmac_self(void)
{
	int check = -1;
	u_char *hmac = NULL, *hmac_chk = NULL;
	char *exe, *chk;
	
	exe = xmalloc(PATH_MAX);
	chk = xmalloc(PATH_MAX);

	/* we will need to add the suffix and the null terminator */
	check = get_executable_path(getpid(), exe
		    , PATH_MAX - strlen(CHECKSUM_SUFFIX) - 1);
	if (CHECK_OK != check)
		goto cleanup;

	strncpy(chk, exe, PATH_MAX);
	strlcat(chk, CHECKSUM_SUFFIX, PATH_MAX);

	check = read_hmac(chk, &hmac_chk);
	if (CHECK_OK != check)
		goto cleanup;

	check = hmac_file(exe, &hmac);
	if (CHECK_OK != check)
		goto cleanup;

	check = memcmp(hmac, hmac_chk, FIPS_HMAC_LEN);
	if (0 == check) {
		check = CHECK_OK;
		debug("fips: checksum matches\n");
	} else {
		check = CHECK_FAIL;
		debug("fips: checksum mismatch!\n");
	}

cleanup:
	free(hmac);
	free(hmac_chk);
	free(chk);
	free(exe);

	return check;
}

static int
fips_check_required_proc(void)
{
	int fips_required = 0;
	int fips_fd;
	char fips_sys = 0;

	struct stat dummy;
	if (-1 == stat(FIPS_PROC_PATH, &dummy)) {
		switch (errno) {
			case ENOENT:
			case ENOTDIR:
				break;
			default:
				fatal("Check for system-wide FIPS mode is required and %s cannot"
				    " be accessed for reason other than non-existence - aborting"
				    , FIPS_PROC_PATH);
				break;
		}
	} else {
		if (-1 == (fips_fd = open(FIPS_PROC_PATH, O_RDONLY)))
			fatal("Check for system-wide FIPS mode is required and %s cannot"
			    " be opened for reading - aborting"
			    , FIPS_PROC_PATH);
		if (1 > read(fips_fd, &fips_sys, 1)) {
			close(fips_fd);
			fatal("Check for system-wide FIPS mode is required and %s doesn't"
			    " return at least one character - aborting"
			    , FIPS_PROC_PATH);
		}
		close(fips_fd);
		switch (fips_sys) {
			case '0':
			case '1':
				fips_required = fips_sys - '0';
				break;
			default:
				fatal("Bogus character %c found in %s - aborting"
				    , fips_sys, FIPS_PROC_PATH);
		}
	}
	return fips_required;
}

static int
fips_check_required_env(void)
{
	return (NULL != getenv(SSH_FORCE_FIPS_ENV));
}

static int
fips_required(void)
{
	int fips_requests = 0;
	fips_requests += fips_check_required_proc();
	fips_requests += fips_check_required_env();
	return fips_requests;
}

/* check whether FIPS mode is required and perform selfchecksum/selftest */
void
fips_ssh_init(void)
{
	int checksum;

	checksum = fips_hmac_self();

	if (fips_required()) {
		switch (checksum) {
			case CHECK_OK:
				debug("fips: mandatory checksum ok");
				break;
			case CHECK_FAIL:
				fatal("fips: mandatory checksum failed - aborting");
				break;
			case CHECK_MISSING:
				fatal("fips: mandatory checksum data missing - aborting");
				break;
			default:
				fatal("Fatal error: internal error at %s:%u"
				    , __FILE__, __LINE__);
				break;
		}
		fips_state = FIPS_mode_set(1);
		if (1 != fips_state) {
			ERR_load_crypto_strings();
			u_long err = ERR_get_error();
			error("fips: OpenSSL error %lx: %s"
			    , err, ERR_error_string(err, NULL));
			fatal("fips: unable to set OpenSSL into FIPS mode - aborting");
		}
	} else {
		switch (checksum) {
			case CHECK_OK:
				debug("fips: checksum ok");
				break;
			case CHECK_FAIL:
				fatal("fips: checksum failed - aborting");
				break;
			case CHECK_MISSING:
				debug("fips: checksum data missing, but not required - continuing non-FIPS");
				break;
			default:
				fatal("Fatal error: internal error at %s:%u",
				    __FILE__, __LINE__);
				break;
		}
 	}
	return;
}

int
fips_mode(void)
{
	if (-1 == fips_state) {
		fips_state = FIPS_mode();
		if (fips_state)
			debug("FIPS mode initialized");
		else {
			if (fips_check_required_env()) {
				debug("FIPS mode requested through the environment variable '%s'"
				    , SSH_FORCE_FIPS_ENV);
				if (!FIPS_mode_set(1))
					fatal("Unable to enter FIPS mode as requested through the environment variable '%s'"
					    , SSH_FORCE_FIPS_ENV);
				fips_state = 1;
			}
		}
	}
	return fips_state;
}

int
fips_correct_dgst(int digest)
{
	int fips;
	int rv = -1;

	fips = fips_mode();
	switch (fips) {
		case 0:
			rv = digest;
			break;
		case 1:
			switch (digest) {
				case SSH_DIGEST_MD5:
				case SSH_DIGEST_RIPEMD160:
					debug("MD5/RIPEMD160 digests not allowed in FIPS 140-2 mode"
					    "using SHA-256 instead.");
					rv = SSH_DIGEST_SHA256;
					break;
				default:
					rv = digest;
					break;
			}
			break;
		default:
			/* should not be reached */
			fatal("Fatal error: incorrect FIPS mode '%i' at %s:%u",
			    fips, __FILE__, __LINE__);
	}

	return rv;
}

/*
 * filter out FIPS disallowed algorithms
 * *crypto MUST be free()-able - it is assigned newly allocated memory and
 * the previous one is freed
 *
 * returns zero if all algorithms were rejected, non-zero otherwise
 */
int
fips_filter_crypto(char **crypto, fips_filters filter)
{
	char *token, *tmp, *tmp_sav, *new;
	int plus = 0;
	int valid;
	int comma = 0;
	int empty = 1;
	size_t len;

	tmp = tmp_sav = xstrdup(*crypto);

	len = strlen(tmp) + 1;
	new = xcalloc(1, len);

	if ('+' == *tmp) {
		plus = 1;
		tmp++;
	}

	while ((token = strsep(&tmp, ",")) != NULL) {
		switch(filter) {
			case FIPS_FILTER_CIPHERS:
				valid = ciphers_valid(token);
				if (!valid)
					debug("Cipher '%s' is not allowed in FIPS mode",
					    token);
				break;
			case FIPS_FILTER_MACS:
				valid = mac_valid(token);
				if (!valid)
					debug("MAC '%s' is not allowed in FIPS mode",
					    token);
				break;
			case FIPS_FILTER_KEX_ALGS:
				valid = kex_names_valid(token);
				if (!valid)
					debug("KEX '%s' is not allowed in FIPS mode",
					    token);
				break;
			default:
				/* should not be reached */
				fatal("Fatal error: incorrect FIPS filter '%i' requested at %s:%u",
				    filter, __FILE__, __LINE__);
		}

		if (valid) {
			empty = 0;
			if (plus) {
				strlcat(new, "+", len);
				plus = 0;
			}
			if (comma)
				strlcat(new, ",", len);
			else
				comma = 1;
			strlcat(new, token, len);
		}
	}

	/* free tmp and re-allocate shorter buffer for result if necessary */
	free(tmp_sav);
	free(*crypto);
	*crypto = new;

	return (!empty);
}

int
fips_dgst_min(void)
{
	int fips;
	int dgst;

	fips = fips_mode();
	switch (fips) {
		case 0:
			dgst = SSH_DIGEST_MD5;
			break;
		case 1:
			dgst = SSH_DIGEST_SHA1;
			break;
		default:
			/* should not be reached */
			fatal("Fatal error: incorrect FIPS mode '%i' at %s:%u",
			    fips, __FILE__, __LINE__);
	}
	return dgst;
}

int
fips_dh_grp_min(void)
{
	int fips;
	int dh;

	fips = fips_mode();
	switch (fips) {
		case 0:
			dh = dh_grp_min;
			break;
		case 1:
			dh = DH_GRP_MIN_FIPS;
			break;
		default:
			/* should not be reached */
			fatal("Fatal error: incorrect FIPS mode '%i' at %s:%u",
			    fips, __FILE__, __LINE__);
	}
	return dh;
}

