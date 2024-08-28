/*
 * Copyright (c) 2012-2014 Petr Cerny.  All rights reserved.
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
#ifndef FIPS_H
#define FIPS_H

#include "key.h"

#define SSH_FORCE_FIPS_ENV	"SSH_FORCE_FIPS"
#define FIPS_PROC_PATH		"/proc/sys/crypto/fips_enabled"
 
#define PROC_EXE_PATH_LEN	64
#define CHECKSUM_SUFFIX		".hmac"
#define FIPS_HMAC_KEY		"HMAC_KEY:OpenSSH-FIPS@SLE"
#define FIPS_HMAC_EVP		EVP_sha256
#define FIPS_HMAC_LEN		32

void	 fips_ssh_init(void);

typedef enum {
	FIPS_FILTER_CIPHERS,
	FIPS_FILTER_MACS,
	FIPS_FILTER_KEX_ALGS
} fips_filters;

typedef enum {
	CHECK_OK = 0,
	CHECK_FAIL,
	CHECK_MISSING
} fips_checksum_status;
 
int	 fips_mode(void);
int	 fips_correct_dgst(int);
int	 fips_dgst_min(void);
int	 fips_dh_grp_min(void);
enum fp_type	 fips_correct_fp_type(enum fp_type);
int	 fips_filter_crypto(char **, fips_filters);

#endif

