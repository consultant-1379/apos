# $Id: Makefile.in,v 1.56 2014/09/30 23:43:08 djm Exp $

sysconfdir=/etc/ssh
piddir=/var/run
srcdir=.
top_srcdir=..


APGINCLUDE=-I/app/APG43L/SDK/LDE/4_27_0_20/usr/lib64/gcc/x86_64-suse-linux/4.8/include\
        -I/app/APG43L/SDK/LDE/4_27_0_20/usr/lib64/glib-2.0/include\
        -I/app/APG43L/SDK/LDE/4_27_0_20/usr/include\
        -I/app/APG43L/SDK/LDE/4_27_0_20/usr/x86_64-suse-linux/include\
        -I/app/APG43L/SDK/LDE/4_27_0_20/usr/X11R6/include\ -I/app/APG43L/SDK/LDE/4_27_0_20/usr/local/include
#CC=/app/APG43L/SDK/dx_btd/1_13/compilers/bin/x86_64-dx-linux-gnu-gcc
#LD=/app/APG43L/SDK/dx_btd/1_13/compilers/bin/x86_64-dx-linux-gnu-gcc
CFLAGS=-g -O2 -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wsizeof-pointer-memaccess -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -DERICSSON_PATCH_ENABLED=1 -ftrapv -fno-builtin-memset -fstack-protector-all -fPIE 
CPPFLAGS=-I. -I.. -I$(srcdir) -I$(srcdir)/.. ${APGINCLUDE} -DLDAP_DEPRECATED -DHAVE_CONFIG_H
LIBS=-lcrypto -ldl -lldap -llber -lutil -lz  -lcrypt -lresolv
AR=ar
RANLIB=ranlib
INSTALL=/usr/bin/install -c
LDFLAGS=-L. -L/app/APG43L/SDK/LDE/4_27_0_20/lib64 -L/app/APG43L/SDK/LDE/4_27_0_20/lib -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -fstack-protector-all -pie

OPENBSD=base64.o basename.o bcrypt_pbkdf.o bindresvport.o blowfish.o daemon.o dirname.o fmt_scaled.o getcwd.o getgrouplist.o getopt_long.o getrrsetbyname.o glob.o inet_aton.o inet_ntoa.o inet_ntop.o mktemp.o pwcache.o readpassphrase.o reallocarray.o realpath.o recallocarray.o rresvport.o setenv.o setproctitle.o sha1.o sha2.o rmd160.o md5.o sigact.o strlcat.o strlcpy.o strmode.o strnlen.o strptime.o strsep.o strtonum.o strtoll.o strtoul.o strtoull.o timingsafe_bcmp.o vis.o blowfish.o bcrypt_pbkdf.o explicit_bzero.o freezero.o

COMPAT=arc4random.o bsd-asprintf.o bsd-closefrom.o bsd-cray.o bsd-cygwin_util.o bsd-getpeereid.o getrrsetbyname-ldns.o bsd-getpagesize.o bsd-misc.o bsd-nextstep.o bsd-openpty.o bsd-poll.o bsd-setres_id.o bsd-snprintf.o bsd-statvfs.o bsd-waitpid.o fake-rfc2553.o openssl-compat.o xcrypt.o kludge-fd_set.o

PORTS=port-aix.o port-irix.o port-linux.o port-linux-prng.o port-solaris.o port-tun.o port-uw.o

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $<

all: libopenbsd-compat.a

$(COMPAT): ../config.h
$(OPENBSD): ../config.h
$(PORTS): ../config.h

libopenbsd-compat.a:  $(COMPAT) $(OPENBSD) $(PORTS)
	$(AR) rv $@ $(COMPAT) $(OPENBSD) $(PORTS)
	$(RANLIB) $@

clean:
	rm -f *.o *.a core 

distclean: clean
	rm -f Makefile *~
