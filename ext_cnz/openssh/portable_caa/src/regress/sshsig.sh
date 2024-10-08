#	$OpenBSD: sshsig.sh,v 1.1 2019/09/03 08:37:45 djm Exp $
#	Placed in the Public Domain.

tid="sshsig"

DATA2=$OBJ/${DATANAME}.2
cat ${DATA} ${DATA} > ${DATA2}

rm -f $OBJ/sshsig-*.sig $OBJ/wrong-key* $OBJ/sigca-key*

sig_namespace="test-$$"
sig_principal="user-$$@example.com"

# Make a "wrong key"
${SSHKEYGEN} -t ed25519 -f $OBJ/wrong-key -C "wrong trousers, Grommit" -N '' \
	|| fatal "couldn't generate key"
WRONG=$OBJ/wrong-key.pub

# Make a CA key.
${SSHKEYGEN} -t ed25519 -f $OBJ/sigca-key -C "CA" -N '' \
	|| fatal "couldn't generate key"
CA_PRIV=$OBJ/sigca-key
CA_PUB=$OBJ/sigca-key.pub

SIGNKEYS="$SSH_KEYTYPES"
verbose "$tid: make certificates"
for t in $SSH_KEYTYPES ; do
	[ "$t" != rsa1 ] || continue
	${SSHKEYGEN} -q -s $CA_PRIV -z $$ \
	    -I "regress signature key for $USER" \
	    -n $sig_principal $OBJ/${t} || \
		fatal "couldn't sign ${t}"
	SIGNKEYS="$SIGNKEYS ${t}-cert.pub"
done

for t in $SIGNKEYS; do
	[ "$t" != rsa1 ] || continue
	verbose "$tid: check signature for $t"
	keybase=`basename $t .pub`
	sigfile=${OBJ}/sshsig-${keybase}.sig
	pubkey=${OBJ}/${keybase}.pub

	${SSHKEYGEN} -vvv -Y sign -f ${OBJ}/$t -n $sig_namespace \
		< $DATA > $sigfile 2>/dev/null || fail "sign using $t failed"

	(printf "$sig_principal " ; cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 || \
		fail "failed signature for $t key"

	(printf "$sig_principal namespaces=\"$sig_namespace,whatever\" ";
	 cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 || \
		fail "failed signature for $t key w/ limited namespace"

	# Invalid option
	(printf "$sig_principal octopus " ; cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t key with bad signers option"

	# Wrong key trusted.
	(printf "$sig_principal " ; cat $WRONG) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t key with wrong key trusted"

	# incorrect data
	(printf "$sig_principal " ; cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA2 >/dev/null 2>&1 && \
		fail "passed signature for wrong data with $t key"

	# wrong principal in signers
	(printf "josef.k@example.com " ; cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t key with wrong principal"

	# wrong namespace
	(printf "$sig_principal " ; cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n COWS_COWS_COWS \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t key with wrong namespace"

	# namespace excluded by option
	(printf "$sig_principal namespaces=\"whatever\" " ;
	 cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t key with excluded namespace"

	# Remaining tests are for certificates only.
	case "$keybase" in
		*-cert) ;;
		*) continue ;;
	esac

	# correct CA key
	(printf "$sig_principal cert-authority " ;
	 cat $CA_PUB) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 || \
		fail "failed signature for $t cert"

	# signing key listed as cert-authority
	(printf "$sig_principal cert-authority" ;
	 cat $pubkey) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature with $t key listed as CA"

	# CA key not flagged cert-authority
	(printf "$sig_principal " ; cat $CA_PUB) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t cert with CA not marked"

	# mismatch between cert principal and file
	(printf "josef.k@example.com cert-authority" ;
	 cat $CA_PUB) > $OBJ/allowed_signers
	${SSHKEYGEN} -vvv -Y verify -s $sigfile -n $sig_namespace \
		-I $sig_principal -f $OBJ/allowed_signers \
		< $DATA >/dev/null 2>&1 && \
		fail "accepted signature for $t cert with wrong principal"
done

# XXX test keys in agent.
# XXX test revocation

