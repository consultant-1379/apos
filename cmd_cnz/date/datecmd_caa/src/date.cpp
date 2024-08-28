//----------------------------------------------------------------------------------------
//
//  FILE
//      date.cpp
//
//  COPYRIGHT
//      Copyright Ericsson AB 2012. All rights reserved.
//      
//      The Copyright to the computer program(s) herein is the property of
//      Ericsson AB, Sweden. The program(s) may be used and/or copied only
//      with the written permission from Ericsson AB or in accordance with
//      the terms and conditions stipulated in the agreement/contract under
//      which the program(s) have been supplied.
//
//  DESCRIPTION
//      This is a console program for reading system clock from both AP nodes 
//      or setting system time and hardware clock in both nodes.
//
//  ERROR HANDLING
//      -
//
//  DOCUMENT NO
//      -
//
//  AUTHOR
//      EAB/FLE/EM UABTSO (Thomas Olsson)
//
//  REVISION HISTORY
//      Rev.   Date         Prepared    Description
//      ----   ----         --------    -----------
//      PA1    2012-07-27   UABTSO      New design.
//		  PA2	   2012-08-06	 UABMAGN		 Changed to using ping to verify if the 
//                                      passive node is available
//		  PA3	   2012-11-19	 UABTSO		 Suppress path printout when giving illegal
//                                      option.
//
//  SEE ALSO
//      -
//
//---------------------------------------------------------------------------------------- 

#include <string>
#include <iostream>
#include <sstream>
#include <getopt.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

using namespace std;

//----------------------------------------------------------------------------------------
// Execute shell command
//----------------------------------------------------------------------------------------
int executeCommand(const string& command, string& printout)
{
	//cout << "Exceuting command: " << command << endl;	// ***
   printout.clear();
	int pdes[2];

	if (pipe(pdes) < 0)
	{
		return -1;
	}

	int pid = vfork();
	uid_t uid = getuid();
	switch (pid)
	{
	case -1: // Error
		close(pdes[0]);
		close(pdes[1]);
		return -1;

	case 0: // Child process
		if (pdes[1] != STDOUT_FILENO)
		{
			dup2(pdes[1], STDOUT_FILENO);
			close(pdes[1]);
		}
		close(pdes[0]);

		setuid(0);
		execl("/bin/sh", "sh", "-c", (command + " 2>&1").c_str(), NULL);
		setuid(uid);
		_exit(127);
	}

	// Parent process
	setuid(uid);
	FILE* fd = fdopen(pdes[0], "r");
	close(pdes[1]);
	if (fd == NULL)
	{
		ostringstream s;
		s << "Failed to launch command '" << command << "'." << endl;
		s << strerror(errno);
		printout = s.str();
		return -1;
	}

   char cbuf[512];
	while (fgets(cbuf, 511, fd) != NULL)
	{
		printout.append(cbuf);
	}

	fclose(fd);

	int tpid;
	int pstat;
	do
	{
		tpid = waitpid(pid, &pstat, 0);
	}
	while (tpid == -1 && errno == EINTR);

	return (tpid != -1)? WIFEXITED(pstat)? WEXITSTATUS(pstat): -1: -1;
}

//----------------------------------------------------------------------------------------
// Command usage
//----------------------------------------------------------------------------------------
void usage(bool verbose = false)
{
   cout << "usage: date [-s DATE][-u][\"+FORMAT\"]" << endl;
   cout << "       date -h" << endl;
	cout << endl;
	if (verbose == false)
	{
		cout << "Type \"date -h\" for detailed help on the command" << endl;
	}
	else
	{
		cout << "-s DATE   Set the system time and hw clock in both nodes." << endl;
		cout << "-u        Read or set the time in UTC format." << endl;
		cout << "\"+FORMAT\" Display the time in both nodes in the given FORMAT." << endl;
		cout << "-h        Display this help."	<< endl;
		cout << endl;
		cout << "The command reads the system time from both nodes or sets the system time"
			  << endl;
		cout << "and hardware clock. The command must be executed from the active node." 
			  << endl;
		cout << endl;
	}
	cout << endl;
}

//----------------------------------------------------------------------------------------
// Main program
//----------------------------------------------------------------------------------------
int main(int argc, char* argv[])
{
	const char s_date[] = "/bin/date";
	const char s_hwclock[] = "/sbin/hwclock";
	const char s_ssh[] = "/usr/bin/ssh";
	
	enum t_faultcode
	{
		e_ok = 0,
		e_execfault = 1,
		e_usage = 2,
		e_standbyunavailable = 3
	};

	int c;
	string date;
	string format;

	// Parse command
	bool set = false;
	bool utc = false;
	bool help = false;
	while (true)
	{
		opterr = 0;
		c = getopt(argc, argv, "s:uh");
		if (c == -1)
			break;

		switch (c)
		{
		case 's':
			set = true;
			date = optarg;
			break;

		case 'u':
			utc = true;
			break;

		case 'h':
			help = true;
			break;

		case '?':
			cerr << "Invalid option -- '" << char(optopt) << "'" << endl;
			usage();
			return e_usage;
		}
	}

	if (optind < argc)
	{
		format = argv[optind];
		size_t pos = format.find_first_not_of(' ');
		format.erase(0, pos);
		if (format[0] != '+')
		{
			cerr << "Incorrect usage" << endl;
			usage();
			return e_usage;
		}
		optind++;
	}

	if (optind < argc)
	{
		cerr << "Incorrect usage" << endl;
		usage();
		return e_usage;
	}

	// Execute command
	enum
	{
		e_this,
		e_peer
	};

	if (help == true)
	{
		if (set || utc || (format.empty() == false))
		{
			cerr << "Incorrect usage" << endl;
			usage();
			return e_usage;
		}
		usage(true);
		return e_ok;
	}

	int ret;
	string printout;
	string result;

	if (set == false)
	{
		ostringstream cmd;

		// Read date from this node
		cmd << s_date;
		if (utc == true)
		{
			cmd << " -u";
		}
		if (format.empty() == false)
		{
			cmd << " \"" << format << "\"";
		}

		ret = executeCommand(cmd.str(), printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}
		result = printout;
	}
	else
	{
		// Get path to peer node
		ret = executeCommand("cat /etc/cluster/nodes/peer/hostname", printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}

		string peernode;
		size_t size = printout.size();
		if (size != string::npos)
		{
			peernode = printout.erase(size - 1); // Remove CR;
		}
		else
		{
			cerr << "The date cannot be set, the other side is not available" << endl << endl;
			return e_standbyunavailable;
		}

		ret = executeCommand("ls /etc/cluster/nodes/peer/ip", printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}

		string peerip;

		string space("\n");
		size_t found;

		found = printout.find(space);

		if (found == string::npos)
		{
			cerr << "The date cannot be set, the other side is not available" << endl << endl;
			return e_standbyunavailable;
		}

		peerip = printout.substr(0, (int) found);

		ret = executeCommand("/bin/ping -c 1 " + peerip, printout);
		if (ret == -1)
		{
			cerr << printout << endl;
			return e_execfault;
		}

		string sup("bytes from");

		found = printout.find(sup);

		if (found == string::npos)
		{
			cerr << "The date cannot be set, the other side is not available" << endl << endl;
			return e_standbyunavailable;
		}

		enum
		{
			e_settime, e_hwclock
		};

		ostringstream cmd[2][2];

		// Set date on this node
		cmd[e_settime][e_this] << s_date;
		if (date.empty() == false)
		{
			cmd[e_settime][e_this] << " -s \"" << date << "\"";
		}
		if (utc == true)
		{
			cmd[e_settime][e_this] << " -u";
		}
		if (format.empty() == false)
		{
			cmd[e_settime][e_this] << " \"" << format << "\"";
		}

		ret = executeCommand(cmd[e_settime][e_this].str(), printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}
		result = printout;

		// Set date on peer node
		cmd[e_settime][e_peer] << "ssh " << peernode << " '"
				<< cmd[e_settime][e_this].str() << "'";

		ret = executeCommand(cmd[e_settime][e_peer].str(), printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}

		// Set HW clock on this node
		cmd[e_hwclock][e_this] << s_hwclock << " -w";
		ret = executeCommand(cmd[e_hwclock][e_this].str(), printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}

		// Set HW clock on peer node
		string printout;
		cmd[e_hwclock][e_peer] << s_ssh << " " << peernode << " '"
				<< cmd[e_hwclock][e_this].str() << "'";
		ret = executeCommand(cmd[e_hwclock][e_peer].str(), printout);
		if (ret != 0)
		{
			cerr << printout << endl;
			return e_execfault;
		}
	}
	cout << result << endl;

	return e_ok;
}
