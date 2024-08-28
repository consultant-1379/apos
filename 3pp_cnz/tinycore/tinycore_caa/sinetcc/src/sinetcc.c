/*****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2017
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 -------------------------------------------------------------------------*//*
  *
  * @file sinetcc.c
  *
  * @brief
  * This is the main file that is responsible for communication with netconf server.
  * This command gets an xml file, assemples a netconf query 
  * values and sends rpc messages to netconf server.
  *
  * @author Antonio Buoncounto (eanbuon)
  *
 ------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <time.h>
#include <stdarg.h>
#include <sys/stat.h>

#define __USE_GNU
#include <poll.h>


#define CONNECT_TIMOUT		2		// seconds
#define MAX_ATTEMPTS		20
#define POLL_TIMEOUT		200		// milliseconds
#define RECV_RETRY_INTERVAL	100000 	// microseconds
// max number of bytes we can get at once
#define MAXDATASIZE		4096
#define MEID		"#MEID"
const char LOG_FILE_HEADER[] =
{
		"******************************************\n"
		"**                                      **\n"
		"**      SMART IMAGE NETCONF CLIENT      **\n"
		"**                                      **\n"
		"******************************************\n"
};

const char HELLO_MESSAGE[] =
{
		"<hello xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n"
		"<capabilities>\n"
		"<capability>\n"
		"urn:ietf:params:netconf:base:1.0\n"
		"</capability>\n"
		"</capabilities>\n"
		"</hello>\n"
		"]]>]]>\n"
};

const char GET_MANAGED_ELEMENT_ID_MESSAGE[] =
{
		"<rpc message-id=\"1\" xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n"
		"<get>\n"
		"<filter type=\"subtree\">\n"
		"<ManagedElement>\n"
		"<managedElementId/>\n"
		"</ManagedElement>\n"
		"</filter>\n"
		"</get>\n"
		"</rpc>\n"
		"]]>]]>\n"
};

const char EDIT_CONFIG_PREFIX[] =
{
		"<rpc message-id=\"2\" xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n"
		"<edit-config>\n"
		"<config>\n"
};

const char EDIT_CONFIG_SUFFIX[] =
{
		"\n</config>\n"
		"</edit-config>\n"
		"</rpc>\n"
		"]]>]]>\n"
};

const char CLOSE_MESSAGE[] =
{
		"<rpc message-id=\"3\" xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n"
		"<close-session/>\n"
		"</rpc>\n"
		"]]>]]>\n"
};

const char MEID_TAG[] 	= "<managedElementId>";
const char OK_RESP[] 	= "<ok/>";
const char EOM[] 		= "]]>]]>";

/* Input parameter */
struct param
{
	char place_card[128];
	char value[128];
};

struct param meid 		=  {MEID, ""};

int sockfd 		= -1;	// socket file descriptor
FILE* logfile 	= 0;	// log file pointer
int logging 	= 0;	// flag for turn off/on logging

void _log_(const char* fmt, ...)
{
	if (fmt != NULL)
	{
		va_list argp;
		va_start(argp, fmt);
		vfprintf(logfile, fmt, argp);
		va_end(argp);
	}
}

#define LOG(FMT...) ({ \
		if (logging){ \
			_log_(FMT); \
		}}) \

int recv_msg(char* buff, size_t buff_size, int error_on_connection_closure)
{
	int attempts = 0;
	int numbytes = 0;
	//size_t buff_size = MAXDATASIZE;
	size_t msg_size = 0;

	// Initialize the pollfd structure
	const nfds_t nfds = 1;
	struct pollfd fds[nfds];
	memset(fds, 0, sizeof(fds));
 
	// Socket handle
	fds[0].fd = sockfd;
	fds[0].events = POLLIN | POLLRDHUP | POLLERR;
	int poll_res;
	/*
	 * Waiting data to read on socket. More efficient than
	 * sleep or call at once recv() retrying cyclically.
	 *
	 */


	do
	{
		poll_res = poll(fds, nfds, POLL_TIMEOUT);
		if ( poll_res == -1 )
		{
			LOG ("\nFailure while polling\n");
			attempts++;
		} else if ( poll_res == 0 )
		{
			LOG ("\nPolling timeout expired\n");
			attempts++;
		}
		else
		{
			if((fds[0].revents & POLLERR) && error_on_connection_closure)
			{
				LOG("\nError while polling\n");
				return -1;
			}
			else if((fds[0].revents & POLLRDHUP) && error_on_connection_closure)
			{
				LOG("\nSocket peer closed connection\n");
				return -1;
			}
			else if(fds[0].revents & POLLIN)
			{
				LOG("\nThere is data to read on socket\n");
				if((numbytes = recv(sockfd, buff + msg_size, buff_size - msg_size, MSG_DONTWAIT)) <= 0)
				{
					usleep(RECV_RETRY_INTERVAL);
					attempts++;
					if(errno == EAGAIN)
						continue;

					if(attempts == MAX_ATTEMPTS)
					{
						LOG("\nrecv() failed!\n");
						return -1;
					}
					LOG("\nrecv() failed, trying again...\n");
					continue;
				}
				else
				{
					LOG("\nBytes received: %i\n", numbytes);
					msg_size += numbytes;
					if(strstr(buff, EOM))
					{
						break;
					}
					else
						continue;
				}
			}
		}
	}
	while (attempts <= MAX_ATTEMPTS);

	return 0;
}

int send_msg(char* buff)
{
	if (write(sockfd, buff, strlen(buff)) == -1)
	{
		LOG("\nWriting to socket failed, errno[%i]: %s\n", errno, strerror(errno));
		return -1;
	}
	return 0;
}

/*-----------------------------------------------------------------------
 * Start netconf session by receiving and answering to hello message
-----------------------------------------------------------------------*/
int handle_hello_netconf_message()
{
	LOG("\nHandling HELLO message...\n");

	char buff[MAXDATASIZE] = {0};

	if(recv_msg(buff, MAXDATASIZE, 1) < 0)
		return -1;

	LOG("\nMessage received:\n\n%s\n", buff);

	memset(buff, 0, strlen(buff));
	sprintf(buff, HELLO_MESSAGE);
	LOG("\nThe message being sent:\n\n%s\n", buff);

	if(send_msg(buff) < 0)
		return -1;

	LOG("\nNetconf session established\n");
	return 0;
}

/*-----------------------------------------------------------------------
 * Create socket connection to netconf server
-----------------------------------------------------------------------*/
int client_connect(const char* ipaddress, const char* port)
{
	LOG("\nConnecting to netconf server...\n");

	struct addrinfo* addr_info;
	struct addrinfo hints;
	int rc;

	// Set to 0 each field in the hints structure and then select to retrieve only IPv4 and TCP addresses
	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;

	if ((rc = getaddrinfo(ipaddress, 0, &hints, &addr_info)) != 0)
	{
		LOG("\nError on getaddrinfo(): %s\n", gai_strerror(rc));
		return -1;
	}

	struct sockaddr_in server;
	memset(&server,'\0',sizeof(struct sockaddr_in));

	memcpy((struct sockaddr *)(&server), addr_info->ai_addr, sizeof(struct sockaddr));
	freeaddrinfo(addr_info);

	server.sin_family = AF_INET;
	server.sin_port = htons(atoi(port));

	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		LOG("\nSocket creation failed\n");
		return -1;
	}

	/* Getting the socket properties before setting the socket non blocking */
	int flags;
	if ((flags = fcntl(sockfd, F_GETFL, NULL)) < 0)
	{
		LOG("\nError on fcntl(..., F_GETFL): %s\n", strerror(errno));
		return -1;
	}
	/* Setting the socket non blocking */
	if ((fcntl(sockfd, F_SETFL, O_NONBLOCK)) < 0)
	{
		LOG("\nError on fcntl(..., F_SETFL): %s\n", strerror(errno));
		return -1;
	}

	errno = 0;
	/* Connecting to the ip address */
	if ((connect(sockfd, (struct sockaddr*)(&server), sizeof(struct sockaddr_in))) < 0)
	{
		const int errno_save = errno;
		if (errno_save != EINPROGRESS)
		{
			close(sockfd);
			LOG("\nConnect failed, errno: %i\n", errno_save);
			return -1;
		}

		// waiting for connect to complete
		struct timeval tval;
		tval.tv_usec = 0;
		tval.tv_sec = CONNECT_TIMOUT;

		fd_set wset;
		FD_ZERO(&wset);
		FD_SET(sockfd, &wset);

		if (select(sockfd+1, (fd_set*)0, &wset, (fd_set*)0, &tval) <= 0)
		{
			//timeout or select error
			close(sockfd);
			LOG("\nTimeout or error on select(), errno[%i]: %s\n", errno, strerror(errno));
			return -1;
		}

		int so_error = 0;
		socklen_t len = sizeof(so_error);
		getsockopt(sockfd, SOL_SOCKET, SO_ERROR, (void *)&so_error, &len);
		if (so_error)
		{
			close(sockfd);
			LOG("\nConnection error: %s\n", strerror(so_error));
			return -1;
		}
	}

	/*
	 * connect() successful, setting the sock of blocking type
	 */
	if ((fcntl(sockfd, F_SETFL, flags)) < 0)
	{
		close(sockfd);
		LOG("Error on fcntl(..., F_SETFL): %s\n", strerror(errno));
		return -1;
	}

	// Connection established, ready for transaction
	LOG("\nConnection established\n");
	return 0;
}

/*-----------------------------------------------------------------------
 * Supporting function for Knuth-Morris-Pratt pattern searching
 * algorithm. Called only from kmp_search function
-----------------------------------------------------------------------*/
int* compute_prefix_function(char *pattern, int psize)
{
	int k = -1;
	int i = 1;
	int *pi = malloc(sizeof(int)*psize);
	if (!pi)
		return NULL;

	pi[0] = k;
	for (i = 1; i < psize; i++) {
		while (k > -1 && pattern[k+1] != pattern[i])
			k = pi[k];
		if (pattern[i] == pattern[k+1])
			k++;
		pi[i] = k;
	}
	return pi;
}

/*-----------------------------------------------------------------------
 * Utility function Knuth-Morris-Pratt pattern searching algorithm.
 * Search for occurrences of word "pattern" with length psize in
 * text "target" of length tsize. Return the index of the first
 * occurrence of word "pattern" in "target" buffer.
-----------------------------------------------------------------------*/
int kmp_search(char *target, int tsize, char *pattern, int psize)
{
	int i;
	int *pi = compute_prefix_function(pattern, psize);
	int k = -1;
	if (!pi)
		return -1;
	for (i = 0; i < tsize; i++) {
		while (k > -1 && pattern[k+1] != target[i])
			k = pi[k];
		if (target[i] == pattern[k+1])
			k++;
		if (k == psize - 1) {
			free(pi);
			return i-k;
		}
	}
	free(pi);
	return -1;
}

/*-----------------------------------------------------------------------
 * Load and parse xml template file replacing empty tags with provided
 * values and saving it into memory buffer for subsequent netconf query
-----------------------------------------------------------------------*/
int fill_xml_template(char* filename, char* xmlbuff)
{
	LOG("\nFilling xml template...\n");

	/* Load file into memory buffer */
	FILE* fp = fopen(filename, "r");
	if(fp == NULL)
	{
		LOG("\nErron while opening xml template file: %s\n", strerror(errno));
		return -1;
	}

	/* Parse xml template line by line replacing place cards with provided values */
	char tmpXmlLineFirstPart[MAXDATASIZE] = {0};
	char* tmpXmlLineSecondPart = 0;
	char line[MAXDATASIZE] = {0};
	char reworkedLine[MAXDATASIZE] = {0};
	while(fgets(line, MAXDATASIZE, fp) != 0)
	{
		int j = 0;
		j = kmp_search(line, strlen(line), meid.place_card, strlen(meid.place_card));
		if( j != -1)
		{
			strncpy(tmpXmlLineFirstPart, line, j);
			tmpXmlLineSecondPart = &line[(j + strlen(meid.place_card))];
			snprintf(reworkedLine, sizeof(reworkedLine), "%s%s%s", tmpXmlLineFirstPart, meid.value, tmpXmlLineSecondPart);
			memset(line, 0, strlen(line));
			strcpy(line, reworkedLine);
		}

		// Append line into xmlbuff
		strcat(xmlbuff, line);

		// Reset buffers
		memset(tmpXmlLineFirstPart, 0, strlen(tmpXmlLineFirstPart));
		tmpXmlLineSecondPart = 0;
		memset(reworkedLine, 0, strlen(reworkedLine));
		memset(line, 0, strlen(line));
	}
	fclose(fp);
	LOG("\nXml template filled:\n\n%s\n", xmlbuff);
	return 0;
}

/*-----------------------------------------------------------------------
 * Get the managedElementId value from server reply
-----------------------------------------------------------------------*/
int extract_meid(char* resp, char* meid_value)
{
	char* pch1;

	pch1 = strstr(resp, MEID_TAG);
	if (pch1 == NULL)
	{
		LOG("\nManaged Element ID not received\n");
		return -1;
	}

	strtok(pch1, "<>");
	strcpy(meid_value, strtok(NULL, "<>"));

	LOG("\nManaged Element ID received: %s\n", meid_value);

	return 0;
}

/*-----------------------------------------------------------------------
 * Send <get> netconf query to netconf server and parse
 * server reply for retrieving managedElementId value
-----------------------------------------------------------------------*/
int get_managedelement_id()
{
	LOG("\nGetting Managed Element ID...\n");
	char buff[MAXDATASIZE] = {0};

	sprintf(buff, GET_MANAGED_ELEMENT_ID_MESSAGE);
	LOG("\nThe message being sent:\n\n%s\n", buff);

	if(send_msg(buff) < 0)
		return -1;

	memset(buff, 0, strlen(buff));
	if(recv_msg(buff, MAXDATASIZE, 1) < 0)
		return -1;

	LOG("\nMessage received:\n\n%s\n", buff);

	if(extract_meid(buff, meid.value) < 0)
		return -1;
	return 0;
}

/*-----------------------------------------------------------------------
 * Check presence of <ok/> tag in the netconf server rpc reply
-----------------------------------------------------------------------*/
int check_ok_resp(char* xmlbuff)
{
	int pch;
	pch = kmp_search(xmlbuff, strlen(xmlbuff), (char*)OK_RESP, strlen(OK_RESP));
	if (pch == -1)
	{
		LOG("\nError: netconf transaction failed\n");
		return -1;
	}

	LOG("\nNetconf transaction successfull\n");
	return 0;
}

/*-----------------------------------------------------------------------
 * Send <edit-config> netconf query to netconf server providing
 * the updated xml configuration information
-----------------------------------------------------------------------*/
int send_edit_config_query(char* xmlbuff, int xmlbuff_size)
{
	LOG("\nSending edit config query...\n");
	// Assemble netconf query
	int buff_size = xmlbuff_size * 2;
	char *edit_config_query = (char*) malloc(buff_size);
	
	//char edit_config_query [MAXDATASIZE] = {0};
	snprintf(edit_config_query, buff_size, "%s%s%s", EDIT_CONFIG_PREFIX, xmlbuff, EDIT_CONFIG_SUFFIX);

	LOG("\nThe message being sent:\n\n%s\n", edit_config_query);
	if(send_msg(edit_config_query) < 0)
		return -1;
	memset(edit_config_query, 0, buff_size);
	
	if(recv_msg(edit_config_query, buff_size, 1) < 0)
		return -1;
	LOG("\nMessage received:\n\n%s\n", edit_config_query);

	if(check_ok_resp(edit_config_query) < 0)
		return -1;

	free(edit_config_query);
	return 0;
}

/*-----------------------------------------------------------------------
 * Send <close-session> netconf query to netconf server in order
 * to commit config operations and to close netconf session
-----------------------------------------------------------------------*/
int close_session()
{
	LOG("\nClosing netconf session...\n");
	char buff[MAXDATASIZE] = {0};

	// Send netconf close session message
	sprintf(buff, CLOSE_MESSAGE);
	LOG("\nThe message being sent:\n\n%s\n", buff);
	if(send_msg(buff) < 0)
		return -1;

	// Receive netconf server reply
	memset(buff, 0, strlen(buff));
	if(recv_msg(buff, MAXDATASIZE, 0) < 0)
		return -1;

	LOG("\nMessage received:\n\n%s\n", buff);

	if(check_ok_resp(buff) < 0)
		return -1;

	return 0;
}

void open_log_file()
{
	logfile = fopen("smartImage.log", "a");
}

void print_usage()
{
	puts("Usage:");
	puts(" sinetcc");
	puts("");
	puts("Options:");
	puts(" -s <ip address>          netconf server ip address");
	puts(" -p <port>                netconf server port number");
	puts(" -m                       fetch the managed element id");
	puts(" -f <xml-file>            xml file to be used inside netconf transaction");
	puts(" -d <value>               turn off(0)/on(1) logging for debugging");
	puts("");
	exit(EXIT_FAILURE);
}


int main(int argc, char* argv[])
{
	char ipaddress[15] = {0};
	char port[5] = {0};
	char xml_template[128] = {0};

	int option_m = 0, option_s = 0, option_p = 0, option_f = 0, option_d = 0, i = 0;
	int result = EXIT_SUCCESS;

	if (argc < 2)
		print_usage();
	for (i = 1; i < argc; i++)
	{
		if(strcmp(argv[i], "-s") == 0)
		{
			strcpy(ipaddress, argv[++i]);
			option_s = 1;
		}
		else if (strcmp(argv[i], "-m") == 0)
		{
			option_m = 1;
		}
		else if (strcmp(argv[i], "-p") == 0)
		{
			strcpy(port, argv[++i]);
			option_p = 1;
		}
		else if (strcmp(argv[i], "-f") == 0)
		{
			strcpy(xml_template, argv[++i]);
			option_f = 1;
		}
		else if (strcmp(argv[i], "-d") == 0)
		{
			if(strcmp(argv[++i], "0") != 0)
				logging = 1;

			option_d = 1;
		}
	}
	
	/* Validate options */
	if (!option_s || !option_p || !option_d)
		print_usage();

	if (!option_m)
	{
	  if (!option_f)
		print_usage();
	}else
	{
	  if (option_f)
		print_usage();	
	}
		
	if(logging)
		open_log_file();

	LOG(LOG_FILE_HEADER);
	LOG("\nStarting...\n");

	/* connect to NETCONF server */
	if(client_connect(ipaddress, port) < 0)
	{
		result = EXIT_FAILURE;
		close(sockfd);
		return result;
	}
	/* start netconf session */
	if(handle_hello_netconf_message() < 0)
	{
		result = EXIT_FAILURE;
		close(sockfd);
		return result;
	}
	/* ask for managedElementId */
	if(get_managedelement_id() < 0)
	{
		result = EXIT_FAILURE;
		close(sockfd);
		return result;
	}
	if (!option_m)
	{
		/* fill xml template file and save it into memory buffer */
		struct stat template_st;
		stat(xml_template, &template_st);
		int buff_size = template_st.st_size * sizeof(char) * 2;
		char *xmlbuff = (char*) malloc( buff_size );
		if(fill_xml_template(xml_template, xmlbuff) < 0)
		{
			result = EXIT_FAILURE;
			close(sockfd);
			return result;
		}
		/* send config parameters to netconf server */
		if(send_edit_config_query(xmlbuff, buff_size) < 0)
		{
			result = EXIT_FAILURE;
			close(sockfd);
			return result;
		}
		free(xmlbuff);
	}else
	{
	  printf("MEID:%s",meid.value);
	}
	/* finally, close session to commit operations*/
	if(close_session() < 0) 
		result = EXIT_FAILURE;
	
	// Close socket file descriptor
	close(sockfd);
	LOG("\nExiting...\n\n");

	// Close log file descriptor
	if(logging)
		fclose(logfile);
	return result;
}

