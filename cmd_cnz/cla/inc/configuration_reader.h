#ifndef _CONFIGURATION_READER_H
#define _CONFIGURATION_READER_H

#include <string>

typedef enum {
	STARTTLS,
	LDAPS,
	NO_TLS
} TlsMode_t;

typedef enum {
	DEMAND,
	ALLOW,
	TRY,
	NEVER,
	HARD
} RequiredCert_t;

class ConfigurationReader {
public:
	inline ConfigurationReader() : _tls_mode(LDAPS) {}
	inline virtual ~ConfigurationReader () {}

	int load_configuration (const char * configuration_file = DEFAULT_SSSD_CONFIGURATION_FILE);
	inline std::string get_ldap_uri () const { return _ldap_uri; }
	inline std::string get_bind_dn () const { return _bind_dn; }
	inline std::string get_bind_password () const { return _bind_password; }
	inline TlsMode_t get_tls_mode () const { return _tls_mode; }
	inline std::string get_ca_cert_dir () const { return _ca_cert_dir; }
	inline std::string get_ca_certificate () const { return _ca_certificate; }
	inline std::string get_client_certificate () const { return _client_certificate; }
	inline std::string get_client_key () const { return _client_key; }
	inline std::string get_cipher_filter () const { return _cipher_filter; }

private:
	bool configuration_file_exists (const char * configuration_file);
	int parse_configuration_item (const std::string & configuration_item, std::string & item_name, std::string & item_value);

private:
	static const char * const DEFAULT_SSSD_CONFIGURATION_FILE;
	static const char * const LDAP_URI_ATTRIBUTE_NAME;
	static const char * const LDAP_BIND_DN_ATTRIBUTE_NAME;
	static const char * const LDAP_BIND_PASSWORD_ATTRIBUTE_NAME;
	static const char * const LDAP_TLS_MODE_ATTRIBUTE_NAME;
	static const char * const LDAP_CA_CERT_DIRECTORY_ATTRIBUTE_NAME;
	static const char * const LDAP_CA_CERTIFICATE_ATTRIBUTE_NAME;
	static const char * const LDAP_CLIENT_CERTIFICATE_ATTRIBUTE_NAME;
	static const char * const LDAP_CLIENT_KEY_ATTRIBUTE_NAME;
	static const char * const LDAP_CIPHER_FILTER_ATTRIBUTE_NAME;

	std::string _ldap_uri;
	std::string _bind_dn;
	std::string _bind_password;
	TlsMode_t _tls_mode;
	std::string _ca_cert_dir;
	std::string _ca_certificate;
	std::string _client_certificate;
	std::string _client_key;
	std::string _cipher_filter;
};

#endif // _CONFIGURATION_READER_H
