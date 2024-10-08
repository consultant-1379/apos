/* $OpenBSD: sshd.c,v 1.465 2016/02/15 09:47:49 dtucker Exp $ */
/*
 * Author: Tatu Ylonen <ylo@cs.hut.fi>
 * Copyright (c) 1995 Tatu Ylonen <ylo@cs.hut.fi>, Espoo, Finland
 *                    All rights reserved
 * This program is the ssh daemon.  It listens for connections from clients,
 * and performs authentication, executes use commands or shell, and forwards
 * information to/from the application to the user client over an encrypted
 * connection.  This can also handle forwarding of X11, TCP/IP, and
 * authentication agent connections.
 *
 * As far as I am concerned, the code I have written for this software
 * can be used freely for any purpose.  Any derived versions of this
 * software must be clearly marked as such, and if the derived work is
 * incompatible with the protocol description in the RFC file, it must be
 * called by a name other than "ssh" or "Secure Shell".
 *
 * SSH2 implementation:
 * Privilege Separation:
 *
 * Copyright (c) 2000, 2001, 2002 Markus Friedl.  All rights reserved.
 * Copyright (c) 2002 Niels Provos.  All rights reserved.
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

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#ifdef HAVE_SYS_TIME_H
# include <sys/time.h>
#endif
#include "openbsd-compat/sys-tree.h"
#include "openbsd-compat/sys-queue.h"
#include "openbsd-compat/port-linux.h"

#include <sys/wait.h>

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#ifdef HAVE_PATHS_H
#include <paths.h>
#endif
#include <grp.h>
#include <pwd.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

#ifdef WITH_OPENSSL
#include <openssl/dh.h>
#include <openssl/bn.h>
#include <openssl/rand.h>
#include "openbsd-compat/openssl-compat.h"
#endif

#ifdef HAVE_SECUREWARE
#include <sys/security.h>
#include <prot.h>
#endif

#ifdef HAVE_SYSTEMD
#include <systemd/sd-daemon.h>
#endif

#include "xmalloc.h"
#include "ssh.h"
#include "ssh1.h"
#include "ssh2.h"
#include "rsa.h"
#include "sshpty.h"
#include "packet.h"
#include "log.h"
#include "buffer.h"
#include "misc.h"
#include "match.h"
#include "servconf.h"
#include "uidswap.h"
#include "compat.h"
#include "cipher.h"
#include "digest.h"
#include "key.h"
#include "kex.h"
#include "myproposal.h"
#include "authfile.h"
#include "pathnames.h"
#include "atomicio.h"
#include "canohost.h"
#include "hostfile.h"
#include "auth.h"
#include "authfd.h"
#include "msg.h"
#include "dispatch.h"
#include "channels.h"
#include "session.h"
#include "monitor.h"
#ifdef GSSAPI
#include "ssh-gss.h"
#endif
#include "monitor_wrap.h"
#include "audit.h"
#include "ssh-sandbox.h"
#include "version.h"
#include "ssherr.h"

#include "fips.h"

#ifdef USE_SECURITY_SESSION_API
#include <Security/AuthSession.h>
#endif

#ifdef LIBWRAP
#include <tcpd.h>
#include <syslog.h>
int allow_severity;
int deny_severity;
#endif /* LIBWRAP */

#ifndef O_NOCTTY
#define O_NOCTTY	0
#endif

/* Re-exec fds */
#define REEXEC_DEVCRYPTO_RESERVED_FD	(STDERR_FILENO + 1)
#define REEXEC_STARTUP_PIPE_FD		(STDERR_FILENO + 2)
#define REEXEC_CONFIG_PASS_FD		(STDERR_FILENO + 3)
#define REEXEC_MIN_FREE_FD		(STDERR_FILENO + 4)

extern char *__progname;

/* Server configuration options. */
ServerOptions options;

/* Name of the server configuration file. */
char *config_file_name = _PATH_SERVER_CONFIG_FILE;

/*
 * Debug mode flag.  This can be set on the command line.  If debug
 * mode is enabled, extra debugging output will be sent to the system
 * log, the daemon will not go to background, and will exit after processing
 * the first connection.
 */
int debug_flag = 0;

/* Flag indicating that the daemon should only test the configuration and keys. */
int test_flag = 0;

/* Flag indicating that the daemon is being started from inetd. */
int inetd_flag = 0;

/* Flag indicating that sshd should not detach and become a daemon. */
int no_daemon_flag = 0;

/* debug goes to stderr unless inetd_flag is set */
int log_stderr = 0;

/* Saved arguments to main(). */
char **saved_argv;
int saved_argc;

/* re-exec */
int rexeced_flag = 0;
int rexec_flag = 1;
int rexec_argc = 0;
char **rexec_argv;

/*
 * The sockets that the server is listening; this is used in the SIGHUP
 * signal handler.
 */
#define	MAX_LISTEN_SOCKS	20
int listen_socks[MAX_LISTEN_SOCKS];
int num_listen_socks = 0;

/*
 * the client's version string, passed by sshd2 in compat mode. if != NULL,
 * sshd will skip the version-number exchange
 */
char *client_version_string = NULL;
char *server_version_string = NULL;

/* Daemon's agent connection */
int auth_sock = -1;
int have_agent = 0;

/*
 * Any really sensitive data in the application is contained in this
 * structure. The idea is that this structure could be locked into memory so
 * that the pages do not get written into swap.  However, there are some
 * problems. The private key contains BIGNUMs, and we do not (in principle)
 * have access to the internals of them, and locking just the structure is
 * not very useful.  Currently, memory locking is not implemented.
 */
struct {
	Key	*server_key;		/* ephemeral server key */
	Key	*ssh1_host_key;		/* ssh1 host key */
	Key	**host_keys;		/* all private host keys */
	Key	**host_pubkeys;		/* all public host keys */
	Key	**host_certificates;	/* all public host certificates */
	int	have_ssh1_key;
	int	have_ssh2_key;
	u_char	ssh1_cookie[SSH_SESSION_KEY_LENGTH];
} sensitive_data;

/*
 * Every RESEED_AFTERth connection triggers call to linux_seed() to re-seed the
 * random pool.
 */
#define RESEED_AFTER    100
static int re_seeding_counter = RESEED_AFTER;

/*
 * Flag indicating whether the RSA server key needs to be regenerated.
 * Is set in the SIGALRM handler and cleared when the key is regenerated.
 */
static volatile sig_atomic_t key_do_regen = 0;

/* This is set to true when a signal is received. */
static volatile sig_atomic_t received_sighup = 0;
static volatile sig_atomic_t received_sigterm = 0;

/* session identifier, used by RSA-auth */
u_char session_id[16];

/* same for ssh2 */
u_char *session_id2 = NULL;
u_int session_id2_len = 0;

/* record remote hostname or ip */
u_int utmp_len = HOST_NAME_MAX+1;

/*
 * startup_pipes/flags are used for tracking children of the listening sshd
 * process early in their lifespans. This tracking is needed for three things:
 *
 * 1) Implementing the MaxStartups limit of concurrent unauthenticated
 *    connections.
 * 2) Avoiding a race condition for SIGHUP processing, where child processes
 *    may have listen_socks open that could collide with main listener process
 *    after it restarts.
 * 3) Ensuring that rexec'd sshd processes have received their initial state
 *    from the parent listen process before handling SIGHUP.
 *
 * Child processes signal that they have completed closure of the listen_socks
 * and (if applicable) received their rexec state by sending a char over their
 * sock. Child processes signal that authentication has completed by closing
 * the sock (or by exiting).
 */
static int *startup_pipes = NULL;
static int *startup_flags = NULL;	/* Indicates child closed listener */
static int startup_pipe = -1;		/* in child */

/* variables used for privilege separation */
int use_privsep = -1;
struct monitor *pmonitor = NULL;
int privsep_is_preauth = 1;

/* global authentication context */
Authctxt *the_authctxt = NULL;

/* sshd_config buffer */
Buffer cfg;

/* message to be displayed after login */
Buffer loginmsg;

/* Unprivileged user */
struct passwd *privsep_pw = NULL;

/* Prototypes for various functions defined later in this file. */
void destroy_sensitive_data(int);
void demote_sensitive_data(void);

#ifdef WITH_SSH1
static void do_ssh1_kex(void);
#endif
static void do_ssh2_kex(void);

/*
 * Close all listening sockets
 */
static void
close_listen_socks(void)
{
	int i;

	for (i = 0; i < num_listen_socks; i++)
		close(listen_socks[i]);
	num_listen_socks = -1;
}

/*
 * Is this process listening for clients (i.e. not specific to any specific
 * client connection?)
 */
int listening_for_clients(void)
{
	return num_listen_socks > 0;
}

static void
close_startup_pipes(void)
{
	int i;

	if (startup_pipes)
		for (i = 0; i < options.max_startups; i++)
			if (startup_pipes[i] != -1)
				close(startup_pipes[i]);
}

/*
 * Signal handler for SIGHUP.  Sshd execs itself when it receives SIGHUP;
 * the effect is to reread the configuration file (and to regenerate
 * the server key).
 */

/*ARGSUSED*/
static void
sighup_handler(int sig)
{
	int save_errno = errno;

	received_sighup = 1;
	signal(SIGHUP, sighup_handler);
	errno = save_errno;
}

/*
 * Called from the main program after receiving SIGHUP.
 * Restarts the server.
 */
static void
sighup_restart(void)
{
#ifdef HAVE_SYSTEMD
	/* Signal systemd that we are reloading */
	sd_notify(0, "RELOADING=1");
#endif
	logit("Received SIGHUP; restarting.");
	platform_pre_restart();
	close_listen_socks();
	close_startup_pipes();
	alarm(0);  /* alarm timer persists across exec */
	signal(SIGHUP, SIG_IGN); /* will be restored after exec */
	execv(saved_argv[0], saved_argv);
	logit("RESTART FAILED: av[0]='%.100s', error: %.100s.", saved_argv[0],
	    strerror(errno));
	exit(1);
}

/*
 * Generic signal handler for terminating signals in the master daemon.
 */
/*ARGSUSED*/
static void
sigterm_handler(int sig)
{
	received_sigterm = sig;
}

/*
 * SIGCHLD handler.  This is called whenever a child dies.  This will then
 * reap any zombies left by exited children.
 */
/*ARGSUSED*/
static void
main_sigchld_handler(int sig)
{
	int save_errno = errno;
	pid_t pid;
	int status;

	while ((pid = waitpid(-1, &status, WNOHANG)) > 0 ||
	    (pid < 0 && errno == EINTR))
		;

	signal(SIGCHLD, main_sigchld_handler);
	errno = save_errno;
}

/*
 * Signal handler for the alarm after the login grace period has expired.
 */
/*ARGSUSED*/
static void
grace_alarm_handler(int sig)
{
	if (use_privsep && pmonitor != NULL && pmonitor->m_pid > 0)
		kill(pmonitor->m_pid, SIGALRM);

	/*
	 * Try to kill any processes that we have spawned, E.g. authorized
	 * keys command helpers.
	 */
	if (getpgid(0) == getpid()) {
		signal(SIGTERM, SIG_IGN);
		kill(0, SIGTERM);
	}

	/* Log error and exit. */
	sigdie("Timeout before authentication for %s", get_remote_ipaddr());
}

/*
 * Signal handler for the key regeneration alarm.  Note that this
 * alarm only occurs in the daemon waiting for connections, and it does not
 * do anything with the private key or random state before forking.
 * Thus there should be no concurrency control/asynchronous execution
 * problems.
 */
static void
generate_ephemeral_server_key(void)
{
	verbose("Generating %s%d bit RSA key.",
	    sensitive_data.server_key ? "new " : "", options.server_key_bits);
	if (sensitive_data.server_key != NULL)
		key_free(sensitive_data.server_key);
	sensitive_data.server_key = key_generate(KEY_RSA1,
	    options.server_key_bits);
	verbose("RSA key generation complete.");

	arc4random_buf(sensitive_data.ssh1_cookie, SSH_SESSION_KEY_LENGTH);
}

/*ARGSUSED*/
static void
key_regeneration_alarm(int sig)
{
	int save_errno = errno;

	signal(SIGALRM, SIG_DFL);
	errno = save_errno;
	key_do_regen = 1;
}

static void
sshd_exchange_identification(int sock_in, int sock_out)
{
	u_int i;
	int mismatch;
	int remote_major, remote_minor;
	int major, minor;
	char *s, *newline = "\n";
	char buf[256];			/* Must not be larger than remote_version. */
	char remote_version[256];	/* Must be at least as big as buf. */

	if ((options.protocol & SSH_PROTO_1) &&
	    (options.protocol & SSH_PROTO_2)) {
		major = PROTOCOL_MAJOR_1;
		minor = 99;
	} else if (options.protocol & SSH_PROTO_2) {
		major = PROTOCOL_MAJOR_2;
		minor = PROTOCOL_MINOR_2;
		newline = "\r\n";
	} else {
		major = PROTOCOL_MAJOR_1;
		minor = PROTOCOL_MINOR_1;
	}

	xasprintf(&server_version_string, "SSH-%d.%d-%.100s%s%s%s",
	    major, minor, SSH_VERSION,
	    *options.version_addendum == '\0' ? "" : " ",
	    options.version_addendum, newline);

	/* Send our protocol version identification. */
	if (atomicio(vwrite, sock_out, server_version_string,
	    strlen(server_version_string))
	    != strlen(server_version_string)) {
		logit("Could not write ident string to %s", get_remote_ipaddr());
		cleanup_exit(255);
	}

	/* Read other sides version identification. */
	memset(buf, 0, sizeof(buf));
	for (i = 0; i < sizeof(buf) - 1; i++) {
		if (atomicio(read, sock_in, &buf[i], 1) != 1) {
			logit("Did not receive identification string from %s",
			    get_remote_ipaddr());
			cleanup_exit(255);
		}
		if (buf[i] == '\r') {
			buf[i] = 0;
			/* Kludge for F-Secure Macintosh < 1.0.2 */
			if (i == 12 &&
			    strncmp(buf, "SSH-1.5-W1.0", 12) == 0)
				break;
			continue;
		}
		if (buf[i] == '\n') {
			buf[i] = 0;
			break;
		}
	}
	buf[sizeof(buf) - 1] = 0;
	client_version_string = xstrdup(buf);

	/*
	 * Check that the versions match.  In future this might accept
	 * several versions and set appropriate flags to handle them.
	 */
	if (sscanf(client_version_string, "SSH-%d.%d-%[^\n]\n",
	    &remote_major, &remote_minor, remote_version) != 3) {
		s = "Protocol mismatch.\n";
		(void) atomicio(vwrite, sock_out, s, strlen(s));
		logit("Bad protocol version identification '%.100s' "
		    "from %s port %d", client_version_string,
		    get_remote_ipaddr(), get_remote_port());
		close(sock_in);
		close(sock_out);
		cleanup_exit(255);
	}
	debug("Client protocol version %d.%d; client software version %.100s",
	    remote_major, remote_minor, remote_version);

	active_state->compat = compat_datafellows(remote_version);

	if ((datafellows & SSH_BUG_PROBE) != 0) {
		logit("probed from %s with %s.  Don't panic.",
		    get_remote_ipaddr(), client_version_string);
		cleanup_exit(255);
	}
	if ((datafellows & SSH_BUG_SCANNER) != 0) {
		logit("scanned from %s with %s.  Don't panic.",
		    get_remote_ipaddr(), client_version_string);
		cleanup_exit(255);
	}
	if ((datafellows & SSH_BUG_RSASIGMD5) != 0) {
		logit("Client version \"%.100s\" uses unsafe RSA signature "
		    "scheme; disabling use of RSA keys", remote_version);
	}
	if ((datafellows & SSH_BUG_DERIVEKEY) != 0) {
		fatal("Client version \"%.100s\" uses unsafe key agreement; "
		    "refusing connection", remote_version);
	}

	mismatch = 0;
	switch (remote_major) {
	case 1:
		if (remote_minor == 99) {
			if (options.protocol & SSH_PROTO_2)
				enable_compat20();
			else
				mismatch = 1;
			break;
		}
		if (!(options.protocol & SSH_PROTO_1)) {
			mismatch = 1;
			break;
		}
		if (remote_minor < 3) {
			packet_disconnect("Your ssh version is too old and "
			    "is no longer supported.  Please install a newer version.");
		} else if (remote_minor == 3) {
			/* note that this disables agent-forwarding */
			enable_compat13();
		}
		break;
	case 2:
		if (options.protocol & SSH_PROTO_2) {
			enable_compat20();
			break;
		}
		/* FALLTHROUGH */
	default:
		mismatch = 1;
		break;
	}
	chop(server_version_string);
	debug("Local version string %.200s", server_version_string);

	if (mismatch) {
		s = "Protocol major versions differ.\n";
		(void) atomicio(vwrite, sock_out, s, strlen(s));
		close(sock_in);
		close(sock_out);
		logit("Protocol major versions differ for %s: %.200s vs. %.200s",
		    get_remote_ipaddr(),
		    server_version_string, client_version_string);
		cleanup_exit(255);
	}
}

/*
 * Destroy the host and server keys.  They will no longer be needed.  Careful,
 * this can be called from cleanup_exit() - i.e. from just about anywhere.
 */
void
destroy_sensitive_data(int privsep)
{
	int i;
#ifdef SSH_AUDIT_EVENTS
	pid_t pid;
	uid_t uid;

	pid = getpid();
	uid = getuid();
#endif
	if (sensitive_data.server_key) {
		key_free(sensitive_data.server_key);
		sensitive_data.server_key = NULL;
	}
	for (i = 0; i < options.num_host_key_files; i++) {
		if (sensitive_data.host_keys[i]) {
			char *fp;

			if (key_is_private(sensitive_data.host_keys[i]))
				fp = sshkey_fingerprint(sensitive_data.host_keys[i], options.fingerprint_hash, SSH_FP_HEX);
			else
				fp = NULL;
			key_free(sensitive_data.host_keys[i]);
			sensitive_data.host_keys[i] = NULL;
			if (fp != NULL) {
#ifdef SSH_AUDIT_EVENTS
				if (privsep)
					PRIVSEP(audit_destroy_sensitive_data(fp,
						pid, uid));
				else
					audit_destroy_sensitive_data(fp,
						pid, uid);
#endif
				free(fp);
			}
		}
		if (sensitive_data.host_certificates
		    && sensitive_data.host_certificates[i]) {
			key_free(sensitive_data.host_certificates[i]);
			sensitive_data.host_certificates[i] = NULL;
		}
	}
	sensitive_data.ssh1_host_key = NULL;
	explicit_bzero(sensitive_data.ssh1_cookie, SSH_SESSION_KEY_LENGTH);
}

/* Demote private to public keys for network child */
void
demote_sensitive_data(void)
{
	Key *tmp;
	int i;
#ifdef SSH_AUDIT_EVENTS
	pid_t pid;
	uid_t uid;

	pid = getpid();
	uid = getuid();
#endif
	if (sensitive_data.server_key) {
		tmp = key_demote(sensitive_data.server_key);
		key_free(sensitive_data.server_key);
		sensitive_data.server_key = tmp;
	}

	for (i = 0; i < options.num_host_key_files; i++) {
		if (sensitive_data.host_keys[i]) {
			char *fp;

			if (key_is_private(sensitive_data.host_keys[i]))
				fp = sshkey_fingerprint(sensitive_data.host_keys[i], options.fingerprint_hash, SSH_FP_HEX);
			else
				fp = NULL;
			tmp = key_demote(sensitive_data.host_keys[i]);
			key_free(sensitive_data.host_keys[i]);
			sensitive_data.host_keys[i] = tmp;
			if (tmp->type == KEY_RSA1)
				sensitive_data.ssh1_host_key = tmp;
			if (fp != NULL) {
#ifdef SSH_AUDIT_EVENTS
				audit_destroy_sensitive_data(fp, pid, uid);
#endif
				free(fp);
			}
		}
		/* Certs do not need demotion */
	}

	/* We do not clear ssh1_host key and cookie.  XXX - Okay Niels? */
}

static void
privsep_preauth_child(void)
{
	u_int32_t rnd[256];
	gid_t gidset[1];

	/* Enable challenge-response authentication for privilege separation */
	privsep_challenge_enable();

#ifdef GSSAPI
	/* Cache supported mechanism OIDs for later use */
	if (options.gss_authentication)
		ssh_gssapi_prepare_supported_oids();
#endif

	arc4random_stir();
	arc4random_buf(rnd, sizeof(rnd));
#ifdef WITH_OPENSSL
	RAND_seed(rnd, sizeof(rnd));
	if ((RAND_bytes((u_char *)rnd, 1)) != 1)
		fatal("%s: RAND_bytes failed", __func__);
#endif
	explicit_bzero(rnd, sizeof(rnd));

	/* Demote the private keys to public keys. */
	demote_sensitive_data();

	/* Demote the child */
	if (getuid() == 0 || geteuid() == 0) {
		/* Change our root directory */
		if (chroot(_PATH_PRIVSEP_CHROOT_DIR) == -1)
			fatal("chroot(\"%s\"): %s", _PATH_PRIVSEP_CHROOT_DIR,
			    strerror(errno));
		if (chdir("/") == -1)
			fatal("chdir(\"/\"): %s", strerror(errno));

		/* Drop our privileges */
		debug3("privsep user:group %u:%u", (u_int)privsep_pw->pw_uid,
		    (u_int)privsep_pw->pw_gid);
		gidset[0] = privsep_pw->pw_gid;
		if (setgroups(1, gidset) < 0)
			fatal("setgroups: %.100s", strerror(errno));
		permanently_set_uid(privsep_pw);
	}
}

static int
privsep_preauth(Authctxt *authctxt)
{
	int status, r;
	pid_t pid;
	struct ssh_sandbox *box = NULL;

	/* Set up unprivileged child process to deal with network data */
	pmonitor = monitor_init();
	/* Store a pointer to the kex for later rekeying */
	pmonitor->m_pkex = &active_state->kex;

	if (use_privsep == PRIVSEP_ON)
		box = ssh_sandbox_init(pmonitor);
	pid = fork();
	if (pid == -1) {
		fatal("fork of unprivileged child failed");
	} else if (pid != 0) {
		debug2("Network child is on pid %ld", (long)pid);

		pmonitor->m_pid = pid;
		if (have_agent) {
			r = ssh_get_authentication_socket(&auth_sock);
			if (r != 0) {
				error("Could not get agent socket: %s",
				    ssh_err(r));
				have_agent = 0;
			}
		}
		if (box != NULL)
			ssh_sandbox_parent_preauth(box, pid);
		monitor_child_preauth(authctxt, pmonitor);

		/* Wait for the child's exit status */
		while (waitpid(pid, &status, 0) < 0) {
			if (errno == EINTR)
				continue;
			pmonitor->m_pid = -1;
			fatal("%s: waitpid: %s", __func__, strerror(errno));
		}
		privsep_is_preauth = 0;
		pmonitor->m_pid = -1;
		if (WIFEXITED(status)) {
			if (WEXITSTATUS(status) != 0)
				fatal("%s: preauth child exited with status %d",
				    __func__, WEXITSTATUS(status));
		} else if (WIFSIGNALED(status))
			fatal("%s: preauth child terminated by signal %d",
			    __func__, WTERMSIG(status));
		if (box != NULL)
			ssh_sandbox_parent_finish(box);
		return 1;
	} else {
		/* child */
		close(pmonitor->m_sendfd);
		close(pmonitor->m_log_recvfd);

		/* Arrange for logging to be sent to the monitor */
		set_log_handler(mm_log_handler, pmonitor);

		privsep_preauth_child();
		setproctitle("%s", "[net]");
		if (box != NULL)
			ssh_sandbox_child(box);

		return 0;
	}
}

static void
privsep_postauth(Authctxt *authctxt)
{
	u_int32_t rnd[256];

#ifdef DISABLE_FD_PASSING
	if (1) {
#else
	if (authctxt->pw->pw_uid == 0 || options.use_login) {
#endif
		/* File descriptor passing is broken or root login */
		use_privsep = 0;
		goto skip;
	}

	/* New socket pair */
	monitor_reinit(pmonitor);

	pmonitor->m_pid = fork();
	if (pmonitor->m_pid == -1)
		fatal("fork of unprivileged child failed");
	else if (pmonitor->m_pid != 0) {
		verbose("User child is on pid %ld", (long)pmonitor->m_pid);
		buffer_clear(&loginmsg);
		if (*pmonitor->m_pkex != NULL ){
			newkeys_destroy((*pmonitor->m_pkex)->newkeys[MODE_OUT]);
			newkeys_destroy((*pmonitor->m_pkex)->newkeys[MODE_IN]);
			audit_session_key_free_body(2, getpid(), getuid());
			packet_destroy_all(0, 0);
		}
		monitor_child_postauth(pmonitor);

		/* NEVERREACHED */
		exit(0);
	}

	/* child */

	close(pmonitor->m_sendfd);
	pmonitor->m_sendfd = -1;

	/* Demote the private keys to public keys. */
	demote_sensitive_data();

	arc4random_stir();
	arc4random_buf(rnd, sizeof(rnd));
#ifdef WITH_OPENSSL
	RAND_seed(rnd, sizeof(rnd));
	if ((RAND_bytes((u_char *)rnd, 1)) != 1)
		fatal("%s: RAND_bytes failed", __func__);
#endif
	explicit_bzero(rnd, sizeof(rnd));

	/* Drop privileges */
	do_setusercontext(authctxt->pw);

 skip:
	/* It is safe now to apply the key state */
	monitor_apply_keystate(pmonitor);

	/*
	 * Tell the packet layer that authentication was successful, since
	 * this information is not part of the key state.
	 */
	packet_set_authenticated();
}

static char *
list_hostkey_types(void)
{
	Buffer b;
	const char *p;
	char *ret;
	int i;
	Key *key;

	buffer_init(&b);
	for (i = 0; i < options.num_host_key_files; i++) {
		key = sensitive_data.host_keys[i];
		if (key == NULL)
			key = sensitive_data.host_pubkeys[i];
		if (key == NULL || key->type == KEY_RSA1)
			continue;
		/* Check that the key is accepted in HostkeyAlgorithms */
		if (match_pattern_list(sshkey_ssh_name(key),
		    options.hostkeyalgorithms, 0) != 1) {
			debug3("%s: %s key not permitted by HostkeyAlgorithms",
			    __func__, sshkey_ssh_name(key));
			continue;
		}
		switch (key->type) {
		case KEY_RSA:
		case KEY_DSA:
		case KEY_ECDSA:
		case KEY_ED25519:
			if (buffer_len(&b) > 0)
				buffer_append(&b, ",", 1);
			p = key_ssh_name(key);
			buffer_append(&b, p, strlen(p));

			/* for RSA we also support SHA2 signatures */
			if (key->type == KEY_RSA) {
				p = ",rsa-sha2-512,rsa-sha2-256";
				buffer_append(&b, p, strlen(p));
			}
			break;
		}
		/* If the private key has a cert peer, then list that too */
		key = sensitive_data.host_certificates[i];
		if (key == NULL)
			continue;
		switch (key->type) {
		case KEY_RSA_CERT:
		case KEY_DSA_CERT:
		case KEY_ECDSA_CERT:
		case KEY_ED25519_CERT:
			if (buffer_len(&b) > 0)
				buffer_append(&b, ",", 1);
			p = key_ssh_name(key);
			buffer_append(&b, p, strlen(p));
			break;
		}
	}
	buffer_append(&b, "\0", 1);
	ret = xstrdup(buffer_ptr(&b));
	buffer_free(&b);
	debug("list_hostkey_types: %s", ret);
	return ret;
}

static Key *
get_hostkey_by_type(int type, int nid, int need_private, struct ssh *ssh)
{
	int i;
	Key *key;

	for (i = 0; i < options.num_host_key_files; i++) {
		switch (type) {
		case KEY_RSA_CERT:
		case KEY_DSA_CERT:
		case KEY_ECDSA_CERT:
		case KEY_ED25519_CERT:
			key = sensitive_data.host_certificates[i];
			break;
		default:
			key = sensitive_data.host_keys[i];
			if (key == NULL && !need_private)
				key = sensitive_data.host_pubkeys[i];
			break;
		}
		if (key != NULL && key->type == type &&
		    (key->type != KEY_ECDSA || key->ecdsa_nid == nid))
			return need_private ?
			    sensitive_data.host_keys[i] : key;
	}
	return NULL;
}

Key *
get_hostkey_public_by_type(int type, int nid, struct ssh *ssh)
{
	return get_hostkey_by_type(type, nid, 0, ssh);
}

Key *
get_hostkey_private_by_type(int type, int nid, struct ssh *ssh)
{
	return get_hostkey_by_type(type, nid, 1, ssh);
}

Key *
get_hostkey_by_index(int ind)
{
	if (ind < 0 || ind >= options.num_host_key_files)
		return (NULL);
	return (sensitive_data.host_keys[ind]);
}

Key *
get_hostkey_public_by_index(int ind, struct ssh *ssh)
{
	if (ind < 0 || ind >= options.num_host_key_files)
		return (NULL);
	return (sensitive_data.host_pubkeys[ind]);
}

int
get_hostkey_index(Key *key, int compare, struct ssh *ssh)
{
	int i;

	for (i = 0; i < options.num_host_key_files; i++) {
		if (key_is_cert(key)) {
			if (key == sensitive_data.host_certificates[i] ||
			    (compare && sensitive_data.host_certificates[i] &&
			    sshkey_equal(key,
			    sensitive_data.host_certificates[i])))
				return (i);
		} else {
			if (key == sensitive_data.host_keys[i] ||
			    (compare && sensitive_data.host_keys[i] &&
			    sshkey_equal(key, sensitive_data.host_keys[i])))
				return (i);
			if (key == sensitive_data.host_pubkeys[i] ||
			    (compare && sensitive_data.host_pubkeys[i] &&
			    sshkey_equal(key, sensitive_data.host_pubkeys[i])))
				return (i);
		}
	}
	return (-1);
}

/* Inform the client of all hostkeys */
static void
notify_hostkeys(struct ssh *ssh)
{
	struct sshbuf *buf;
	struct sshkey *key;
	int i, nkeys, r;
	char *fp;

	/* Some clients cannot cope with the hostkeys message, skip those. */
	if (datafellows & SSH_BUG_HOSTKEYS)
		return;

	if ((buf = sshbuf_new()) == NULL)
		fatal("%s: sshbuf_new", __func__);
	for (i = nkeys = 0; i < options.num_host_key_files; i++) {
		key = get_hostkey_public_by_index(i, ssh);
		if (key == NULL || key->type == KEY_UNSPEC ||
		    key->type == KEY_RSA1 || sshkey_is_cert(key))
			continue;
		fp = sshkey_fingerprint(key, options.fingerprint_hash,
		    SSH_FP_DEFAULT);
		debug3("%s: key %d: %s %s", __func__, i,
		    sshkey_ssh_name(key), fp);
		free(fp);
		if (nkeys == 0) {
			packet_start(SSH2_MSG_GLOBAL_REQUEST);
			packet_put_cstring("hostkeys-00@openssh.com");
			packet_put_char(0); /* want-reply */
		}
		sshbuf_reset(buf);
		if ((r = sshkey_putb(key, buf)) != 0)
			fatal("%s: couldn't put hostkey %d: %s",
			    __func__, i, ssh_err(r));
		packet_put_string(sshbuf_ptr(buf), sshbuf_len(buf));
		nkeys++;
	}
	debug3("%s: sent %d hostkeys", __func__, nkeys);
	if (nkeys == 0)
		fatal("%s: no hostkeys", __func__);
	packet_send();
	sshbuf_free(buf);
}

/*
 * returns 1 if connection should be dropped, 0 otherwise.
 * dropping starts at connection #max_startups_begin with a probability
 * of (max_startups_rate/100). the probability increases linearly until
 * all connections are dropped for startups > max_startups
 */
static int
drop_connection(int startups)
{
	int p, r;

	if (startups < options.max_startups_begin)
		return 0;
	if (startups >= options.max_startups)
		return 1;
	if (options.max_startups_rate == 100)
		return 1;

	p  = 100 - options.max_startups_rate;
	p *= startups - options.max_startups_begin;
	p /= options.max_startups - options.max_startups_begin;
	p += options.max_startups_rate;
	r = arc4random_uniform(100);

	debug("drop_connection: p %d, r %d", p, r);
	return (r < p) ? 1 : 0;
}

static void
usage(void)
{
	fprintf(stderr, "%s, %s\n",
	    SSH_RELEASE,
#ifdef WITH_OPENSSL
	    SSLeay_version(SSLEAY_VERSION)
#else
	    "without OpenSSL"
#endif
	);
	fprintf(stderr,
"usage: sshd [-46DdeiqTt] [-b bits] [-C connection_spec] [-c host_cert_file]\n"
"            [-E log_file] [-f config_file] [-g login_grace_time]\n"
"            [-h host_key_file] [-k key_gen_time] [-o option] [-p port]\n"
"            [-u len]\n"
	);
	exit(1);
}

static void
send_rexec_state(int fd, Buffer *conf)
{
	Buffer m;

	debug3("%s: entering fd = %d config len %d", __func__, fd,
	    buffer_len(conf));

	/*
	 * Protocol from reexec master to child:
	 *	string	configuration
	 *	u_int	ephemeral_key_follows
	 *	bignum	e		(only if ephemeral_key_follows == 1)
	 *	bignum	n			"
	 *	bignum	d			"
	 *	bignum	iqmp			"
	 *	bignum	p			"
	 *	bignum	q			"
	 *	string rngseed		(only if OpenSSL is not self-seeded)
	 */
	buffer_init(&m);
	buffer_put_cstring(&m, buffer_ptr(conf));

#ifdef WITH_SSH1
	if (sensitive_data.server_key != NULL &&
	    sensitive_data.server_key->type == KEY_RSA1) {
		buffer_put_int(&m, 1);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->e);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->n);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->d);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->iqmp);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->p);
		buffer_put_bignum(&m, sensitive_data.server_key->rsa->q);
	} else
#endif
		buffer_put_int(&m, 0);

#if defined(WITH_OPENSSL) && !defined(OPENSSL_PRNG_ONLY)
	rexec_send_rng_seed(&m);
#endif

	if (ssh_msg_send(fd, 0, &m) == -1)
		fatal("%s: ssh_msg_send failed", __func__);

	buffer_free(&m);

	debug3("%s: done", __func__);
}

static void
recv_rexec_state(int fd, Buffer *conf)
{
	Buffer m;
	char *cp;
	u_int len;

	debug3("%s: entering fd = %d", __func__, fd);

	buffer_init(&m);

	if (ssh_msg_recv(fd, &m) == -1)
		fatal("%s: ssh_msg_recv failed", __func__);
	if (buffer_get_char(&m) != 0)
		fatal("%s: rexec version mismatch", __func__);

	cp = buffer_get_string(&m, &len);
	if (conf != NULL)
		buffer_append(conf, cp, len + 1);
	free(cp);

	if (buffer_get_int(&m)) {
#ifdef WITH_SSH1
		if (sensitive_data.server_key != NULL)
			key_free(sensitive_data.server_key);
		sensitive_data.server_key = key_new_private(KEY_RSA1);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->e);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->n);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->d);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->iqmp);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->p);
		buffer_get_bignum(&m, sensitive_data.server_key->rsa->q);
		if (rsa_generate_additional_parameters(
		    sensitive_data.server_key->rsa) != 0)
			fatal("%s: rsa_generate_additional_parameters "
			    "error", __func__);
#endif
	}

#if defined(WITH_OPENSSL) && !defined(OPENSSL_PRNG_ONLY)
	rexec_recv_rng_seed(&m);
#endif

	buffer_free(&m);

	debug3("%s: done", __func__);
}

/* Accept a connection from inetd */
static void
server_accept_inetd(int *sock_in, int *sock_out)
{
	int fd;

	if (rexeced_flag) {
		close(REEXEC_CONFIG_PASS_FD);
		*sock_in = *sock_out = dup(STDIN_FILENO);
	} else {
		*sock_in = dup(STDIN_FILENO);
		*sock_out = dup(STDOUT_FILENO);
	}
	/*
	 * We intentionally do not close the descriptors 0, 1, and 2
	 * as our code for setting the descriptors won't work if
	 * ttyfd happens to be one of those.
	 */
	if ((fd = open(_PATH_DEVNULL, O_RDWR, 0)) != -1) {
		dup2(fd, STDIN_FILENO);
		dup2(fd, STDOUT_FILENO);
		if (!log_stderr)
			dup2(fd, STDERR_FILENO);
		if (fd > (log_stderr ? STDERR_FILENO : STDOUT_FILENO))
			close(fd);
	}
	debug("inetd sockets after dupping: %d, %d", *sock_in, *sock_out);
}

/*
 * Listen for TCP connections
 */
static void
server_listen(void)
{
	int ret, listen_sock, on = 1;
	struct addrinfo *ai;
	char ntop[NI_MAXHOST], strport[NI_MAXSERV];

	for (ai = options.listen_addrs; ai; ai = ai->ai_next) {
		if (ai->ai_family != AF_INET && ai->ai_family != AF_INET6)
			continue;
		if (num_listen_socks >= MAX_LISTEN_SOCKS)
			fatal("Too many listen sockets. "
			    "Enlarge MAX_LISTEN_SOCKS");
		if ((ret = getnameinfo(ai->ai_addr, ai->ai_addrlen,
		    ntop, sizeof(ntop), strport, sizeof(strport),
		    NI_NUMERICHOST|NI_NUMERICSERV)) != 0) {
			error("getnameinfo failed: %.100s",
			    ssh_gai_strerror(ret));
			continue;
		}
		/* Create socket for listening. */
		listen_sock = socket(ai->ai_family, ai->ai_socktype,
		    ai->ai_protocol);
		if (listen_sock < 0) {
			/* kernel may not support ipv6 */
			verbose("socket: %.100s", strerror(errno));
			continue;
		}
		if (set_nonblock(listen_sock) == -1) {
			close(listen_sock);
			continue;
		}
		/*
		 * Set socket options.
		 * Allow local port reuse in TIME_WAIT.
		 */
		if (setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR,
		    &on, sizeof(on)) == -1)
			error("setsockopt SO_REUSEADDR: %s", strerror(errno));

		/* Only communicate in IPv6 over AF_INET6 sockets. */
		if (ai->ai_family == AF_INET6)
			sock_set_v6only(listen_sock);

		debug("Bind to port %s on %s.", strport, ntop);

		/* Bind the socket to the desired port. */
		if (bind(listen_sock, ai->ai_addr, ai->ai_addrlen) < 0) {
			error("Bind to port %s on %s failed: %.200s.",
			    strport, ntop, strerror(errno));
			close(listen_sock);
			continue;
		}
		listen_socks[num_listen_socks] = listen_sock;
		num_listen_socks++;

		/* Start listening on the port. */
		if (listen(listen_sock, SSH_LISTEN_BACKLOG) < 0)
			fatal("listen on [%s]:%s: %.100s",
			    ntop, strport, strerror(errno));
		logit("Server listening on %s port %s.", ntop, strport);
	}
	freeaddrinfo(options.listen_addrs);

	if (!num_listen_socks)
		fatal("Cannot bind any address.");
}

/*
 * The main TCP accept loop. Note that, for the non-debug case, returns
 * from this function are in a forked subprocess.
 */
static void
server_accept_loop(int *sock_in, int *sock_out, int *newsock, int *config_s)
{
	fd_set *fdset;
	int i, j, ret, maxfd;
	int key_used = 0;
	int startups = 0, listening = 0, lameduck = 0;
	int startup_p[2] = { -1 , -1 };
	char c = 0;
	struct sockaddr_storage from;
	socklen_t fromlen;
	pid_t pid;
	u_char rnd[256];

	/* setup fd set for accept */
	fdset = NULL;
	maxfd = 0;
	for (i = 0; i < num_listen_socks; i++)
		if (listen_socks[i] > maxfd)
			maxfd = listen_socks[i];
	/* pipes connected to unauthenticated childs */
	startup_pipes = xcalloc(options.max_startups, sizeof(int));
	startup_flags = xcalloc(options.max_startups, sizeof(int));
	for (i = 0; i < options.max_startups; i++)
		startup_pipes[i] = -1;

	/*
	 * Stay listening for connections until the system crashes or
	 * the daemon is killed with a signal.
	 */
	for (;;) {
		if (received_sighup) {
			if (!lameduck) {
				debug("Received SIGHUP; waiting for children");
				close_listen_socks();
				lameduck = 1;
			}
			if (listening <= 0)
				sighup_restart();
		}
		free(fdset);
		fdset = xcalloc(howmany(maxfd + 1, NFDBITS),
		    sizeof(fd_mask));

		for (i = 0; i < num_listen_socks; i++)
			FD_SET(listen_socks[i], fdset);
		for (i = 0; i < options.max_startups; i++)
			if (startup_pipes[i] != -1)
				FD_SET(startup_pipes[i], fdset);

		/* Wait in select until there is a connection. */
		ret = select(maxfd+1, fdset, NULL, NULL, NULL);
		if (ret < 0 && errno != EINTR)
			error("select: %.100s", strerror(errno));
		if (received_sigterm) {
			logit("Received signal %d; terminating.",
			    (int) received_sigterm);
			destroy_sensitive_data(0);
			close_listen_socks();
			if (options.pid_file != NULL)
				unlink(options.pid_file);
			exit(received_sigterm == SIGTERM ? 0 : 255);
		}
		if (key_used && key_do_regen) {
			generate_ephemeral_server_key();
			key_used = 0;
			key_do_regen = 0;
		}
		if (ret < 0)
			continue;

		for (i = 0; i < options.max_startups; i++) {
			if (startup_pipes[i] == -1 ||
			    !FD_ISSET(startup_pipes[i], fdset))
				continue;
			switch (read(startup_pipes[i], &c, sizeof(c))) {
			case -1:
				if (errno == EINTR || errno == EAGAIN)
					continue;
				if (errno != EPIPE) {
					error("%s: startup pipe %d (fd=%d): "
					    "read %s", __func__, i,
					    startup_pipes[i], strerror(errno));
				}
				/* FALLTHROUGH */
			case 0:
				/* child exited or completed auth */
				close(startup_pipes[i]);
				startup_pipes[i] = -1;
				startups--;
				if (startup_flags[i])
					listening--;
				break;
			case 1:
				/* child has finished preliminaries */
				if (startup_flags[i]) {
					listening--;
					startup_flags[i] = 0;
				}
				break;
			}
		}
		for (i = 0; i < num_listen_socks; i++) {
			if (!FD_ISSET(listen_socks[i], fdset))
				continue;
			fromlen = sizeof(from);
			*newsock = accept(listen_socks[i],
			    (struct sockaddr *)&from, &fromlen);
			if (*newsock < 0) {
				if (errno != EINTR && errno != EWOULDBLOCK &&
				    errno != ECONNABORTED && errno != EAGAIN)
					error("accept: %.100s",
					    strerror(errno));
				if (errno == EMFILE || errno == ENFILE)
					usleep(100 * 1000);
				continue;
			}
			if (unset_nonblock(*newsock) == -1) {
				close(*newsock);
				continue;
			}
			if (drop_connection(startups) == 1) {
				debug("drop connection #%d", startups);
				close(*newsock);
				continue;
			}
			if (pipe(startup_p) == -1) {
				close(*newsock);
				continue;
			}

			if (rexec_flag && socketpair(AF_UNIX,
			    SOCK_STREAM, 0, config_s) == -1) {
				error("reexec socketpair: %s",
				    strerror(errno));
				close(*newsock);
				close(startup_p[0]);
				close(startup_p[1]);
				continue;
			}

			for (j = 0; j < options.max_startups; j++)
				if (startup_pipes[j] == -1) {
					startup_pipes[j] = startup_p[0];
					if (maxfd < startup_p[0])
						maxfd = startup_p[0];
					startups++;
					startup_flags[j] = 1;
					break;
				}
			if(!(--re_seeding_counter)) {
				re_seeding_counter = RESEED_AFTER;
				linux_seed();
#ifdef SSH_AUDIT_EVENTS
				audit_linux_prng_seed(rand_bytes, rand_file);
#endif
			}

			/*
			 * Got connection.  Fork a child to handle it, unless
			 * we are in debugging mode.
			 */
			if (debug_flag) {
				/*
				 * In debugging mode.  Close the listening
				 * socket, and start processing the
				 * connection without forking.
				 */
				debug("Server will not fork when running in debugging mode.");
				close_listen_socks();
				*sock_in = *newsock;
				*sock_out = *newsock;
				close(startup_p[0]);
				close(startup_p[1]);
				startup_pipe = -1;
				pid = getpid();
				if (rexec_flag) {
					send_rexec_state(config_s[0],
					    &cfg);
					close(config_s[0]);
				}
				return;
			}

			/*
			 * Normal production daemon.  Fork, and have
			 * the child process the connection. The
			 * parent continues listening.
			 */
			platform_pre_fork();
			listening++;
			if ((pid = fork()) == 0) {
				/*
				 * Child.  Close the listening and
				 * max_startup sockets.  Start using
				 * the accepted socket. Reinitialize
				 * logging (since our pid has changed).
				 * We return from this function to handle
				 * the connection.
				 */
				platform_post_fork_child();
				startup_pipe = startup_p[1];
				close_startup_pipes();
				close_listen_socks();
				*sock_in = *newsock;
				*sock_out = *newsock;
				log_init(__progname,
				    options.log_level,
				    options.log_facility,
				    log_stderr);
				if (rexec_flag)
					close(config_s[0]);
				else {
					/*
					 * Signal parent that the preliminaries
					 * for this child are complete. For the
					 * re-exec case, this happens after the
					 * child has received the rexec state
					 * from the server.
					 */
					(void)atomicio(vwrite, startup_pipe,
					    "\0", 1);
				}
				return;
			}

			/* Parent.  Stay in the loop. */
			platform_post_fork_parent(pid);
			if (pid < 0)
				error("fork: %.100s", strerror(errno));
			else
				debug("Forked child %ld.", (long)pid);

			close(startup_p[1]);

			if (rexec_flag) {
				send_rexec_state(config_s[0], &cfg);
				close(config_s[0]);
				close(config_s[1]);
			}

			/*
			 * Mark that the key has been used (it
			 * was "given" to the child).
			 */
			if ((options.protocol & SSH_PROTO_1) &&
			    key_used == 0) {
				/* Schedule server key regeneration alarm. */
				signal(SIGALRM, key_regeneration_alarm);
				alarm(options.key_regeneration_time);
				key_used = 1;
			}

			close(*newsock);

			/*
			 * Ensure that our random state differs
			 * from that of the child
			 */
			arc4random_stir();
			arc4random_buf(rnd, sizeof(rnd));
#ifdef WITH_OPENSSL
			RAND_seed(rnd, sizeof(rnd));
			if ((RAND_bytes((u_char *)rnd, 1)) != 1)
				fatal("%s: RAND_bytes failed", __func__);
#endif
			explicit_bzero(rnd, sizeof(rnd));
		}
	}
}


/*
 * Main program for the daemon.
 */
int
main(int ac, char **av)
{
	extern char *optarg;
	extern int optind;
	int r, opt, i, j, on = 1;
	int sock_in = -1, sock_out = -1, newsock = -1;
	const char *remote_ip;
	int remote_port;
	char *fp, *line, *laddr, *logfile = NULL;
	int config_s[2] = { -1 , -1 };
	u_int n;
	u_int64_t ibytes, obytes;
	mode_t new_umask;
	Key *key;
	Key *pubkey;
	int keytype;
	Authctxt *authctxt;
	struct connection_info *connection_info = get_connection_info(0, 0);

    /* initialize fips - can go before ssh_malloc_init(), since that is a
     * OpenBSD-only thing (as of OpenSSH 7.6p1) */
	fips_ssh_init();

	ssh_malloc_init();	/* must be called before any mallocs */

#ifdef HAVE_SECUREWARE
	(void)set_auth_parameters(ac, av);
#endif
	__progname = ssh_get_progname(av[0]);

	/* Save argv. Duplicate so setproctitle emulation doesn't clobber it */
	saved_argc = ac;
	rexec_argc = ac;
	saved_argv = xcalloc(ac + 1, sizeof(*saved_argv));
	for (i = 0; i < ac; i++)
		saved_argv[i] = xstrdup(av[i]);
	saved_argv[i] = NULL;

#ifndef HAVE_SETPROCTITLE
	/* Prepare for later setproctitle emulation */
	compat_init_setproctitle(ac, av);
	av = saved_argv;
#endif

	if (geteuid() == 0 && setgroups(0, NULL) == -1)
		debug("setgroups(): %.200s", strerror(errno));

	/* Ensure that fds 0, 1 and 2 are open or directed to /dev/null */
	sanitise_stdfd();

	/* Initialize configuration options to their default values. */
	initialize_server_options(&options);
#ifdef ERICSSON_PATCH_ENABLED
        connection_info->address = connection_info->host =
                connection_info->subsystem = connection_info->user = NULL;
#endif

	/* Parse command-line arguments. */
	while ((opt = getopt(ac, av,
	    "C:E:b:c:f:g:h:k:o:p:u:46DQRTdeiqrt")) != -1) {
		switch (opt) {
		case '4':
			options.address_family = AF_INET;
			break;
		case '6':
			options.address_family = AF_INET6;
			break;
		case 'f':
			config_file_name = optarg;
			break;
		case 'c':
			if (options.num_host_cert_files >= MAX_HOSTCERTS) {
				fprintf(stderr, "too many host certificates.\n");
				exit(1);
			}
			options.host_cert_files[options.num_host_cert_files++] =
			   derelativise_path(optarg);
			break;
		case 'd':
			if (debug_flag == 0) {
				debug_flag = 1;
				options.log_level = SYSLOG_LEVEL_DEBUG1;
			} else if (options.log_level < SYSLOG_LEVEL_DEBUG3)
				options.log_level++;
			break;
		case 'D':
			no_daemon_flag = 1;
			break;
		case 'E':
			logfile = optarg;
			/* FALLTHROUGH */
		case 'e':
			log_stderr = 1;
			break;
		case 'i':
			inetd_flag = 1;
			break;
		case 'r':
			rexec_flag = 0;
			break;
		case 'R':
			rexeced_flag = 1;
			inetd_flag = 1;
			break;
		case 'Q':
			/* ignored */
			break;
		case 'q':
			options.log_level = SYSLOG_LEVEL_QUIET;
			break;
		case 'b':
			options.server_key_bits = (int)strtonum(optarg, 256,
			    32768, NULL);
			break;
		case 'p':
			options.ports_from_cmdline = 1;
			if (options.num_ports >= MAX_PORTS) {
				fprintf(stderr, "too many ports.\n");
				exit(1);
			}
			options.ports[options.num_ports++] = a2port(optarg);
			if (options.ports[options.num_ports-1] <= 0) {
				fprintf(stderr, "Bad port number.\n");
				exit(1);
			}
			break;
		case 'g':
			if ((options.login_grace_time = convtime(optarg)) == -1) {
				fprintf(stderr, "Invalid login grace time.\n");
				exit(1);
			}
			break;
		case 'k':
			if ((options.key_regeneration_time = convtime(optarg)) == -1) {
				fprintf(stderr, "Invalid key regeneration interval.\n");
				exit(1);
			}
			break;
		case 'h':
			if (options.num_host_key_files >= MAX_HOSTKEYS) {
				fprintf(stderr, "too many host keys.\n");
				exit(1);
			}
			options.host_key_files[options.num_host_key_files++] = 
			   derelativise_path(optarg);
			break;
		case 't':
			test_flag = 1;
			break;
		case 'T':
			test_flag = 2;
			break;
		case 'C':
			if (parse_server_match_testspec(connection_info,
			    optarg) == -1)
				exit(1);
			break;
		case 'u':
			utmp_len = (u_int)strtonum(optarg, 0, HOST_NAME_MAX+1+1, NULL);
			if (utmp_len > HOST_NAME_MAX+1) {
				fprintf(stderr, "Invalid utmp length.\n");
				exit(1);
			}
			break;
		case 'o':
			line = xstrdup(optarg);
			if (process_server_config_line(&options, line,
			    "command-line", 0, NULL, NULL) != 0)
				exit(1);
			free(line);
			break;
		case '?':
		default:
			usage();
			break;
		}
	}
	if (rexeced_flag || inetd_flag)
		rexec_flag = 0;
	if (!test_flag && (rexec_flag && (av[0] == NULL || *av[0] != '/')))
		fatal("sshd re-exec requires execution with an absolute path");
	if (rexeced_flag)
		closefrom(REEXEC_MIN_FREE_FD);
	else
		closefrom(REEXEC_DEVCRYPTO_RESERVED_FD);

#ifdef WITH_OPENSSL
	OpenSSL_add_all_algorithms();
#endif

	/* If requested, redirect the logs to the specified logfile. */
	if (logfile != NULL)
		log_redirect_stderr_to(logfile);
	/*
	 * Force logging to stderr until we have loaded the private host
	 * key (unless started from inetd)
	 */
	log_init(__progname,
	    options.log_level == SYSLOG_LEVEL_NOT_SET ?
	    SYSLOG_LEVEL_INFO : options.log_level,
	    options.log_facility == SYSLOG_FACILITY_NOT_SET ?
	    SYSLOG_FACILITY_AUTH : options.log_facility,
	    log_stderr || !inetd_flag);

	/*
	 * Unset KRB5CCNAME, otherwise the user's session may inherit it from
	 * root's environment
	 */
	if (getenv("KRB5CCNAME") != NULL)
		(void) unsetenv("KRB5CCNAME");

#ifdef _UNICOS
	/* Cray can define user privs drop all privs now!
	 * Not needed on PRIV_SU systems!
	 */
	drop_cray_privs();
#endif

	sensitive_data.server_key = NULL;
	sensitive_data.ssh1_host_key = NULL;
	sensitive_data.have_ssh1_key = 0;
	sensitive_data.have_ssh2_key = 0;

	/*
	 * If we're doing an extended config test, make sure we have all of
	 * the parameters we need.  If we're not doing an extended test,
	 * do not silently ignore connection test params.
	 */
	if (test_flag >= 2 && server_match_spec_complete(connection_info) == 0)
		fatal("user, host and addr are all required when testing "
		   "Match configs");
	if (test_flag < 2 && server_match_spec_complete(connection_info) >= 0)
		fatal("Config test connection parameter (-C) provided without "
		   "test mode (-T)");

	/* Fetch our configuration */
	buffer_init(&cfg);
	if (rexeced_flag) {
		recv_rexec_state(REEXEC_CONFIG_PASS_FD, &cfg);
		if (!debug_flag) {
			startup_pipe = dup(REEXEC_STARTUP_PIPE_FD);
			close(REEXEC_STARTUP_PIPE_FD);
			/*
			 * Signal parent that this child is at a point where
			 * they can go away if they have a SIGHUP pending.
			 */
			(void)atomicio(vwrite, startup_pipe, "\0", 1);
		}
	} else if (strcasecmp(config_file_name, "none") != 0)
		load_server_config(config_file_name, &cfg);

	parse_server_config(&options, rexeced_flag ? "rexec" : config_file_name,
	    &cfg, NULL);

	seed_rng();

	/* Fill in default values for those options not explicitly set. */
	fill_default_server_options(&options);

	/* challenge-response is implemented via keyboard interactive */
	if (options.challenge_response_authentication)
		options.kbd_interactive_authentication = 1;

	/* Check that options are sensible */
	if (options.authorized_keys_command_user == NULL &&
	    (options.authorized_keys_command != NULL &&
	    strcasecmp(options.authorized_keys_command, "none") != 0))
		fatal("AuthorizedKeysCommand set without "
		    "AuthorizedKeysCommandUser");
	if (options.authorized_principals_command_user == NULL &&
	    (options.authorized_principals_command != NULL &&
	    strcasecmp(options.authorized_principals_command, "none") != 0))
		fatal("AuthorizedPrincipalsCommand set without "
		    "AuthorizedPrincipalsCommandUser");

	/*
	 * Check whether there is any path through configured auth methods.
	 * Unfortunately it is not possible to verify this generally before
	 * daemonisation in the presence of Match block, but this catches
	 * and warns for trivial misconfigurations that could break login.
	 */
	if (options.num_auth_methods != 0) {
		if ((options.protocol & SSH_PROTO_1))
			fatal("AuthenticationMethods is not supported with "
			    "SSH protocol 1");
		for (n = 0; n < options.num_auth_methods; n++) {
			if (auth2_methods_valid(options.auth_methods[n],
			    1) == 0)
				break;
		}
		if (n >= options.num_auth_methods)
			fatal("AuthenticationMethods cannot be satisfied by "
			    "enabled authentication methods");
	}

	/* set default channel AF */
	channel_set_af(options.address_family);

	/* Check that there are no remaining arguments. */
	if (optind < ac) {
		fprintf(stderr, "Extra argument %s.\n", av[optind]);
		exit(1);
	}

	debug("sshd version %s, %s", SSH_VERSION,
#ifdef WITH_OPENSSL
	    SSLeay_version(SSLEAY_VERSION)
#else
	    "without OpenSSL"
#endif
	);

	/* Store privilege separation user for later use if required. */
	if ((privsep_pw = getpwnam(SSH_PRIVSEP_USER)) == NULL) {
		if (use_privsep || options.kerberos_authentication)
			fatal("Privilege separation user %s does not exist",
			    SSH_PRIVSEP_USER);
	} else {
		explicit_bzero(privsep_pw->pw_passwd,
		    strlen(privsep_pw->pw_passwd));
		privsep_pw = pwcopy(privsep_pw);
		free(privsep_pw->pw_passwd);
		privsep_pw->pw_passwd = xstrdup("*");
	}
	endpwent();

	/* load host keys */
	sensitive_data.host_keys = xcalloc(options.num_host_key_files,
	    sizeof(Key *));
	sensitive_data.host_pubkeys = xcalloc(options.num_host_key_files,
	    sizeof(Key *));

	if (options.host_key_agent) {
		if (strcmp(options.host_key_agent, SSH_AUTHSOCKET_ENV_NAME))
			setenv(SSH_AUTHSOCKET_ENV_NAME,
			    options.host_key_agent, 1);
		if ((r = ssh_get_authentication_socket(NULL)) == 0)
			have_agent = 1;
		else
			error("Could not connect to agent \"%s\": %s",
			    options.host_key_agent, ssh_err(r));
	}

	for (i = 0; i < options.num_host_key_files; i++) {
		if (options.host_key_files[i] == NULL)
			continue;
		key = key_load_private(options.host_key_files[i], "", NULL);
		pubkey = key_load_public(options.host_key_files[i], NULL);
		if (pubkey == NULL && key != NULL)
			pubkey = key_demote(key);
		sensitive_data.host_keys[i] = key;
		sensitive_data.host_pubkeys[i] = pubkey;

		if (key == NULL && pubkey != NULL && pubkey->type != KEY_RSA1 &&
		    have_agent) {
			debug("will rely on agent for hostkey %s",
			    options.host_key_files[i]);
			keytype = pubkey->type;
		} else if (key != NULL) {
			keytype = key->type;
		} else {
			error("Could not load host key: %s",
			    options.host_key_files[i]);
			sensitive_data.host_keys[i] = NULL;
			sensitive_data.host_pubkeys[i] = NULL;
			continue;
		}

		switch (keytype) {
		case KEY_RSA1:
			sensitive_data.ssh1_host_key = key;
			sensitive_data.have_ssh1_key = 1;
			break;
		case KEY_RSA:
		case KEY_DSA:
		case KEY_ECDSA:
		case KEY_ED25519:
			if (have_agent || key != NULL)
				sensitive_data.have_ssh2_key = 1;
			break;
		}
		if ((fp = sshkey_fingerprint(pubkey, options.fingerprint_hash,
		    SSH_FP_DEFAULT)) == NULL)
			fatal("sshkey_fingerprint failed");
		debug("%s host key #%d: %s %s",
		    key ? "private" : "agent", i, keytype == KEY_RSA1 ?
		    sshkey_type(pubkey) : sshkey_ssh_name(pubkey), fp);
		free(fp);
	}
	if ((options.protocol & SSH_PROTO_1) && fips_mode()) {
		logit("Disabling protocol version 1. Not allowed in the FIPS mode.");
		options.protocol &= ~SSH_PROTO_1;
	}
	if ((options.protocol & SSH_PROTO_1) && !sensitive_data.have_ssh1_key) {
		logit("Disabling protocol version 1. Could not load host key");
		options.protocol &= ~SSH_PROTO_1;
	}
#ifndef GSSAPI
	/* The GSSAPI key exchange can run without a host key */
	if ((options.protocol & SSH_PROTO_2) && !sensitive_data.have_ssh2_key) {
		logit("Disabling protocol version 2. Could not load host key");
		options.protocol &= ~SSH_PROTO_2;
	}
#endif
	if (!(options.protocol & (SSH_PROTO_1|SSH_PROTO_2))) {
		logit("sshd: no hostkeys available -- exiting.");
		exit(1);
	}

	/*
	 * Load certificates. They are stored in an array at identical
	 * indices to the public keys that they relate to.
	 */
	sensitive_data.host_certificates = xcalloc(options.num_host_key_files,
	    sizeof(Key *));
	for (i = 0; i < options.num_host_key_files; i++)
		sensitive_data.host_certificates[i] = NULL;

	for (i = 0; i < options.num_host_cert_files; i++) {
		if (options.host_cert_files[i] == NULL)
			continue;
		key = key_load_public(options.host_cert_files[i], NULL);
		if (key == NULL) {
			error("Could not load host certificate: %s",
			    options.host_cert_files[i]);
			continue;
		}
		if (!key_is_cert(key)) {
			error("Certificate file is not a certificate: %s",
			    options.host_cert_files[i]);
			key_free(key);
			continue;
		}
		/* Find matching private key */
		for (j = 0; j < options.num_host_key_files; j++) {
			if (key_equal_public(key,
			    sensitive_data.host_keys[j])) {
				sensitive_data.host_certificates[j] = key;
				break;
			}
		}
		if (j >= options.num_host_key_files) {
			error("No matching private key for certificate: %s",
			    options.host_cert_files[i]);
			key_free(key);
			continue;
		}
		sensitive_data.host_certificates[j] = key;
		debug("host certificate: #%d type %d %s", j, key->type,
		    key_type(key));
	}

#ifdef WITH_SSH1
	/* Check certain values for sanity. */
	if (options.protocol & SSH_PROTO_1) {
		if (options.server_key_bits < SSH_RSA_MINIMUM_MODULUS_SIZE ||
		    options.server_key_bits > OPENSSL_RSA_MAX_MODULUS_BITS) {
			fprintf(stderr, "Bad server key size.\n");
			exit(1);
		}
		/*
		 * Check that server and host key lengths differ sufficiently. This
		 * is necessary to make double encryption work with rsaref. Oh, I
		 * hate software patents. I dont know if this can go? Niels
		 */
		if (options.server_key_bits >
		    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n) -
		    SSH_KEY_BITS_RESERVED && options.server_key_bits <
		    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n) +
		    SSH_KEY_BITS_RESERVED) {
			options.server_key_bits =
			    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n) +
			    SSH_KEY_BITS_RESERVED;
			debug("Forcing server key to %d bits to make it differ from host key.",
			    options.server_key_bits);
		}
	}
#endif

	if (use_privsep) {
		struct stat st;

		if ((stat(_PATH_PRIVSEP_CHROOT_DIR, &st) == -1) ||
		    (S_ISDIR(st.st_mode) == 0))
			fatal("Missing privilege separation directory: %s",
			    _PATH_PRIVSEP_CHROOT_DIR);

#ifdef HAVE_CYGWIN
		if (check_ntsec(_PATH_PRIVSEP_CHROOT_DIR) &&
		    (st.st_uid != getuid () ||
		    (st.st_mode & (S_IWGRP|S_IWOTH)) != 0))
#else
		if (st.st_uid != 0 || (st.st_mode & (S_IWGRP|S_IWOTH)) != 0)
#endif
			fatal("%s must be owned by root and not group or "
			    "world-writable.", _PATH_PRIVSEP_CHROOT_DIR);
	}

	if (test_flag > 1) {
		if (server_match_spec_complete(connection_info) == 1)
			parse_server_match_config(&options, connection_info);
		dump_config(&options);
	}

	/* Configuration looks good, so exit if in test mode. */
	if (test_flag)
		exit(0);

	/*
	 * Clear out any supplemental groups we may have inherited.  This
	 * prevents inadvertent creation of files with bad modes (in the
	 * portable version at least, it's certainly possible for PAM
	 * to create a file, and we can't control the code in every
	 * module which might be used).
	 */
	if (setgroups(0, NULL) < 0)
		debug("setgroups() failed: %.200s", strerror(errno));

	if (rexec_flag) {
		rexec_argv = xcalloc(rexec_argc + 2, sizeof(char *));
		for (i = 0; i < rexec_argc; i++) {
			debug("rexec_argv[%d]='%s'", i, saved_argv[i]);
			rexec_argv[i] = saved_argv[i];
		}
		rexec_argv[rexec_argc] = "-R";
		rexec_argv[rexec_argc + 1] = NULL;
	}

	/* Ensure that umask disallows at least group and world write */
	new_umask = umask(0077) | 0022;
	(void) umask(new_umask);

	/* Initialize the log (it is reinitialized below in case we forked). */
	if (debug_flag && (!inetd_flag || rexeced_flag))
		log_stderr = 1;
	log_init(__progname, options.log_level, options.log_facility, log_stderr);

	/*
	 * If not in debugging mode, and not started from inetd, disconnect
	 * from the controlling terminal, and fork.  The original process
	 * exits.
	 */
	if (!(debug_flag || inetd_flag || no_daemon_flag)) {
#ifdef TIOCNOTTY
		int fd;
#endif /* TIOCNOTTY */
		if (daemon(0, 0) < 0)
			fatal("daemon() failed: %.200s", strerror(errno));

		/* Disconnect from the controlling tty. */
#ifdef TIOCNOTTY
		fd = open(_PATH_TTY, O_RDWR | O_NOCTTY);
		if (fd >= 0) {
			(void) ioctl(fd, TIOCNOTTY, NULL);
			close(fd);
		}
#endif /* TIOCNOTTY */
	}
	/* Reinitialize the log (because of the fork above). */
	log_init(__progname, options.log_level, options.log_facility, log_stderr);

	/* Chdir to the root directory so that the current disk can be
	   unmounted if desired. */
	if (chdir("/") == -1)
		error("chdir(\"/\"): %s", strerror(errno));

	/* ignore SIGPIPE */
	signal(SIGPIPE, SIG_IGN);

	/* Get a connection, either from inetd or a listening TCP socket */
	if (inetd_flag) {
		server_accept_inetd(&sock_in, &sock_out);
	} else {
		platform_pre_listen();
		server_listen();

		if (options.protocol & SSH_PROTO_1)
			generate_ephemeral_server_key();

		signal(SIGHUP, sighup_handler);
		signal(SIGCHLD, main_sigchld_handler);
		signal(SIGTERM, sigterm_handler);
		signal(SIGQUIT, sigterm_handler);

		/*
		 * Write out the pid file after the sigterm handler
		 * is setup and the listen sockets are bound
		 */
		if (!no_daemon_flag && options.pid_file != NULL && !debug_flag) {
			FILE *f = fopen(options.pid_file, "w");

			if (f == NULL) {
				error("Couldn't create pid file \"%s\": %s",
				    options.pid_file, strerror(errno));
			} else {
				fprintf(f, "%ld\n", (long) getpid());
				fclose(f);
			}
		}

#ifdef HAVE_SYSTEMD
		/* Signal systemd that we are ready to accept connections */
		sd_notify(0, "READY=1");
#endif

		/* Accept a connection and return in a forked child */
		server_accept_loop(&sock_in, &sock_out,
		    &newsock, config_s);
	}

	/* This is the child processing a new connection. */
	setproctitle("%s", "[accepted]");

#ifdef USE_SECURITY_SESSION_API
	/*
	 * Create a new security session for use by the new user login if
	 * the current session is the root session or we are not launched
	 * by inetd (eg: debugging mode or server mode).  We do not
	 * necessarily need to create a session if we are launched from
	 * inetd because Panther xinetd will create a session for us.
	 *
	 * The only case where this logic will fail is if there is an
	 * inetd running in a non-root session which is not creating
	 * new sessions for us.  Then all the users will end up in the
	 * same session (bad).
	 *
	 * When the client exits, the session will be destroyed for us
	 * automatically.
	 *
	 * We must create the session before any credentials are stored
	 * (including AFS pags, which happens a few lines below).
	 */
	{
		OSStatus err = 0;
		SecuritySessionId sid = 0;
		SessionAttributeBits sattrs = 0;

		err = SessionGetInfo(callerSecuritySession, &sid, &sattrs);
		if (err)
			error("SessionGetInfo() failed with error %.8X",
			    (unsigned) err);
		else
			debug("Current Session ID is %.8X / Session Attributes are %.8X",
			    (unsigned) sid, (unsigned) sattrs);

		if (inetd_flag && !(sattrs & sessionIsRoot))
			debug("Running in inetd mode in a non-root session... "
			    "assuming inetd created the session for us.");
		else {
			debug("Creating new security session...");
			err = SessionCreate(0, sessionHasTTY | sessionIsRemote);
			if (err)
				error("SessionCreate() failed with error %.8X",
				    (unsigned) err);

			err = SessionGetInfo(callerSecuritySession, &sid, 
			    &sattrs);
			if (err)
				error("SessionGetInfo() failed with error %.8X",
				    (unsigned) err);
			else
				debug("New Session ID is %.8X / Session Attributes are %.8X",
				    (unsigned) sid, (unsigned) sattrs);
		}
	}
#endif

	/*
	 * Create a new session and process group since the 4.4BSD
	 * setlogin() affects the entire process group.  We don't
	 * want the child to be able to affect the parent.
	 */
#if !defined(SSHD_ACQUIRES_CTTY)
	/*
	 * If setsid is called, on some platforms sshd will later acquire a
	 * controlling terminal which will result in "could not set
	 * controlling tty" errors.
	 */
	if (!debug_flag && !inetd_flag && setsid() < 0)
		error("setsid: %.100s", strerror(errno));
#endif

	if (rexec_flag) {
		int fd;

		debug("rexec start in %d out %d newsock %d pipe %d sock %d",
		    sock_in, sock_out, newsock, startup_pipe, config_s[0]);
		dup2(newsock, STDIN_FILENO);
		dup2(STDIN_FILENO, STDOUT_FILENO);
		if (startup_pipe == -1)
			close(REEXEC_STARTUP_PIPE_FD);
		else if (startup_pipe != REEXEC_STARTUP_PIPE_FD) {
			dup2(startup_pipe, REEXEC_STARTUP_PIPE_FD);
			close(startup_pipe);
			startup_pipe = REEXEC_STARTUP_PIPE_FD;
		}

		dup2(config_s[1], REEXEC_CONFIG_PASS_FD);
		close(config_s[1]);

		execv(rexec_argv[0], rexec_argv);

		/* Reexec has failed, fall back and continue */
		error("rexec of %s failed: %s", rexec_argv[0], strerror(errno));
		recv_rexec_state(REEXEC_CONFIG_PASS_FD, NULL);
		log_init(__progname, options.log_level,
		    options.log_facility, log_stderr);

		/* Clean up fds */
		close(REEXEC_CONFIG_PASS_FD);
		newsock = sock_out = sock_in = dup(STDIN_FILENO);
		if ((fd = open(_PATH_DEVNULL, O_RDWR, 0)) != -1) {
			dup2(fd, STDIN_FILENO);
			dup2(fd, STDOUT_FILENO);
			if (fd > STDERR_FILENO)
				close(fd);
		}
		debug("rexec cleanup in %d out %d newsock %d pipe %d sock %d",
		    sock_in, sock_out, newsock, startup_pipe, config_s[0]);
	}

	/* Executed child processes don't need these. */
	fcntl(sock_out, F_SETFD, FD_CLOEXEC);
	fcntl(sock_in, F_SETFD, FD_CLOEXEC);

	/*
	 * Disable the key regeneration alarm.  We will not regenerate the
	 * key since we are no longer in a position to give it to anyone. We
	 * will not restart on SIGHUP since it no longer makes sense.
	 */
	alarm(0);
	signal(SIGALRM, SIG_DFL);
	signal(SIGHUP, SIG_DFL);
	signal(SIGTERM, SIG_DFL);
	signal(SIGQUIT, SIG_DFL);
	signal(SIGCHLD, SIG_DFL);
	signal(SIGINT, SIG_DFL);

	/*
	 * Register our connection.  This turns encryption off because we do
	 * not have a key.
	 */
	packet_set_connection(sock_in, sock_out);
	packet_set_server();

	/* Set SO_KEEPALIVE if requested. */
	if (options.tcp_keep_alive && packet_connection_is_on_socket() &&
	    setsockopt(sock_in, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on)) < 0)
		error("setsockopt SO_KEEPALIVE: %.100s", strerror(errno));

	if ((remote_port = get_remote_port()) < 0) {
		debug("get_remote_port failed");
		cleanup_exit(255);
	}

	/*
	 * We use get_canonical_hostname with usedns = 0 instead of
	 * get_remote_ipaddr here so IP options will be checked.
	 */
	(void) get_canonical_hostname(0);
	/*
	 * The rest of the code depends on the fact that
	 * get_remote_ipaddr() caches the remote ip, even if
	 * the socket goes away.
	 */
	remote_ip = get_remote_ipaddr();

#ifdef SSH_AUDIT_EVENTS
	audit_connection_from(remote_ip, remote_port);
#endif

#ifdef LIBWRAP
	if (options.use_tcpwrappers) {
		allow_severity = options.log_facility|LOG_INFO;
		deny_severity = options.log_facility|LOG_WARNING;
		/* Check whether logins are denied from this host. */
		if (packet_connection_is_on_socket()) {
			struct request_info req;

			request_init(&req, RQ_DAEMON, __progname, RQ_FILE, sock_in, 0);
			fromhost(&req);

			if (!hosts_access(&req)) {
				debug("Connection refused by tcp wrapper");
				refuse(&req);
				/* NOTREACHED */
				fatal("libwrap refuse returns");
			}
		}
	}
#endif /* LIBWRAP */

	/* Log the connection. */
	laddr = get_local_ipaddr(sock_in);
	verbose("Connection from %s port %d on %s port %d",
	    remote_ip, remote_port, laddr,  get_local_port());
	free(laddr);

#ifdef USE_SECURITY_SESSION_API
	/*
	 * Create a new security session for use by the new user login if
	 * the current session is the root session or we are not launched
	 * by inetd (eg: debugging mode or server mode).  We do not
	 * necessarily need to create a session if we are launched from
	 * inetd because Panther xinetd will create a session for us.
	 *
	 * The only case where this logic will fail is if there is an
	 * inetd running in a non-root session which is not creating
	 * new sessions for us.  Then all the users will end up in the
	 * same session (bad).
	 *
	 * When the client exits, the session will be destroyed for us
	 * automatically.
	 *
	 * We must create the session before any credentials are stored
	 * (including AFS pags, which happens a few lines below).
	 */
	{
		OSStatus err = 0;
		SecuritySessionId sid = 0;
		SessionAttributeBits sattrs = 0;

		err = SessionGetInfo(callerSecuritySession, &sid, &sattrs);
		if (err)
			error("SessionGetInfo() failed with error %.8X",
			    (unsigned) err);
		else
			debug("Current Session ID is %.8X / Session Attributes are %.8X",
			    (unsigned) sid, (unsigned) sattrs);

		if (inetd_flag && !(sattrs & sessionIsRoot))
			debug("Running in inetd mode in a non-root session... "
			    "assuming inetd created the session for us.");
		else {
			debug("Creating new security session...");
			err = SessionCreate(0, sessionHasTTY | sessionIsRemote);
			if (err)
				error("SessionCreate() failed with error %.8X",
				    (unsigned) err);

			err = SessionGetInfo(callerSecuritySession, &sid, 
			    &sattrs);
			if (err)
				error("SessionGetInfo() failed with error %.8X",
				    (unsigned) err);
			else
				debug("New Session ID is %.8X / Session Attributes are %.8X",
				    (unsigned) sid, (unsigned) sattrs);
		}
	}
#endif

	/*
	 * We don't want to listen forever unless the other side
	 * successfully authenticates itself.  So we set up an alarm which is
	 * cleared after successful authentication.  A limit of zero
	 * indicates no limit. Note that we don't set the alarm in debugging
	 * mode; it is just annoying to have the server exit just when you
	 * are about to discover the bug.
	 */
	signal(SIGALRM, grace_alarm_handler);
	if (!debug_flag)
		alarm(options.login_grace_time);

	sshd_exchange_identification(sock_in, sock_out);

	/* In inetd mode, generate ephemeral key only for proto 1 connections */
	if (!compat20 && inetd_flag && sensitive_data.server_key == NULL)
		generate_ephemeral_server_key();

	packet_set_nonblocking();

	/* allocate authentication context */
	authctxt = xcalloc(1, sizeof(*authctxt));

	authctxt->loginmsg = &loginmsg;

	/* XXX global for cleanup, access from other modules */
	the_authctxt = authctxt;

	/* prepare buffer to collect messages to display to user after login */
	buffer_init(&loginmsg);
	auth_debug_reset();

	if (use_privsep) {
		if (privsep_preauth(authctxt) == 1)
			goto authenticated;
	} else if (compat20 && have_agent) {
		if ((r = ssh_get_authentication_socket(&auth_sock)) != 0) {
			error("Unable to get agent socket: %s", ssh_err(r));
			have_agent = 0;
		}
	}

	/* perform the key exchange */
	/* authenticate user and start session */
	if (compat20) {
		do_ssh2_kex();
		do_authentication2(authctxt);
	} else {
#ifdef WITH_SSH1
		do_ssh1_kex();
		do_authentication(authctxt);
#else
		fatal("ssh1 not supported");
#endif
	}
	/*
	 * If we use privilege separation, the unprivileged child transfers
	 * the current keystate and exits
	 */
	if (use_privsep) {
		mm_send_keystate(pmonitor);
		packet_destroy_all(1, 1);
		exit(0);
	}

 authenticated:
	/*
	 * Cancel the alarm we set to limit the time taken for
	 * authentication.
	 */
	alarm(0);
	signal(SIGALRM, SIG_DFL);
	authctxt->authenticated = 1;
	if (startup_pipe != -1) {
		close(startup_pipe);
		startup_pipe = -1;
	}

#ifdef SSH_AUDIT_EVENTS
	audit_event(SSH_AUTH_SUCCESS);
#endif

#ifdef GSSAPI
	if (options.gss_authentication) {
		temporarily_use_uid(authctxt->pw);
		ssh_gssapi_storecreds();
		restore_uid();
	}
#endif
#ifdef USE_PAM
	if (options.use_pam) {
		do_pam_setcred(1);
		do_pam_session();
	}
#endif

	/*
	 * In privilege separation, we fork another child and prepare
	 * file descriptor passing.
	 */
	if (use_privsep) {
		privsep_postauth(authctxt);
		/* the monitor process [priv] will not return */
		if (!compat20)
			destroy_sensitive_data(0);
	}

	packet_set_timeout(options.client_alive_interval,
	    options.client_alive_count_max);

	/* Try to send all our hostkeys to the client */
	if (compat20)
		notify_hostkeys(active_state);

	/* Start session. */
	do_authenticated(authctxt);

	/* The connection has been terminated. */
	packet_destroy_all(1, 1);
	destroy_sensitive_data(1);

	packet_get_bytes(&ibytes, &obytes);
	verbose("Transferred: sent %llu, received %llu bytes",
	    (unsigned long long)obytes, (unsigned long long)ibytes);

	verbose("Closing connection to %.500s port %d", remote_ip, remote_port);

#ifdef USE_PAM
	if (options.use_pam)
		finish_pam();
#endif /* USE_PAM */

#ifdef SSH_AUDIT_EVENTS
	PRIVSEP(audit_event(SSH_CONNECTION_CLOSE));
#endif

	packet_close();

	if (use_privsep)
		mm_terminate();

	exit(0);
}

#ifdef WITH_SSH1
/*
 * Decrypt session_key_int using our private server key and private host key
 * (key with larger modulus first).
 */
int
ssh1_session_key(BIGNUM *session_key_int)
{
	int rsafail = 0;

	if (BN_cmp(sensitive_data.server_key->rsa->n,
	    sensitive_data.ssh1_host_key->rsa->n) > 0) {
		/* Server key has bigger modulus. */
		if (BN_num_bits(sensitive_data.server_key->rsa->n) <
		    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n) +
		    SSH_KEY_BITS_RESERVED) {
			fatal("do_connection: %s: "
			    "server_key %d < host_key %d + SSH_KEY_BITS_RESERVED %d",
			    get_remote_ipaddr(),
			    BN_num_bits(sensitive_data.server_key->rsa->n),
			    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n),
			    SSH_KEY_BITS_RESERVED);
		}
		if (rsa_private_decrypt(session_key_int, session_key_int,
		    sensitive_data.server_key->rsa) != 0)
			rsafail++;
		if (rsa_private_decrypt(session_key_int, session_key_int,
		    sensitive_data.ssh1_host_key->rsa) != 0)
			rsafail++;
	} else {
		/* Host key has bigger modulus (or they are equal). */
		if (BN_num_bits(sensitive_data.ssh1_host_key->rsa->n) <
		    BN_num_bits(sensitive_data.server_key->rsa->n) +
		    SSH_KEY_BITS_RESERVED) {
			fatal("do_connection: %s: "
			    "host_key %d < server_key %d + SSH_KEY_BITS_RESERVED %d",
			    get_remote_ipaddr(),
			    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n),
			    BN_num_bits(sensitive_data.server_key->rsa->n),
			    SSH_KEY_BITS_RESERVED);
		}
		if (rsa_private_decrypt(session_key_int, session_key_int,
		    sensitive_data.ssh1_host_key->rsa) != 0)
			rsafail++;
		if (rsa_private_decrypt(session_key_int, session_key_int,
		    sensitive_data.server_key->rsa) != 0)
			rsafail++;
	}
	return (rsafail);
}

/*
 * SSH1 key exchange
 */
static void
do_ssh1_kex(void)
{
	int i, len;
	int rsafail = 0;
	BIGNUM *session_key_int, *fake_key_int, *real_key_int;
	u_char session_key[SSH_SESSION_KEY_LENGTH];
	u_char fake_key_bytes[4096 / 8];
	size_t fake_key_len;
	u_char cookie[8];
	u_int cipher_type, auth_mask, protocol_flags;

	/*
	 * Generate check bytes that the client must send back in the user
	 * packet in order for it to be accepted; this is used to defy ip
	 * spoofing attacks.  Note that this only works against somebody
	 * doing IP spoofing from a remote machine; any machine on the local
	 * network can still see outgoing packets and catch the random
	 * cookie.  This only affects rhosts authentication, and this is one
	 * of the reasons why it is inherently insecure.
	 */
	arc4random_buf(cookie, sizeof(cookie));

	/*
	 * Send our public key.  We include in the packet 64 bits of random
	 * data that must be matched in the reply in order to prevent IP
	 * spoofing.
	 */
	packet_start(SSH_SMSG_PUBLIC_KEY);
	for (i = 0; i < 8; i++)
		packet_put_char(cookie[i]);

	/* Store our public server RSA key. */
	packet_put_int(BN_num_bits(sensitive_data.server_key->rsa->n));
	packet_put_bignum(sensitive_data.server_key->rsa->e);
	packet_put_bignum(sensitive_data.server_key->rsa->n);

	/* Store our public host RSA key. */
	packet_put_int(BN_num_bits(sensitive_data.ssh1_host_key->rsa->n));
	packet_put_bignum(sensitive_data.ssh1_host_key->rsa->e);
	packet_put_bignum(sensitive_data.ssh1_host_key->rsa->n);

	/* Put protocol flags. */
	packet_put_int(SSH_PROTOFLAG_HOST_IN_FWD_OPEN);

	/* Declare which ciphers we support. */
	packet_put_int(cipher_mask_ssh1(0));

	/* Declare supported authentication types. */
	auth_mask = 0;
	if (options.rhosts_rsa_authentication)
		auth_mask |= 1 << SSH_AUTH_RHOSTS_RSA;
	if (options.rsa_authentication)
		auth_mask |= 1 << SSH_AUTH_RSA;
	if (options.challenge_response_authentication == 1)
		auth_mask |= 1 << SSH_AUTH_TIS;
	if (options.password_authentication)
		auth_mask |= 1 << SSH_AUTH_PASSWORD;
	packet_put_int(auth_mask);

	/* Send the packet and wait for it to be sent. */
	packet_send();
	packet_write_wait();

	debug("Sent %d bit server key and %d bit host key.",
	    BN_num_bits(sensitive_data.server_key->rsa->n),
	    BN_num_bits(sensitive_data.ssh1_host_key->rsa->n));

	/* Read clients reply (cipher type and session key). */
	packet_read_expect(SSH_CMSG_SESSION_KEY);

	/* Get cipher type and check whether we accept this. */
	cipher_type = packet_get_char();

	if (!(cipher_mask_ssh1(0) & (1 << cipher_type)))
		packet_disconnect("Warning: client selects unsupported cipher.");

	/* Get check bytes from the packet.  These must match those we
	   sent earlier with the public key packet. */
	for (i = 0; i < 8; i++)
		if (cookie[i] != packet_get_char())
			packet_disconnect("IP Spoofing check bytes do not match.");

#ifdef SSH_AUDIT_EVENTS
	audit_kex(MODE_OUT, cipher_name(cipher_type), "crc", "none", "none");
#endif

	debug("Encryption type: %.200s", cipher_name(cipher_type));

	/* Get the encrypted integer. */
	if ((real_key_int = BN_new()) == NULL)
		fatal("do_ssh1_kex: BN_new failed");
	packet_get_bignum(real_key_int);

	protocol_flags = packet_get_int();
	packet_set_protocol_flags(protocol_flags);
	packet_check_eom();

	/* Setup a fake key in case RSA decryption fails */
	if ((fake_key_int = BN_new()) == NULL)
		fatal("do_ssh1_kex: BN_new failed");
	fake_key_len = BN_num_bytes(real_key_int);
	if (fake_key_len > sizeof(fake_key_bytes))
		fake_key_len = sizeof(fake_key_bytes);
	arc4random_buf(fake_key_bytes, fake_key_len);
	if (BN_bin2bn(fake_key_bytes, fake_key_len, fake_key_int) == NULL)
		fatal("do_ssh1_kex: BN_bin2bn failed");

	/* Decrypt real_key_int using host/server keys */
	rsafail = PRIVSEP(ssh1_session_key(real_key_int));
	/* If decryption failed, use the fake key. Else, the real key. */
	if (rsafail)
		session_key_int = fake_key_int;
	else
		session_key_int = real_key_int;

	/*
	 * Extract session key from the decrypted integer.  The key is in the
	 * least significant 256 bits of the integer; the first byte of the
	 * key is in the highest bits.
	 */
	(void) BN_mask_bits(session_key_int, sizeof(session_key) * 8);
	len = BN_num_bytes(session_key_int);
	if (len < 0 || (u_int)len > sizeof(session_key)) {
		error("do_ssh1_kex: bad session key len from %s: "
		    "session_key_int %d > sizeof(session_key) %lu",
		    get_remote_ipaddr(), len, (u_long)sizeof(session_key));
		rsafail++;
	} else {
		explicit_bzero(session_key, sizeof(session_key));
		BN_bn2bin(session_key_int,
		    session_key + sizeof(session_key) - len);

		derive_ssh1_session_id(
		    sensitive_data.ssh1_host_key->rsa->n,
		    sensitive_data.server_key->rsa->n,
		    cookie, session_id);
		/*
		 * Xor the first 16 bytes of the session key with the
		 * session id.
		 */
		for (i = 0; i < 16; i++)
			session_key[i] ^= session_id[i];
	}

	/* Destroy the private and public keys. No longer. */
	destroy_sensitive_data(1);

	if (use_privsep)
		mm_ssh1_session_id(session_id);

	/* Destroy the decrypted integer.  It is no longer needed. */
	BN_clear_free(real_key_int);
	BN_clear_free(fake_key_int);

	/* Set the session key.  From this on all communications will be encrypted. */
	packet_set_encryption_key(session_key, SSH_SESSION_KEY_LENGTH, cipher_type);

	/* Destroy our copy of the session key.  It is no longer needed. */
	explicit_bzero(session_key, sizeof(session_key));

	debug("Received session key; encryption turned on.");

	/* Send an acknowledgment packet.  Note that this packet is sent encrypted. */
	packet_start(SSH_SMSG_SUCCESS);
	packet_send();
	packet_write_wait();
}
#endif

int
sshd_hostkey_sign(Key *privkey, Key *pubkey, u_char **signature, size_t *slen,
    const u_char *data, size_t dlen, const char *alg, u_int flag)
{
	int r;
	u_int xxx_slen, xxx_dlen = dlen;

	if (privkey) {
		if (PRIVSEP(key_sign(privkey, signature, &xxx_slen, data, xxx_dlen,
		    alg) < 0))
			fatal("%s: key_sign failed", __func__);
		if (slen)
			*slen = xxx_slen;
	} else if (use_privsep) {
		if (mm_key_sign(pubkey, signature, &xxx_slen, data, xxx_dlen,
		    alg) < 0)
			fatal("%s: pubkey_sign failed", __func__);
		if (slen)
			*slen = xxx_slen;
	} else {
		if ((r = ssh_agent_sign(auth_sock, pubkey, signature, slen,
		    data, dlen, alg, datafellows)) != 0)
			fatal("%s: ssh_agent_sign failed: %s",
			    __func__, ssh_err(r));
	}
	return 0;
}

/* SSH2 key exchange */
static void
do_ssh2_kex(void)
{
	char *myproposal[PROPOSAL_MAX] = { KEX_SERVER };
	struct kex *kex;
	int r;
	char *s;

	/* Append EXT_INFO signalling to KexAlgorithms */
	if (options.kex_algorithms == NULL)
		s = strdup("kex-strict-s-v00@openssh.com");
	else
		s = kex_names_cat(options.kex_algorithms,
				  "kex-strict-s-v00@openssh.com");

	if (s == NULL)
		fatal("%s: kex_names_cat", __func__);

	myproposal[PROPOSAL_KEX_ALGS] = compat_kex_proposal(s);
	myproposal[PROPOSAL_ENC_ALGS_CTOS] = compat_cipher_proposal(
	    options.ciphers);
	myproposal[PROPOSAL_ENC_ALGS_STOC] = compat_cipher_proposal(
	    options.ciphers);
	myproposal[PROPOSAL_MAC_ALGS_CTOS] =
	    myproposal[PROPOSAL_MAC_ALGS_STOC] = options.macs;

	if (options.compression == COMP_NONE) {
		myproposal[PROPOSAL_COMP_ALGS_CTOS] =
		myproposal[PROPOSAL_COMP_ALGS_STOC] = "none";
	}

	if (options.rekey_limit || options.rekey_interval)
		packet_set_rekey_limits(options.rekey_limit,
		    (time_t)options.rekey_interval);

	myproposal[PROPOSAL_SERVER_HOST_KEY_ALGS] = compat_pkalg_proposal(
	    list_hostkey_types());

#ifdef GSSAPI
	{
	char *orig;
	char *gss = NULL;
	char *newstr = NULL;
	orig = myproposal[PROPOSAL_KEX_ALGS];

	/* 
	 * If we don't have a host key, then there's no point advertising
	 * the other key exchange algorithms
	 */

	if (strlen(myproposal[PROPOSAL_SERVER_HOST_KEY_ALGS]) == 0)
		orig = NULL;

	if (options.gss_keyex)
		gss = ssh_gssapi_server_mechanisms();
	else
		gss = NULL;

	if (gss && orig)
		xasprintf(&newstr, "%s,%s", gss, orig);
	else if (gss)
		newstr = gss;
	else if (orig)
		newstr = orig;

	/* 
	 * If we've got GSSAPI mechanisms, then we've got the 'null' host
	 * key alg, but we can't tell people about it unless its the only
  	 * host key algorithm we support
	 */
	if (gss && (strlen(myproposal[PROPOSAL_SERVER_HOST_KEY_ALGS])) == 0)
		myproposal[PROPOSAL_SERVER_HOST_KEY_ALGS] = "null";

	if (newstr)
		myproposal[PROPOSAL_KEX_ALGS] = newstr;
	else
		fatal("No supported key exchange algorithms");
	}
#endif

	/* start key exchange */
	if ((r = kex_setup(active_state, myproposal)) != 0)
		fatal("kex_setup: %s", ssh_err(r));
	kex = active_state->kex;
#ifdef WITH_OPENSSL
	kex->kex[KEX_DH_GRP1_SHA1] = kexdh_server;
	kex->kex[KEX_DH_GRP14_SHA1] = kexdh_server;
	kex->kex[KEX_DH_GEX_SHA1] = kexgex_server;
	kex->kex[KEX_DH_GEX_SHA256] = kexgex_server;
# ifdef OPENSSL_HAS_ECC
	kex->kex[KEX_ECDH_SHA2] = kexecdh_server;
# endif
#endif
	kex->kex[KEX_C25519_SHA256] = kexc25519_server;
#ifdef GSSAPI
	if (options.gss_keyex) {
		kex->kex[KEX_GSS_GRP1_SHA1] = kexgss_server;
		kex->kex[KEX_GSS_GRP14_SHA1] = kexgss_server;
		kex->kex[KEX_GSS_GEX_SHA1] = kexgss_server;
	}
#endif
	kex->server = 1;
	kex->client_version_string=client_version_string;
	kex->server_version_string=server_version_string;
	kex->load_host_public_key=&get_hostkey_public_by_type;
	kex->load_host_private_key=&get_hostkey_private_by_type;
	kex->host_key_index=&get_hostkey_index;
	kex->sign = sshd_hostkey_sign;

	dispatch_run(DISPATCH_BLOCK, &kex->done, active_state);

	session_id2 = kex->session_id;
	session_id2_len = kex->session_id_len;

#ifdef DEBUG_KEXDH
	/* send 1st encrypted/maced/compressed message */
	packet_start(SSH2_MSG_IGNORE);
	packet_put_cstring("markus");
	packet_send();
	packet_write_wait();
#endif
	debug("KEX done");
}

/* server specific fatal cleanup */
void
cleanup_exit(int i)
{
	static int in_cleanup = 0;
	int is_privsep_child;

	/* cleanup_exit can be called at the very least from the privsep
	   wrappers used for auditing.  Make sure we don't recurse
	   indefinitely. */
	if (in_cleanup)
		_exit(i);
	in_cleanup = 1;

	if (the_authctxt) {
		do_cleanup(the_authctxt);
		if (use_privsep && privsep_is_preauth &&
		    pmonitor != NULL && pmonitor->m_pid > 1) {
			debug("Killing privsep child %d", pmonitor->m_pid);
			if (kill(pmonitor->m_pid, SIGKILL) != 0 &&
			    errno != ESRCH)
				error("%s: kill(%d): %s", __func__,
				    pmonitor->m_pid, strerror(errno));
		}
	}
	is_privsep_child = use_privsep && pmonitor != NULL && pmonitor->m_pid == 0;
	if (sensitive_data.host_keys != NULL)
		destroy_sensitive_data(is_privsep_child);
	packet_destroy_all(1, is_privsep_child);
#ifdef SSH_AUDIT_EVENTS
	/* done after do_cleanup so it can cancel the PAM auth 'thread' */
	if ((the_authctxt == NULL || !the_authctxt->authenticated) &&
	    (!use_privsep || mm_is_monitor()))
		audit_event(SSH_CONNECTION_ABANDON);
#endif
	_exit(i);
}
