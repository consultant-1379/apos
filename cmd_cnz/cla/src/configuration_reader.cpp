#include <sys/stat.h>
#include <errno.h>

#include <string>
#include <fstream>
#include <algorithm>

#include "common.h"
#include "configuration_reader.h"

const char * const ConfigurationReader::DEFAULT_SSSD_CONFIGURATION_FILE        = "/etc/sssd/sssd.conf";
const char * const ConfigurationReader::LDAP_URI_ATTRIBUTE_NAME                = "ldap_uri";
const char * const ConfigurationReader::LDAP_BIND_DN_ATTRIBUTE_NAME            = "ldap_default_bind_dn";
const char * const ConfigurationReader::LDAP_BIND_PASSWORD_ATTRIBUTE_NAME      = "ldap_default_authtok";
const char * const ConfigurationReader::LDAP_TLS_MODE_ATTRIBUTE_NAME           = "tls_mode";
const char * const ConfigurationReader::LDAP_CA_CERT_DIRECTORY_ATTRIBUTE_NAME  = "ldap_tls_cacertdir";
const char * const ConfigurationReader::LDAP_CA_CERTIFICATE_ATTRIBUTE_NAME     = "ldap_tls_cacert";
const char * const ConfigurationReader::LDAP_CLIENT_CERTIFICATE_ATTRIBUTE_NAME = "ldap_tls_cert";
const char * const ConfigurationReader::LDAP_CLIENT_KEY_ATTRIBUTE_NAME         = "ldap_tls_key";
const char * const ConfigurationReader::LDAP_CIPHER_FILTER_ATTRIBUTE_NAME      = "ldap_tls_cipher_suite";

int ConfigurationReader::load_configuration (const char * configuration_file) {
	// Check if the provided configuration file exists
	DEBUG_LOG("Checking if the configuration file '%s' exists.", configuration_file);
	if (!configuration_file_exists(configuration_file)) {
		ERROR_LOG("The configuration file '%s' doesn't exist!", configuration_file);
		return -1;
	}

	// The file exists: let's open it
	DEBUG_LOG("Opening the configuration file '%s'.", configuration_file);
	std::ifstream ifs;
	ifs.open(configuration_file, std::ifstream::in);

	// Check if the file has been correctly opened
	DEBUG_LOG("Checking that the configuration file '%s' has been correctly opened.", configuration_file);
	if (!ifs.is_open()) {
		ERROR_LOG("Failed to open the configuration file '%s'!", configuration_file);
		ifs.close();
		return -2;
	}

	// Once the file has been correctly opened, extract all the interesting data from it
	std::string line;
	bool ldap_domain_found = false;

	DEBUG_LOG("Extracting data from the configuration file '%s'.", configuration_file);
	while (ifs.good()) {
		std::getline(ifs, line);

		// Skip empty lines and comments lines
		if ((line.empty()) || (line[0] == '#'))
			continue;

		/*
		 * The configuration file is built of many different domains.
		 * Extract the interesting information only for the LDAP domain.
		 * The search will stop in two different cases:
		 * 		1. End of the file.
		 * 		2. New domain found after the LDAP one has been found.
		 */
		const bool domain_line_found = (line.find("[domain/") != std::string::npos);
		if (domain_line_found && ldap_domain_found) {
			// New domain found but LDAP domain was previously found: break loop!
			DEBUG_LOG("A new domain has been found, but the LDAP domain was previously found: no more data to be read.");
			break;
		}
		else if (domain_line_found && !ldap_domain_found && (line.find("[domain/LdapAuthenticationMethod]") != std::string::npos)) {
			DEBUG_LOG("LDAP domain section found: starting to read its data.");
			ldap_domain_found = true;
			continue;
		}

		if (ldap_domain_found) {
			// The current line belongs to the LDAP domain section: read the configuration data
			std::string item_name, item_value;
			if (parse_configuration_item(line, item_name, item_value)) {
				ERROR_LOG("Failed to parse the configuration item from line '%s'.", line.c_str());
				continue;
			}

			// Store the found pair into the correct attribute
			if (!item_name.compare(LDAP_URI_ATTRIBUTE_NAME))
				_ldap_uri = item_value;
			else if (!item_name.compare(LDAP_BIND_DN_ATTRIBUTE_NAME))
				_bind_dn = item_value;
			else if (!item_name.compare(LDAP_BIND_PASSWORD_ATTRIBUTE_NAME))
				_bind_password = item_value;
			else if (!item_name.compare(LDAP_TLS_MODE_ATTRIBUTE_NAME))
				_tls_mode = static_cast<TlsMode_t>(std::stoi(item_value));
			else if (!item_name.compare(LDAP_CA_CERT_DIRECTORY_ATTRIBUTE_NAME))
				_ca_cert_dir = item_value;
			else if (!item_name.compare(LDAP_CA_CERTIFICATE_ATTRIBUTE_NAME))
				_ca_certificate = item_value;
			else if (!item_name.compare(LDAP_CLIENT_CERTIFICATE_ATTRIBUTE_NAME))
				_client_certificate = item_value;
			else if (!item_name.compare(LDAP_CLIENT_KEY_ATTRIBUTE_NAME))
				_client_key = item_value;
			else if (!item_name.compare(LDAP_CIPHER_FILTER_ATTRIBUTE_NAME))
				_cipher_filter = item_value;
		}
	}

	// Close the configuration file handle
	ifs.close();
	return 0;
}

bool ConfigurationReader::configuration_file_exists (const char * configuration_file) {
	// First check that the file exists
	DEBUG_LOG("Checking if a file system object exists with the following name '%s'.", configuration_file);
	struct stat file_info;
	if (::stat(configuration_file, &file_info)) {
		const int errno_save = errno;
		ERROR_LOG("Call 'stat' failed for file '%s': errno == %d.", configuration_file, errno_save);
		return false;
	}

	// Second, check that the file is a regular file
	DEBUG_LOG("Checking that the following file '%s' is a regular file.", configuration_file);
	if (!(file_info.st_mode & S_IFREG)) {
		ERROR_LOG("The file '%s': is not a regular file (mode == %x).", configuration_file, file_info.st_mode);
		return false;
	}
	return true;
}

int ConfigurationReader::parse_configuration_item (const std::string & configuration_item, std::string & item_name, std::string & item_value) {
	// First, remove spaces from the input string
	std::string item = configuration_item;
//	item.erase(std::remove(item.begin(), item.end(), ' '), item.end());

	/*
	 * Each item is a couple having the following format:
	 * 		name=value
	 * Extract the two parts using the '=' as token
	 */
	const size_t equal_pos = item.find_first_of('=');
	if (equal_pos == std::string::npos) {
		ERROR_LOG("The provided string (%s) is not a valid configuration item.", configuration_item.c_str());
		return -1;
	}

	item_name = item.substr(0, equal_pos);
	item_name.erase(std::find_if(item_name.rbegin(), item_name.rend(), std::bind1st(std::not_equal_to<char>(), ' ')).base(), item_name.end());
	item_value = item.substr(equal_pos + 1);
	item_value.erase(item_value.begin(), std::find_if(item_value.begin(), item_value.end(), std::bind1st(std::not_equal_to<char>(), ' ')));
	//TR:IA65840 : Sensitive info should not be logged
	if (item_name.compare(LDAP_BIND_PASSWORD_ATTRIBUTE_NAME)) {
		DEBUG_LOG("Parsed data: ITEM_NAME == '%s', ITEM_VALUE == '%s'", item_name.c_str(), item_value.c_str());
	}
	return 0;
}
