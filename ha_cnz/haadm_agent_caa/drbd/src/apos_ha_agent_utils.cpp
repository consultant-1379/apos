/*****************************************************************************
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
 * @file apos_ha_agent_utils.cpp
 *
 * @brief
 * 
 * This class is used as a generic utility class. It checks the physical
 * components of the node viz., name, architecture etc.
 *
 * @author Malangsha Shaik (xmalsha)
 *
 -------------------------------------------------------------------------*/

#include "apos_ha_agent_utils.h"
#include <sstream>

//-------------------------------------------------------------------------
HA_AGENT_Utils::HA_AGENT_Utils():
 ap_1(false),
 ap_2(false),
 Gep1flag(false),
 Gep2flag(false),
 Gep4flag(false),
 Gep5flag(false),
 m_globalInstance(HA_AGENT_Global::instance())
{
	HA_TRACE_ENTER();
    
    HA_TRACE_LEAVE();     	
}

//-------------------------------------------------------------------------
HA_AGENT_Utils::~HA_AGENT_Utils()
{
    HA_TRACE_ENTER();
    
    HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_Utils::init()
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
int HA_AGENT_Utils::Ap()
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
int HA_AGENT_Utils::Gep()
{
    ACE_INT32 rCode=0;
	HA_TRACE_ENTER();
    // Do we really need to know the Gep version??

	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
void HA_AGENT_Utils::msec_sleep(ACE_UINT32 msecs)
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
int HA_AGENT_Utils::_execlp(const char *cmdStr)
{
    HA_TRACE_ENTER();
    ACE_INT32 rCode=0;

    int status;
    pid_t pid = fork();
    if (pid == 0) {
        ACE_OS::alarm(m_globalInstance->Config()->getConfig().callbackTmout/APOS_HA_ONESEC_IN_MILLI - 1);
        if(execlp("sh","sh", "-c", cmdStr, (char *) NULL) == -1) {
            HA_LG_ER("HA_AGENT_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
            rCode=-1;
        }
		exit(0);
    } else { if (pid < 0) {
                HA_LG_ER("HA_AGENT_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
                rCode=-1;
            }
    }

    if (rCode != -1) {
        waitpid(pid, &status, 0);

        if (status != 0) {
            rCode=-1;
            HA_LG_ER("HA_AGENT_Utils:%s() cmdStr [%s] Failed, rCode:[%d]", __func__, cmdStr, status);
        }
    }
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Utils::_execvp(char *const argv[], char **outstr)
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	int fds[2];
    int status=0;

	if (pipe(fds) < 0) {
		HA_LG_ER("HA_AGENT_Utils:%s() pipe failed. %d", __func__, errno);
		rCode=-1;
	}
	if (rCode == 0) {
		pid_t pid = fork();

		if (rCode == 0) {
			if (pid < 0) {
				HA_LG_ER("HA_AGENT_Utils:%s() Fatal error fork() failed. %d", __func__, errno);
				rCode=-1;
			} else if (pid == 0) {
				ACE_OS::alarm(m_globalInstance->Config()->getConfig().callbackTmout/APOS_HA_ONESEC_IN_MILLI - 1);
				dup2(fds[1], STDOUT_FILENO);
				close(fds[0]);
				if( execvp(argv[0], argv) == -1) {
					HA_LG_ER("HA_AGENT_Utils:%s() Fatal error execvp failed. %d", __func__, errno);
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
						HA_LG_ER("HA_AGENT_Utils:%s() getdelim failed", __func__);
					}
					fclose(fp);
					
				} else {
					rCode=-1;
				}
				close(fds[0]);
				waitpid(pid, &status, 0);
				if (status != 0) {
					rCode=-1;
					HA_LG_ER("HA_AGENT_Utils:%s() _execvp failed, rCode:[%d]", __func__, status);
				}
			}
		}
	}
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
void HA_AGENT_Utils::forceExit()
{
    HA_TRACE_ENTER();
    /*
      _execlp() or _execvp() has taken more time to execute than set. It
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

    HA_LG_ER("HA_AGENT_Utils:%s() Exiting...", __func__);
    exit(EXIT_FAILURE);

    HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
int HA_AGENT_Utils::createRCF()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	FILE *fd;
	if (!this->FileExist()) {
		fd = fopen(APOS_HA_FILE_RC , "w+");
		if (fd == NULL) {
			HA_LG_ER("HA_AGENT_Utils:%s() - RebootCount File creation failed", __func__);
			rCode=-1;
		}	

		if (rCode != -1) {
			ACE_INT32 rCount=m_globalInstance->Config()->getConfig().rebootCount;
			 if (!fprintf(fd,"%d\n", rCount)) {
				HA_LG_ER("HA_AGENT_Utils:%s() - fprintf() failed", __func__);
			}
			fclose(fd);
		}	
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Utils::removeRCF()
{
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	if (FileExist()) { 
		if (unlink(APOS_HA_FILE_RC) < 0) {
			HA_LG_ER("HA_AGENT_Utils:%s() - Failed to unlink(remove) Reboot Count File", __func__);
			rCode=-1;
		}
	}	
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
bool HA_AGENT_Utils::FileExist()
{
    HA_TRACE_ENTER();
    bool rCode=false;

    if (access(APOS_HA_FILE_RC, F_OK) == 0) {
        HA_TRACE_1("HA_AGENT_Utils:%s() - RCF exist", __func__);
        rCode=true;
    }
    HA_TRACE_LEAVE();
    return rCode;
}

//-------------------------------------------------------------------------
int HA_AGENT_Utils::APEvent()
{
	/* The following part of the code will have greater dependency
	  on AEH event handling and in the way aehevls command. If
	  there is change in aeh in the message format, it will have
	  impact in this code as well. */
	HA_TRACE_ENTER();
	ACE_INT32 rCode=0;
	ACE_INT32 fd;
	std::string message="";
	ssize_t written;
	fd = open(APOS_HA_AGENT_AEH_FIFO, O_RDWR);
	if (fd < 0){
		HA_LG_ER("HA_AGENT_Utils:%s() - Failed to open AEH FIFO[%s]", __func__, APOS_HA_AGENT_AEH_FIFO);
		rCode=-1;
	}
	if (rCode != -1){
		fillEvent(message);
		written = write(fd, message.c_str(), strlen(message.c_str()));
		if (written == -1){	
			HA_LG_ER("HA_AGENT_Utils:%s() - write_n error", __func__);
			rCode=-1;
		}					
		HA_TRACE("Msg:[%s]---Written:[%zu]",message.c_str(),written);
		if (written != (unsigned)strlen(message.c_str())){
			HA_LG_ER("HA_AGENT_Utils:%s() - write_n not complete", __func__);
			HA_LG_ER("HA_AGENT_Utils-MSG_LEN :[ %zu] Written_L:[%zu]",strlen(message.c_str()),written);
			rCode=-1;
		}
		fd = close(fd);
		if (fd < 0){
			HA_LG_ER("HA_AGENT_Utils:%s() - Failure in closing AEH FIFO[%s]", __func__, APOS_HA_AGENT_AEH_FIFO);
			rCode=-1;
		}
	}
	HA_TRACE_LEAVE();
	return rCode;
}

//-------------------------------------------------------------------------
void HA_AGENT_Utils::fillEvent(std::string &msg)
{
	HA_TRACE_ENTER();
	ACE_TCHAR SOURCE[26];
	if (Ap_1()) {
    		msg.append("SC-2-1 ");
  	} else {
    		msg.append("SC-2-2 ");
  	}
	msg.append("PASSIVE ");
	msg.append("error ");
	msg.append("root ");
	sprintf(SOURCE, "apos_ha_rdeagentd:%d ", getpid());
	msg.append(SOURCE);
	msg.append("10007 ");
	msg.append("EVENT ");
	msg.append("0 ");
	msg.append("P_CAUSE: DATA DISK INCONSISTENT ");
	msg.append("CLASS_REF: APZ ");
	msg.append("OBJ_REF: apos_ha_rdeagentd ");
	msg.append("P_DATA: Non recoverable fault on Active node during data disk synchronization. No Active node found in the cluster and peer node cannot be granted as Active because of data disk on this node not consistent");
	HA_TRACE_1("APEvent:[%s]", msg.c_str());
	HA_TRACE_LEAVE();
}

//-------------------------------------------------------------------------
bool HA_AGENT_Utils::isIPv4(const string &ipaddress)
{
  struct sockaddr_in sa;
  return inet_pton(AF_INET, ipaddress.c_str(), &(sa.sin_addr)) != 0;
}

//-------------------------------------------------------------------------
bool HA_AGENT_Utils::isIPv6(const string &ipaddress)
{
  struct sockaddr_in6 sa;
  return inet_pton(AF_INET6, ipaddress.c_str(), &(sa.sin6_addr)) != 0;
}

//-------------------------------------------------------------------------

bool HA_AGENT_Utils::runCommand(const string command, string& output)
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

bool HA_AGENT_Utils::getDiskState(string resource, string& state, bool isLocal)
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
   

bool HA_AGENT_Utils::getDrbdRole(string resource, string& role, bool isLocal)
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


bool HA_AGENT_Utils::getConnectedState(string resource, string& state)
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

