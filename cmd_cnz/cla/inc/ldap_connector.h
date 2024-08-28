#ifndef _LDAP_CONNECTOR_H
#define _LDAP_CONNECTOR_H

#include <ldap.h>

#include "configuration_reader.h"

class LdapConnector {
public:
	inline LdapConnector (int timeout = DEFAULT_TIMEOUT_VALUE) : _ldap_handle(0), _timeout(timeout) {}
	inline virtual ~LdapConnector () { disconnect(); }
	int check_ldap_server_availability (const ConfigurationReader & configuration_reader);

private:
	int connect (const std::string ldap_uri);
	void disconnect ();
	int set_api_timeout ();
	int set_network_timeout ();
	int set_ca_cert_dir (const std::string & ca_cert_dir);
	int set_ca_certificate (const std::string & ca_certificate);
	int set_client_certificate (const std::string & client_certificate);
	int set_client_key (const std::string & client_key);
	int set_cipher_suite (const std::string & cipher_suite);
	int set_require_cert (const RequiredCert_t required_cert = DEMAND);
	int create_ssl_context ();
	int bind (const TlsMode_t tls_mode, const std::string & bind_dn, const std::string & bind_password);
	int ping ();

private:
	static const int DEFAULT_TIMEOUT_VALUE = 3;

	LDAP * _ldap_handle;
	int _timeout;
};

#endif // _LDAP_CONNECTOR_H
