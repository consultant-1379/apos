#include "common.h"
#include "ldap_connector.h"

int LdapConnector::check_ldap_server_availability (const ConfigurationReader & configuration_reader) {
	// First, set the timeout for the API calls
	int call_result = 0;
	if ((call_result = set_api_timeout())) {
		ERROR_LOG("Call 'set_api_timeout' failed!");
		return -1;
	}

	// Second, set the timeout for network operations
	if ((call_result = set_network_timeout())) {
		ERROR_LOG("Call 'set_network_timeout' failed!");
		return -2;
	}

	// Connect to the remote LDAP server
	const std::string & ldap_uri = configuration_reader.get_ldap_uri();
	DEBUG_LOG("Connecting to remote LDAP server using the URI '%s'.", ldap_uri.c_str());
	if ((call_result = connect(ldap_uri))) {
		ERROR_LOG("Call 'connect' failed with error_code == %d.", call_result);
		return -3;
	}

	// In case of LDAP over TLS, set the needed certificates information
	if (configuration_reader.get_tls_mode() != NO_TLS) {
		const std::string & ca_certificate = configuration_reader.get_ca_certificate();

		if (!ca_certificate.empty()) {
			if ((call_result = set_ca_certificate(ca_certificate))) {
				ERROR_LOG("Call 'set_ca_certificate' failed with error_code == %d.", call_result);
				return call_result;
			}
		}
		else {
			if ((call_result = set_ca_cert_dir(configuration_reader.get_ca_cert_dir()))) {
				ERROR_LOG("Call 'set_ca_cert_dir' failed with error_code == %d.", call_result);
				return call_result;
			}
		}

		set_client_certificate(configuration_reader.get_client_certificate());

		set_client_key(configuration_reader.get_client_key());

		if ((call_result = set_cipher_suite(configuration_reader.get_cipher_filter()))) {
			ERROR_LOG("Call 'set_cipher_suite' failed with error_code == %d.", call_result);
			return call_result;
		}

		if ((call_result = set_require_cert())) {
			ERROR_LOG("Call 'set_require_cert' failed with error_code == %d.", call_result);
			return call_result;
		}

		if ((call_result = create_ssl_context())) {
			ERROR_LOG("Call 'create_ssl_context' failed with error_code == %d.", call_result);
			return call_result;
		}
	}

	// Bind to the remote LDAP server
	if ((call_result = bind(configuration_reader.get_tls_mode(), configuration_reader.get_bind_dn(), configuration_reader.get_bind_password()))) {
		ERROR_LOG("Call 'bind' failed with error_code == %d.", call_result);
		return call_result;
	}

	// Ping  the remote LDAP server in order to understand if it's up & running
	if ((call_result = ping())) {
		ERROR_LOG("Call 'ping' failed with error_code == %d.", call_result);
		return call_result;
	}

	// Operation completed, disconnect from server
	disconnect();
	return 0;
}

int LdapConnector::connect (const std::string ldap_uri) {
	// Check that a correct URI has been provided
	if (ldap_uri.empty()) {
		ERROR_LOG("Empty URI provided!");
		return -1;
	}

	// Check if another connection has been already exectued
	if (_ldap_handle) {
		ERROR_LOG("Object already connected!");
		return -2;
	}

	// Initialize a LDAP session
	int call_result = 0;
	if ((call_result = ::ldap_initialize(&_ldap_handle, ldap_uri.c_str())) != LDAP_SUCCESS) {
		ERROR_LOG("Call 'ldap_initialize' failed for uri == '%s', with erorr_code == %d.", ldap_uri.c_str(), call_result);
		return -3;
	}

	// Set the options about the protocols versions
	const int protocol_version = 3;
	if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_PROTOCOL_VERSION, &protocol_version)) != LDAP_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_PROTOCOL_VERSION with error_code == %d.", call_result);
		return -4;
	}

	const int tls_min_protocol_version = LDAP_OPT_X_TLS_PROTOCOL_TLS1_0;
	if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_PROTOCOL_MIN, &tls_min_protocol_version)) != LDAP_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_PROTOCOL_MIN with error_code == %d.", call_result);
		return -5;
	}
	return 0;
}

void LdapConnector::disconnect () {
	// First, check if a disconnect operation was already executed
	if (!_ldap_handle)	return;

	// Execute the unbind operation to free allocated resources
	DEBUG_LOG("Unbinding from remote server.");
	int call_result = 0;
	if ((call_result = ::ldap_unbind_ext_s(_ldap_handle, 0, 0)) != LDAP_SUCCESS) {
		ERROR_LOG("Call 'ldap_unbind_ext_s' failed with error_code == %d.", call_result);
	}

	_ldap_handle = 0;
}

int LdapConnector::set_api_timeout () {
	struct timeval timevalue;
    timevalue.tv_sec = _timeout;
    timevalue.tv_usec = (500 * 1000);	// _timeout value + 0,5 seconds

    // Set the LDAP_OPT_TIMEOUT option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_TIMEOUT option to '%d' (+ 0,5 secs).", _timeout);
    int call_result = 0;
    if ((call_result = ::ldap_set_option(0, LDAP_OPT_TIMEOUT, &timevalue)) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_TIMEOUT with error_code == %d.", call_result);
    	return call_result;
    }
    return 0;
}

int LdapConnector::set_network_timeout () {
	struct timeval timevalue;
    timevalue.tv_sec = _timeout;
    timevalue.tv_usec = 0;

    // Set the LDAP_OPT_NETWORK_TIMEOUT option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_NETWORK_TIMEOUT option to '%d'.", _timeout);
    int call_result = 0;
    if ((call_result = ::ldap_set_option(0, LDAP_OPT_NETWORK_TIMEOUT, &timevalue)) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_NETWORK_TIMEOUT with error_code == %d.", call_result);
    	return call_result;
    }
    return 0;
}

int LdapConnector::set_ca_cert_dir (const std::string & ca_cert_dir) {
	// First, check that a correct value has been provided
	if (ca_cert_dir.empty()) {
		ERROR_LOG("Empty value provided!");
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_CACERTDIR option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_CACERTDIR option to '%s'.", ca_cert_dir.c_str());
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_CACERTDIR, ca_cert_dir.c_str())) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_CACERTDIR with error_code == %d.", call_result);
    	return call_result;
    }
    return 0;
}

int LdapConnector::set_ca_certificate (const std::string & ca_certificate) {
	// First, check that a correct value has been provided
	if (ca_certificate.empty()) {
		ERROR_LOG("Empty value provided!");
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_CACERTFILE option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_CACERTFILE option to '%s'.", ca_certificate.c_str());
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_CACERTFILE, ca_certificate.c_str())) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_CACERTFILE with error_code == %d.", call_result);
    	return call_result;
    }
	return 0;
}

int LdapConnector::set_client_certificate (const std::string & client_certificate) {
	// First, check that a correct value has been provided
	if (client_certificate.empty()) {
		ERROR_LOG("Empty value provided!");
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_CERTFILE option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_CERTFILE option to '%s'.", client_certificate.c_str());
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_CERTFILE, client_certificate.c_str())) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_CERTFILE with error_code == %d.", call_result);
    	return call_result;
    }
	return 0;
}

int LdapConnector::set_client_key (const std::string & client_key) {
	// First, check that a correct value has been provided
	if (client_key.empty()) {
		ERROR_LOG("Empty value provided!");
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_KEYFILE option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_KEYFILE option to '%s'.", client_key.c_str());
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_KEYFILE, client_key.c_str())) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_KEYFILE with error_code == %d.", call_result);
    	return call_result;
    }
	return 0;
}

int LdapConnector::set_cipher_suite (const std::string & cipher_suite) {
	// First, check that a correct value has been provided
	if (cipher_suite.empty()) {
		ERROR_LOG("Empty value provided!");
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_CIPHER_SUITE option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_CIPHER_SUITE option to '%s'.", cipher_suite.c_str());
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_CIPHER_SUITE, cipher_suite.c_str())) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_CIPHER_SUITE with error_code == %d.", call_result);
    	return call_result;
    }
	return 0;
}

int LdapConnector::set_require_cert (const RequiredCert_t required_cert) {
	int option_value = 0;
	switch (required_cert) {
	case DEMAND:
		option_value = LDAP_OPT_X_TLS_DEMAND;
		break;
	case ALLOW:
		option_value = LDAP_OPT_X_TLS_ALLOW;
		break;
	case TRY:
		option_value = LDAP_OPT_X_TLS_TRY;
		break;
	case NEVER:
		option_value = LDAP_OPT_X_TLS_NEVER;
		break;
	case HARD:
		option_value = LDAP_OPT_X_TLS_HARD;
		break;
	default:
		ERROR_LOG("Bad value provided (%d)!", required_cert);
		return -1;
	}

    // Set the LDAP_OPT_X_TLS_REQUIRE_CERT option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_REQUIRE_CERT option to '%d'.", option_value);
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_REQUIRE_CERT, &option_value)) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_REQUIRE_CERT with error_code == %d.", call_result);
    	return call_result;
    }
	return 0;
}

int LdapConnector::create_ssl_context () {
	const int create_server_context = 0;

    // Set the LDAP_OPT_X_TLS_NEWCTX option as a global option
    DEBUG_LOG("Setting the LDAP_OPT_X_TLS_NEWCTX option to '%d'.", create_server_context);
    int call_result = 0;
    if ((call_result = ::ldap_set_option(_ldap_handle, LDAP_OPT_X_TLS_NEWCTX, &create_server_context)) != LDAP_OPT_SUCCESS) {
    	ERROR_LOG("Call 'ldap_set_option' failed for option LDAP_OPT_X_TLS_NEWCTX with error_code == %d.", call_result);
    	return call_result;
    }
    return 0;
}

int LdapConnector::bind (const TlsMode_t tls_mode, const std::string & bind_dn, const std::string & bind_password) {
	int call_result = 0;

	// First, check that a connection operation has been performed
	if (!_ldap_handle) {
		ERROR_LOG("Connector object is not connected!");
		return -1;
	}

	// Only in case of STARTTLS mode, a TLS session must be initiated
	if (tls_mode == STARTTLS) {
		if ((call_result = ::ldap_start_tls_s(_ldap_handle, 0, 0)) != LDAP_SUCCESS) {
			if (call_result == LDAP_LOCAL_ERROR) {
				DEBUG_LOG("TLS is already in place, nothing to do!");
			}
			else {
				ERROR_LOG("Call 'ldap_start_tls_s' failed with error_code == %d, ldap_error == '%s'.", call_result, ::ldap_err2string(call_result));
				return call_result;
			}
		}
	}

	// Prepare the data structures to execute the bind operation
	const size_t bind_pwd_len = bind_password.length();
	char bind_pwd[bind_pwd_len + 1];
	::strncpy(bind_pwd, bind_password.c_str(), bind_pwd_len);
	bind_pwd[bind_pwd_len] = 0;

	struct berval creds;
	creds.bv_val = bind_pwd;
	creds.bv_len = bind_pwd_len;

	DEBUG_LOG("Executing bind operation using DN == '%s'.", bind_dn.c_str());
	if ((call_result = ::ldap_sasl_bind_s(_ldap_handle, bind_dn.c_str(), 0, &creds, 0, 0, 0)) != LDAP_SUCCESS) {
		ERROR_LOG("Binding to remote LDAP server using DN == '%s' failed with error_code == %d!", bind_dn.c_str(), call_result);
		return call_result;
	}

	DEBUG_LOG("Bind operation correctly executed.");
	return 0;
}

int LdapConnector::ping () {
	// First, check that a connection operation has been performed
	if (!_ldap_handle) {
		ERROR_LOG("Connector object is not connected!");
		return -1;
	}

	// Executing the LDAP search operation to ping the remote LDAP server
	DEBUG_LOG("Executing a LDAP query on root object.");
	int call_result = 0;
	LDAPMessage * search_response = 0;
	if ((call_result = ::ldap_search_ext_s(_ldap_handle, 0, LDAP_SCOPE_BASE, 0, 0 , 0, 0, 0, 0, 0, &search_response)) != LDAP_SUCCESS) {
		ERROR_LOG("Call 'ldap_search_ext_s' failed with error_code == %d.", call_result);
		ERROR_LOG("The remote LDAP server is NOT REACHABLE!");
	}
	else {
		DEBUG_LOG("The remote LDAP server is reachable.");
	}

	(search_response) && ::ldap_msgfree(search_response);
	return ((call_result == LDAP_SUCCESS) ? 0 : call_result);
}
