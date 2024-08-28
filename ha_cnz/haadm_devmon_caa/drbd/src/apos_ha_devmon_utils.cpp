/****************************************************************************
 *
 * COPYRIGHT Ericsson Telecom AB 2013
 *
 * The copyright of the computer program herein is the property of
 * Ericsson Telecom AB. The program may be used and/or copied only with the
 * written permission from Ericsson Telecom AB or in the accordance with the
 * terms and conditions stipulated in the agreement/contract under which the
 * program has been supplied.
 *
 ----------------------------------------------------------------------*//**
 *
 * @file apos_ha_devmon_utils.cpp
 *
 * @brief
 * 
 * This class is used as a generic utility class. It checks the physical
 * components of the node viz., name, architecture etc.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/
#include "apos_ha_devmon_utils.h"
#include <sstream>

//-------------------------------------------------------------------------
HA_DEVMON_Utils::HA_DEVMON_Utils():
 ap_1(false),
 ap_2(false),
 Gep1flag(false),
 Gep2flag(false),
 Gep4flag(false),
 Gep5flag(false),
 m_globalInstance(HA_DEVMON_Global::instance())
{
	HA_TRACE_ENTER();
    
    HA_TRACE_LEAVE();     	
}

//-------------------------------------------------------------------------
HA_DEVMON_Utils::~HA_DEVMON_Utils()
{
    HA_TRACE_ENTER();
    
    HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_DEVMON_Utils::init()
{
	HA_TRACE_ENTER();
    ACE_INT32 rCode=0;
    
	/* populate Ap details first */
    if (Ap()  <  0)
        rCode=-1;
        
    /* popluate Gep revisions */
    if (rCode == 0) {
        if (Gep() < 0)
            rCode=-1;
    }            
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_Utils::Ap()
{
	HA_TRACE_ENTER();
    FILE* fp;
	ACE_TCHAR buff[10];
    ACE_UINT32 node_id;
    ACE_INT32 rCode=0;

	fp = ACE_OS::fopen(APOS_HA_FILE_NODE_ID,"r");
	if (fp == NULL) {
		HA_LG_ER("%s(): Error! fopen FAILED", __func__);
		rCode=-1;
	}

    if (rCode == 0) {
        if (fscanf(fp ,"%10s" ,buff) != 1 ) {
            (void)fclose(fp);
            HA_LG_ER("%s(): Unable to Retreive the node id from file [ %s ]" , 
            __func__, APOS_HA_FILE_NODE_ID);
            rCode=-1;
        }
    }
			
	if (rCode == 0) {
        if (ACE_OS::fclose(fp) != 0 ) {
            HA_LG_ER("%s(): Error! fclose FAILED", __func__);
            rCode=-1;
        }
	}
    
	if (rCode == 0) {
        node_id= ACE_OS::atoi(buff);
        if (node_id == APOS_HA_NODE_ONE)
            ap_1=true;
        else if (node_id == APOS_HA_NODE_TWO)
            ap_2=true;
        else {
            HA_LG_ER("%s(): Invalide node identification received!", __func__);
            rCode=-1;
        }
        HA_TRACE_1("%s(): Running on NODE:%d", __func__, node_id);    
    }
	
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_Utils::Gep()
{
    ACE_INT32 rCode=0;
	HA_TRACE_ENTER();
    // Do we really need to know the Gep version??

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
void HA_DEVMON_Utils::msec_sleep(ACE_UINT32 msecs)
{
    HA_TRACE_ENTER();
    struct timeval tv;

	tv.tv_sec = msecs / 1000;
	tv.tv_usec = ((msecs) % 1000) * 1000;

	while (select(0, 0, 0, 0, &tv) != 0)
	       if (errno == EINTR)
	           continue;
    
    HA_TRACE_LEAVE();
}
//-------------------------------------------------------------------------
int HA_DEVMON_Utils::_execlp(const char *cmdStr)
{
    HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

    int status;
    pid_t pid = fork();
    if (pid == 0) {
        ACE_OS::alarm(m_globalInstance->Config()->getConfig().callbackTmout/APOS_HA_ONESEC_IN_MILLI - 1);
        if(execlp("sh","sh", "-c", cmdStr, (char *) NULL) == -1) {
            HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
            rCode=-1;
        }
    } else { if (pid < 0) {
                HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
                rCode=-1;
            }
    }

    if (rCode != -1) {
        waitpid(pid, &status, 0);

        if (status != 0) {
            rCode=-1;
            HA_LG_ER("HA_DEVMON_Utils:%s() cmdStr [%s] Failed, rCode:[%d]", __func__, cmdStr, status);
        }
    }
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_Utils::_execvp(char *const argv[], char **outstr)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	int fds[2];
    int status=0;

	if (pipe(fds) < 0) {
		HA_LG_ER("HA_DEVMON_Utils:%s() pipe failed. %d", __func__, errno);
		rCode=-1;
	}
	if (rCode == 0) {
		pid_t pid = fork();

		if (rCode == 0) {
			if (pid < 0) {
				HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
				rCode=-1;
			} else if (pid == 0) {
				ACE_OS::alarm(m_globalInstance->Config()->getConfig().callbackTmout/APOS_HA_ONESEC_IN_MILLI - 1);
				dup2(fds[1], STDOUT_FILENO);
				close(fds[0]);
				if( execvp(argv[0], argv) == -1) {
					HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error execvp failed. %d", __func__, errno);
					rCode=-1;
				}
				close(fds[1]);
				exit(0);
			}  else {
				close(fds[1]);
				fd_set readfdset, writefdset, excepfdset;
				FD_ZERO(&readfdset);
				FD_ZERO(&writefdset);
				FD_ZERO(&excepfdset);
				FD_SET(fds[0], &readfdset);

				//select call will be infinite call and in the worst case, callbacktimeout
				//is triggered to let coremw to take the proper action.
				int ret = select(fds[0]+1, &readfdset, &writefdset, &excepfdset,0);
				if (ret >  0 && FD_ISSET(fds[0], &readfdset)) {
					FILE *fp = fdopen(fds[0], "r");
					size_t len = 0;
					ssize_t read=0;
					if ((read = getdelim(outstr, &len, '\0', fp)) == -1) {
						rCode=-1;
						HA_LG_ER("HA_DEVMON_Utils:%s() getdelim failed, %d", __func__, errno);
					}
					fclose(fp);
				}
				close(fds[0]);
				waitpid(pid, &status, 0);
				if (status != 0) {
					rCode=-1;
					HA_LG_ER("HA_DEVMON_Utils:%s() _execvp failed, rCode:[%d], error : %d", __func__, status, errno);
				}
			}
		}
	}
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_DEVMON_Utils::_popen(char *const argv[], char outstr[])
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	int fds[2];
    int status;

	if (pipe(fds) < 0) {
		HA_LG_ER("HA_DEVMON_Utils:%s() pipe failed. %d", __func__, errno);
		rCode=-1;
	}
	pid_t pid = fork();

	if (rCode == 0) {
		if (pid < 0) {
			HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
			rCode=-1;
		} else if (pid == 0) {
			ACE_OS::alarm(m_globalInstance->Config()->getConfig().callbackTmout/APOS_HA_ONESEC_IN_MILLI - 1);
			dup2(fds[1], STDOUT_FILENO);
			close(fds[0]);
			if( execvp(argv[0], argv) == -1) {
				HA_LG_ER("HA_DEVMON_Utils:%s() Fatal error execvp failed. %d", __func__, errno);
				rCode=-1;
			}
			close(fds[1]);
		}  else {
			close(fds[1]);
			FILE *fp = fdopen(fds[0], "r");
			if( fscanf(fp, "%256s", outstr) == EOF)
			{
				rCode=-1;
				HA_LG_ER("HA_DEVMON_Utils:%s() fscanf failed", __func__);
			}
			fclose(fp);
			close(fds[0]);
			waitpid(pid, &status, 0);
			if (status != 0) {
				rCode=-1;
				HA_LG_ER("HA_DEVMON_Utils:%s()_popen failed, rCode:[%d]", __func__, status);
			}
		}
	}
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
void HA_DEVMON_Utils::forceExit()
{
    HA_TRACE_ENTER();
    /*
      _execlp() or _popen has taken more time to execute than set. It
      might be possible that the process spawned is hung. we can do
      gracefull activities here before CMW takes recovery action on
      us.
    */
    if (m_globalInstance->haMode()) {
        m_globalInstance->nodefailOver();
        /*  if this fails, fall back on --noha exit, thats the best
            we could do now.
        */
    }

    HA_LG_ER("HA_DEVMON_Utils:%s() Exiting...", __func__);
    exit(EXIT_FAILURE);

    HA_TRACE_LEAVE();
}
//-------------------------------------------------------------------------


bool HA_DEVMON_Utils::runCommand(const string command, string& output)
{
	FILE *fp;
	char readLine[10000];
	output = "";

	/* Open the command for reading. */
	fp = popen(command.c_str(), "r");
	if (fp == 0) {
		return false;
	}

	/* Read the output a line at a time and store it. */
	while (fgets(readLine, sizeof(readLine) - 1, fp) != 0) {

		size_t newbuflen = strlen(readLine);

		if ( (readLine[newbuflen - 1] == '\r') || (readLine[newbuflen - 1] == '\n') ) {
			readLine[newbuflen - 1] = '\0';
		}

		if ( (readLine[newbuflen - 2] == '\r') || (readLine[newbuflen - 2] == '\n') ) {
			readLine[newbuflen - 2] = '\0';
		}

		output += readLine;
	}

	/* close */
	pclose(fp);
	return true;
}   

bool HA_DEVMON_Utils::getDiskState(string resource, string& state, bool isLocal)
{
	bool result = false;
	state = "";
	if (resource.length() > 0) {
		ostringstream outStream;
		if (isLocal) {
			
			outStream << "drbdadm status " << resource.c_str() << " |grep -w \" disk\" |awk -F : '{print $2}' | awk '{print $1}'";			
			
		} else {
		    outStream << "drbdadm status " << resource.c_str() << " |grep -w \" peer-disk\" |awk -F 'peer-disk:' '{print $2}' | awk '{print $1}'";		
		}
		
		string command(outStream.str());
		if (runCommand(command, state)) {
			result = true;
		}
		
	}
	return result;
}
   

bool HA_DEVMON_Utils::getDrbdRole(string resource, string& role, bool isLocal)
{
	bool result = false;	
	role = "";
	if (resource.length() > 0) {
		ostringstream outStream;
		if (isLocal) {
			outStream << "drbdadm status " << resource.c_str() << " |grep \""<< resource.c_str() << " role\" |awk -F : '{print $2}'";				
		} else {
			string peer_name;
			string cat_cmd = "cat /etc/cluster/nodes/peer/hostname";
			if (runCommand(cat_cmd, peer_name)) {
				outStream << "drbdadm status " << resource.c_str() << " |grep -w \""<< peer_name.c_str() << " role\" |awk -F : '{print $2}' |awk '{print $1}'";
			} else {
				return false;
			}
		}
		
		string command (outStream.str());
		if (runCommand(command, role)) {
			result = true;
		}
	}
	return result;
}


bool HA_DEVMON_Utils::getConnectedState(string resource, string& state)
{

	bool result = false;
	state = "";
	string temp;
	if (resource.length() > 0) {
		ostringstream outStream1;
		outStream1 << "drbdsetup status " << resource.c_str() << " --verbose | grep \"replication\" | awk -F \"replication:\" '{print $2}' | awk '{print $1}'";
		string command1(outStream1.str());
		if (runCommand(command1, temp)) {
			if ((temp.compare("Established")==0) || (temp.compare("Off")==0)) {
				ostringstream outStream2;
				outStream2 << "drbdsetup status " << resource.c_str() << " --verbose | grep \"connection\" | awk -F \"connection:\" '{print $2}' | awk '{print $1}'";
				string command2(outStream2.str());
				if (runCommand(command2, temp)) {
					state = temp;
				}

			} else {
				state = temp;
			}
		}
		if (!state.empty())
			result = true;
	}

	return result;
}
