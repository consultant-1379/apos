#	$OpenBSD: keyscan.sh,v 1.5 2015/09/11 03:44:21 djm Exp $
#	Placed in the Public Domain.

tid="keyscan"

KEYTYPES=`${SSH} -Q key-plain | sed -e '/^null$/d'`
for i in $KEYTYPES; do
	if [ -z "$algs" ]; then
		algs="$i"
	else
		algs="$algs,$i"
	fi
done
echo "HostKeyAlgorithms $algs" >> sshd_config

cat sshd_config

start_sshd

if ssh_version 1; then
	KEYTYPES="${KEYTYPES} rsa1"
fi

for t in $KEYTYPES; do
	trace "keyscan type $t"
	${SSHKEYSCAN} -t $t -p $PORT 127.0.0.1 127.0.0.1 127.0.0.1 \
		> /dev/null 2>&1
	r=$?
	if [ $r -ne 0 ]; then
		fail "ssh-keyscan -t $t failed with: $r"
	fi
done
