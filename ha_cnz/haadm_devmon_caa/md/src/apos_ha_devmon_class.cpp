
#include "apos_ha_devmon_class.h"

DevMonClass::DevMonClass(const char* daemon_name):
APOS_HA_DevMon_AmfClass(daemon_name ),
gep_id(0),
HaAgentPid(0),
node_id(0),
m_myClassObj(0),	
passiveToActive(0),
Is_Debug(false),
Is_Active(false)
{
	InitializeDevmon();
	Is_Debug = false;
}

DevMonClass::DevMonClass():
gep_id(0),
HaAgentPid(0),
node_id(0),
passiveToActive(0),
Is_Active(false)
{
        InitializeDevmon();
	Is_Debug = false;
	m_myClassObj = 0;	
}


void DevMonClass::InitializeDevmon()
{
        /* create the pipe for shutdown handler */
        Node.PortOne.disk.diskname[0]='\0';
        Node.PortOne.disk.Is_healthy=FALSE;
        Node.PortOne.Is_healthy=FALSE;
        Node.PortTwo.disk.diskname[0]='\0';
        Node.PortTwo.disk.Is_healthy=FALSE;
        Node.PortTwo.Is_healthy=FALSE;
	populateStruct=FALSE;
        Is_RAIDInfoPopulated=FALSE;
}

ACS_APGCC_ReturnType DevMonClass::performStateTransitionToActiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState){

        (void) previousHAState;
							 
	return this->activateApp();

}

ACS_APGCC_ReturnType DevMonClass::performStateTransitionToPassiveJobs(ACS_APGCC_AMF_HA_StateT previousHAState) {

	(void) previousHAState;
	return this->passifyApp();
			
}

ACS_APGCC_ReturnType DevMonClass::performStateTransitionToQueisingJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{

        (void) previousHAState;
        return this->shutdownApp();
}

ACS_APGCC_ReturnType DevMonClass::performStateTransitionToQuiescedJobs(ACS_APGCC_AMF_HA_StateT previousHAState)
{
        (void) previousHAState;
	return this->shutdownApp();
}

ACS_APGCC_ReturnType DevMonClass::performComponentHealthCheck(void)
{

	/* Application has received health check callback from AMF. Check the
	 * sanity of the application and reply to AMF that you are ok.
	 */

	/* Disable the logging for now.
	 * syslog(LOG_INFO, "Received healthcheck query!!!");
 	 */
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::performComponentTerminateJobs(void)
{
	syslog(LOG_INFO, "Received terminate callback!!!");
	return this->shutdownApp();
}

ACS_APGCC_ReturnType DevMonClass::performComponentRemoveJobs(void)
{
	syslog(LOG_INFO, "Application Assignment is removed now");
	return this->shutdownApp();
}

ACS_APGCC_ReturnType DevMonClass::performApplicationShutdownJobs() {
	 syslog(LOG_INFO, "Application is shutting down now");	
	 return this->shutdownApp();
}


ACS_APGCC_ReturnType DevMonClass::shutdownApp(){

	Is_Active=FALSE;
	if ( 0 != this->m_myClassObj){
	        this->m_myClassObj->stop(); // This will initiate the application shutdown and will not return until application is stopped completely.
 	        this->m_myClassObj->wait();
                delete this->m_myClassObj;
                this->m_myClassObj=0;
	}
        return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::activateApp() {

	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	Is_Active=TRUE;
	if ( 0 != this->m_myClassObj) {
		if (passiveToActive){
		        this->m_myClassObj->stop();
        	        this->m_myClassObj->wait();
                	passiveToActive=0;
        	}
	        else {
        	        rCode = ACS_APGCC_SUCCESS;
        	}
	} else {
	                ACE_NEW_NORETURN(this->m_myClassObj, devmonClass());
	                if (0 == this->m_myClassObj) {
		                syslog(LOG_ERR, "devmonClass: failed to create the instance");
		        }
	}	

	if ( 0 != this->m_myClassObj) {
		int res = this->m_myClassObj->active(this); // This will start active functionality. Will not return until myCLass is running
                if (res < 0) {
                // Failed to start
	                delete this->m_myClassObj;
	                this->m_myClassObj = 0;
	        } else {
	                rCode = ACS_APGCC_SUCCESS;
	        }
	}
	return rCode;
}
													//                                                                                                                                                 
ACS_APGCC_ReturnType DevMonClass::passifyApp() {

	ACS_APGCC_ReturnType rCode = ACS_APGCC_FAILURE;
	passiveToActive=1;
	Is_Active=FALSE;
	if (0 != this->m_myClassObj) {
               rCode = ACS_APGCC_SUCCESS;
        } else {
               ACE_NEW_NORETURN(this->m_myClassObj, devmonClass());
	       if (0 == this->m_myClassObj) {
			syslog(LOG_ERR, "devmonClass: failed to create the instance");
		}
		else {
			int res = this->m_myClassObj->passive(this); // This will start passive functionality and will not return until myCLass is running
		       	if (res < 0) {
		       		// Failed to start
		               delete this->m_myClassObj;
		               this->m_myClassObj = 0;
		       } else {

                               rCode = ACS_APGCC_SUCCESS;
                       }
		}
	}
	return rCode;
}
																													//                                                                                                                                                                                                                 
ACS_APGCC_ReturnType DevMonClass::Is_Node_Active() {        
	FILE *p_fd;
        ACE_TCHAR command_string[CMD_LEN];
        ACE_TCHAR line[80];
        ACE_OS::memset(command_string ,0 ,CMD_LEN);
        ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --node-state");
	line[0]='\0';
        p_fd = popen (command_string,"r");

        if ( p_fd == NULL ){
                syslog(LOG_ERR, "Devmon: popen error to lanuch [%s]" ,command_string);
                return ACS_APGCC_FAILURE ;
        }

        while (!feof(p_fd)) {
                ACE_INT32 attemp_count=0;

                while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
                //if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
                        if (attemp_count++ > 10 ) break; // from inner while
                                continue;
                } // inner while

                if (line[0] == '\0'){
                        syslog(LOG_ERR, "DevMon : Counter NULL data found");
                        break; // from outer while
                }
        }

        if (ACE_OS::strstr(line ,"ACTIVE") != NULL){
                syslog(LOG_INFO, "apos_ha_devmond : Running on active node...");
		Is_Active = true;
        }
        else if(ACE_OS::strstr(line ,"STANDBY") != NULL){
                syslog(LOG_INFO, "apos_ha_devmond : Running on standby node...");
		Is_Active = false;
        }
        else
        {
                syslog(LOG_INFO, "apos_ha_devmond: Internal error occured while executing command...");
		fclose(p_fd);
                return ACS_APGCC_FAILURE;
        }
	fclose(p_fd);
        return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType DevMonClass::Initialize() {


	syslog(LOG_INFO, "Starting Application Thread");
	/* set node id */
	if (setNodeId() != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	/* set which gep are you on */
	if ( setGepId () != ACS_APGCC_SUCCESS ){
		return ACS_APGCC_FAILURE;
	}

	/* update the data disk status */	
	if (updateDatadiskStatus() != ACS_APGCC_SUCCESS){
		syslog(LOG_INFO, "Updating the datadisk FAILED");
		return ACS_APGCC_FAILURE;
	}

	/* populate disk and controller info structure */
	if (ACS_APGCC_SUCCESS != populateDiskInfo()){
		syslog(LOG_ERR, "Error populating disk information");
		return ACS_APGCC_FAILURE;
	}

	syslog(LOG_INFO,"populateDiskInfo populated");
	/* get Agent PID */
	if(Is_Debug)
	{
		if (getAgentDebugPid() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "Error! Fetching RDE on pid");
			return ACS_APGCC_FAILURE;
		}
	}
	else
	{
		if (getHaAgentPid() != ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "Error! Fetching RDE on pid");
			return ACS_APGCC_FAILURE;
		}
	}

	if(Is_Active){
		if (populateRAIDInfo()!= ACS_APGCC_SUCCESS){
			syslog(LOG_ERR, "populateRAIDInfo FAILED!");
		}
	}

	return ACS_APGCC_SUCCESS;
}

void DevMonClass::svc_run(){
	/* setting status monitor frequency */

	populateStruct=FALSE;
	while(true){
		if (ACS_APGCC_SUCCESS != monitorControllersAndDatadisks(populateStruct)){
			syslog(LOG_ERR, "Failed to monitor Controllers and Data disks");
		}
		if(Is_Active){
			if (monitorRAID(populateStruct) != ACS_APGCC_SUCCESS){
				syslog(LOG_ERR, "RAID Monitor FAILED!");
			}
		}	

		// wait for 4 secs before monitor again
		msec_sleep(2000); // hardcode 4 secs
	}
	syslog(LOG_INFO, "Application Thread Terminated successfully");
}


void DevMonClass::msec_sleep(ACE_INT32 time_in_msec) {

        struct timeval tv;

        tv.tv_sec = time_in_msec / 1000;
        tv.tv_usec = ((time_in_msec) % 1000) * 1000;

        while (select(0, 0, 0, 0, &tv) != 0)
               if (errno == EINTR)
                   continue;
}


ACS_APGCC_ReturnType DevMonClass::monitorRAID(ACS_APGCC_BOOL populateStruct) {
	FILE *p_fd;
	ACE_TCHAR line[80];
	ACE_TCHAR buff1[50],buff2[50],buff3[50],buff4[50];
	ACE_TCHAR command_string[CMD_LEN];
	ACE_TCHAR diskOne[50]={'\0'};
	ACE_TCHAR diskTwo[50]={'\0'};
	command_string[0]='\0';
	ACS_APGCC_BOOL diskOneRaid_healthy = FALSE;
	ACS_APGCC_BOOL diskTwoRaid_healthy = FALSE;
	line[0]='\0';
	
	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --list-raid-disks");

	p_fd = popen (command_string,"r");
	if ( p_fd == NULL ){
		syslog(LOG_ERR, "popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		buff1[0]='\0';
		buff2[0]='\0';
		buff3[0]='\0';
		buff4[0]='\0';

		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			if (ferror(p_fd)) syslog(LOG_ERR, "ERROR on reading pipe. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "Error! NULL data found");
			break; // from outer while
		}

		if (ACE_OS::strstr(line ,"DISK1:") != NULL){
			sscanf(line ,"%s %s %s %s", buff1 ,buff2, buff3,buff4);
			memcpy(diskOne, buff2,strlen(buff2)+1);
			if ( (ACE_OS::strcmp(buff4,"active") == 0) || (ACE_OS::strcmp(buff4,"spare") == 0) )
			{
				diskOneRaid_healthy = TRUE;
			}
			else
			{
				diskOneRaid_healthy = FALSE;
			}
			continue;
		}
		if (ACE_OS::strstr(line ,"DISK2:") != NULL){
			sscanf(line ,"%s %s %s %s", buff1 ,buff2, buff3,buff4);
			memcpy(diskTwo, buff2,strlen(buff2)+1);
			if ( (ACE_OS::strcmp(buff4,"active") == 0) || (ACE_OS::strcmp(buff4,"spare") == 0) )
			{
				diskTwoRaid_healthy = TRUE;
			}
                        else
                        {
				diskTwoRaid_healthy = FALSE;
                        }
		}

	}//end outer while

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"Error in popen close. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}		

	if (populateStruct){
		if (Node.PortOne.disk.Is_healthy){
			if (ACE_OS::strcmp(diskOne, Node.PortOne.disk.diskname) == 0){
				Node.PortOne.Is_raidHealthy = diskOneRaid_healthy;
			}
		}	

		if (Node.PortTwo.disk.Is_healthy){
			if (ACE_OS::strcmp(diskTwo, Node.PortTwo.disk.diskname) == 0){
				Node.PortTwo.Is_raidHealthy = diskTwoRaid_healthy;	
			}
		}	

		return ACS_APGCC_SUCCESS;
	} else {
		/* Check the RAID status with the previous populated structure
		 * If there is change in state,
		 * 1.update self structure
		 * 2.send a signal to RDE Agent to update the same
		 */

		if (Node.PortOne.Is_raidHealthy  != diskOneRaid_healthy ||
		     Node.PortTwo.Is_raidHealthy != diskTwoRaid_healthy){


			if( (!(diskOneRaid_healthy) && (Node.PortOne.disk.Is_healthy)) || 
			    (!(diskTwoRaid_healthy) && (Node.PortTwo.disk.Is_healthy)) ) {
				
				syslog(LOG_INFO ,"Disk missing in RAID array!");
//				syslog(LOG_INFO, "Invoking [raidmgmt -r] for rebuilding RAID array....");
				ACE_OS::memset(command_string ,0 ,CMD_LEN);
				ACE_OS::snprintf(command_string ,CMD_LEN ,RAID_MGMT_CMD " -r");

				int retCode = ACE_OS::system(command_string);
				if (retCode == -1 ){
					syslog(LOG_ERR, "\"system\" call failed while executing the command %s",command_string);
				}

				retCode = WEXITSTATUS(retCode);
				if (retCode != 0) {
				//	syslog(LOG_ERR,"[ %s ]command failed with error code: %d",command_string,retCode);
					return ACS_APGCC_FAILURE;
				}


				syslog(LOG_INFO, "monitorRAID Status Change, Signaling Agent to update");
				if (kill (this->HaAgentPid, SIG_UPDATE_RAID) < 0 ){
					syslog(LOG_ERR, "Failed to send SIG_STATUS_CHECK Signal to RDE on. errno:[%d]",errno);
				}	
				msec_sleep(1000);
			
			}
			/* update self structure */
			Node.PortOne.Is_raidHealthy = diskOneRaid_healthy;
			Node.PortTwo.Is_raidHealthy = diskTwoRaid_healthy;
		}

	}			
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::setGepId(){

	ACE_TCHAR line[25],buff[20];
	FILE *p_fd;
	line[0]='\0';
	p_fd = popen (GEP_HWTYPE,"r");
	if (p_fd == NULL){
		syslog(LOG_ERR, "RDE_on: popen error to lanuch [%s]" ,GEP_HWTYPE);
		return ACS_APGCC_FAILURE;
	}

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			if (ferror(p_fd)) syslog(LOG_ERR, "ERROR on reading pipe. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "Error! NULL data found");
			break; // from outer while
		}
		sscanf(line,"%s",buff);
	}

	if (ACE_OS::strcmp(buff ,GEP1STRING) == 0){
		this->gep_id=GEP_ONE;
	}

	if (ACE_OS::strcmp(buff ,GEP2STRING) == 0){
		this->gep_id=GEP_TWO;
	}

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"Error in popen close. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}		

	syslog(LOG_INFO ,"Running on : GEP%d",this->gep_id);
	return ACS_APGCC_SUCCESS;
}

ACE_INT32 DevMonClass::launch_popen(const char *command_string, ACS_APGCC_BOOL &port_status){

	ACE_TCHAR line[80],buff1[20],buff2[20];
	FILE *p_fd;
	line[0]='\0';
	buff1[0]='\0';
	buff2[0]='\0';
	
	port_status = FALSE;
	p_fd = popen (command_string,"r");
	if (p_fd == NULL){
		syslog(LOG_ERR, "popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}
        

	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			if (ferror(p_fd)) syslog(LOG_ERR, "ERROR on reading pipe. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "Error! NULL data found");
			break; // from outer while
		}
		sscanf(line,"%s %s",buff1,buff2);
	}

	if (ACE_OS::strcmp(buff2 ,"healthy") == 0)
		port_status = TRUE;
	else if (ACE_OS::strcmp(buff2 ,"unhealthy") == 0)
		port_status = FALSE;

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"Error in popen close. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}

	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::checkSCSIControllerStatus(ACS_APGCC_BOOL populateStruct,ACS_APGCC_BOOL &statusChange ) {
					

        ACE_TCHAR command_string[CMD_LEN];
        ACS_APGCC_BOOL port_status = FALSE;
	command_string[0]='\0';
        ACE_OS::memset(command_string ,0 ,CMD_LEN);


        if (this->gep_id == GEP_ONE){
                ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-one-port-status 1");
                if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE) {
			if (populateStruct){
                        	Node.PortOne.Is_healthy = port_status;
			} 
			if (Node.PortOne.Is_healthy != port_status){
					syslog(LOG_INFO,"Node.PortOne.Is_healthy [%d] port_status[%d]",Node.PortOne.Is_healthy,port_status);
					syslog(LOG_INFO, "PortOne status changed");
					Node.PortOne.Is_healthy = port_status;
					statusChange=TRUE;
			}
		}
		else {
			syslog(LOG_ERR, "launch_popen Failed");
			return ACS_APGCC_FAILURE;	
		}

		port_status = FALSE;
                ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-one-port-status 2"); 
                if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE){
			if (populateStruct){
                        	Node.PortTwo.Is_healthy = port_status;
			} 	
			if (Node.PortTwo.Is_healthy != port_status){
					syslog(LOG_INFO,"Node.PortTwo.Is_healthy [%d] port_status[%d]",Node.PortTwo.Is_healthy,port_status);
					syslog(LOG_INFO, "PortTwo status changed");
					Node.PortTwo.Is_healthy = port_status;
					statusChange=TRUE;
			}
		}
		else {
			syslog(LOG_ERR, "launch_popen Failed");
			return ACS_APGCC_FAILURE;	
		}
        }

        if (this->gep_id == GEP_TWO){
                ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-two-port-status 1");
                if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE){
			if (populateStruct){
                        	Node.PortOne.Is_healthy = port_status;
			} else if (Node.PortOne.Is_healthy != port_status){
					syslog(LOG_INFO,"Node.PortOne.Is_healthy [%d] port_status[%d]",Node.PortOne.Is_healthy,port_status);
					syslog(LOG_INFO, "PortOne status changed");
					Node.PortOne.Is_healthy=port_status;
					statusChange=TRUE;
			}
		}
		else {
			syslog(LOG_ERR, "launch_popen Failed");
			return ACS_APGCC_FAILURE;	
		}
		
		port_status=FALSE;		
                ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --gep-two-port-status 2");
                if ( launch_popen(command_string, port_status) != ACS_APGCC_FAILURE){
			if (populateStruct){
                        	Node.PortTwo.Is_healthy = port_status;
			} else if (Node.PortTwo.Is_healthy != port_status){
					syslog(LOG_INFO,"Node.PortTwo.Is_healthy [%d] port_status[%d]",Node.PortTwo.Is_healthy,port_status);
					syslog(LOG_ERR, "PortTwo status changed");
					Node.PortTwo.Is_healthy = port_status;
					statusChange=TRUE;
			}
		}
		else {
			syslog(LOG_ERR, "launch_popen Failed");
			return ACS_APGCC_FAILURE;	
		}
        }

        return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::checkAvailableDataDisks( ACS_APGCC_BOOL populateStruct, ACS_APGCC_BOOL &statusChange) {

	FILE *p_fd;
	ACE_TCHAR line[80];
	ACE_TCHAR buff1[10],buff2[10];
	ACE_TCHAR command_string[CMD_LEN];
	line[0]='\0';
	buff1[0]='\0';
	buff2[0]='\0';
	command_string[0]='\0';	
	
	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --list-port-disk");

	p_fd = popen (command_string,"r");
	if ( p_fd == NULL ){
		syslog(LOG_ERR, "popen error to lanuch [%s]" ,command_string);
		return ACS_APGCC_FAILURE ;
	}


	while (!feof(p_fd)) {
		ACE_INT32 attemp_count=0;
		while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
			if (ferror(p_fd)) syslog(LOG_ERR, "ERROR on reading pipe. Error [%s]", strerror(errno));
			if (attemp_count++ > 10 ) break; // from inner while
			continue;
		} // inner while
		if (line[0] == '\0'){
			syslog(LOG_ERR, "Error! NULL data found");
			break; // from outer while
		}

		buff1[0]='\0';
		buff2[0]='\0';
		if (ACE_OS::strstr(line ,"PORT1:") != NULL){
			sscanf(line ,"%s %s", buff1 ,buff2);
			if(populateStruct){
				if (ACE_OS::strcmp(buff2 ,"null") != 0){
					memcpy(Node.PortOne.disk.diskname, buff2,strlen(buff2)+1);
					Node.PortOne.disk.Is_healthy = TRUE;
				}
			}else if(ACE_OS::strcmp(Node.PortOne.disk.diskname,buff2) != 0)
				{
					if(ACE_OS::strcmp(buff2 ,"null") == 0)
					{
						Node.PortOne.disk.Is_healthy = FALSE;
						memcpy(Node.PortOne.disk.diskname, buff2,strlen(buff2)+1);
						statusChange=TRUE;
						syslog(LOG_INFO, "Disk status changed");
						pclose(p_fd);	
						return ACS_APGCC_SUCCESS;
					}
					else
					{
						memcpy(Node.PortOne.disk.diskname, buff2,strlen(buff2)+1);
						Node.PortOne.disk.Is_healthy = TRUE;
						statusChange=TRUE;
						syslog(LOG_INFO, "Disk status changed");
						pclose(p_fd);
						return ACS_APGCC_SUCCESS;
					}
				}
			
		}
		if (ACE_OS::strstr(line ,"PORT2:") != NULL){
			sscanf(line ,"%s %s", buff1 ,buff2);

			if(populateStruct){
				if (ACE_OS::strcmp(buff2 ,"null") != 0){
					memcpy(Node.PortTwo.disk.diskname, buff2,strlen(buff2)+1);
					Node.PortTwo.disk.Is_healthy = TRUE;
				}
			}else if (ACE_OS::strcmp(Node.PortTwo.disk.diskname,buff2) != 0)
				{
					if(ACE_OS::strcmp(buff2 ,"null") == 0)
					{
						Node.PortTwo.disk.Is_healthy = FALSE;
						memcpy(Node.PortTwo.disk.diskname, buff2,strlen(buff2)+1);
						statusChange=TRUE;
						syslog(LOG_INFO, "Disk status changed");
						pclose(p_fd);
						return ACS_APGCC_SUCCESS;
					}
					else
					{
						memcpy(Node.PortTwo.disk.diskname, buff2,strlen(buff2)+1);
						Node.PortTwo.disk.Is_healthy = TRUE;
						statusChange=TRUE;
						syslog(LOG_INFO, "Disk status changed");
						pclose(p_fd);
						return ACS_APGCC_SUCCESS;
					}
			}
		}	
	}		
	 /* end of while */

	int status = pclose(p_fd);
	if (WIFEXITED(status)){
		if ((status=WEXITSTATUS(status)) != 0) {
			syslog(LOG_ERR ,"Error in popen exit. Error Code [%d]", status);
			return ACS_APGCC_FAILURE;
		}
	}
	return ACS_APGCC_SUCCESS ;
}


ACS_APGCC_ReturnType DevMonClass::monitorControllersAndDatadisks(ACS_APGCC_BOOL populateStruct){

	ACS_APGCC_BOOL statusChange=FALSE;
	ACE_TCHAR command_string[CMD_LEN];
	command_string[0]='\0';

	if (checkSCSIControllerStatus(populateStruct, statusChange) != ACS_APGCC_SUCCESS){
		return ACS_APGCC_FAILURE;
	}

	if ( statusChange == TRUE){
		/* update data disk status first */
		if (updateDatadiskStatus() != ACS_APGCC_SUCCESS){
			syslog(LOG_INFO, "Updating the datadisk FAILED");
			return ACS_APGCC_FAILURE;
		}
		syslog(LOG_INFO, "checkSCSIControllerStatus Status change, Signling on to update");
		if (kill (this->HaAgentPid, SIG_UPDATE_DISK) < 0 ){
			syslog(LOG_ERR, "Failed to send SIG_UPDATE_DISK Signal to RDE on. errno:[%d]",errno);
		}	
	}

	statusChange=FALSE;

	
	if (checkAvailableDataDisks(populateStruct, statusChange) != ACS_APGCC_SUCCESS){
		return ACS_APGCC_FAILURE;
	}

	if ( statusChange == TRUE){
		if (updateDatadiskStatus() != ACS_APGCC_SUCCESS){
			syslog(LOG_INFO, "Updating the datadisk FAILED");
			return ACS_APGCC_FAILURE;
		}

		if( (!(Node.PortOne.Is_raidHealthy) && (Node.PortOne.disk.Is_healthy)) ||
			(!(Node.PortTwo.Is_raidHealthy) && (Node.PortTwo.disk.Is_healthy)) ) {

			if(Is_Active)
			{
				syslog(LOG_INFO ,"Disk missing in RAID array!");
//				syslog(LOG_INFO, "Invoking [raidmgmt -r] for adding missing disks and rebuilding array....");
				ACE_OS::memset(command_string ,0 ,CMD_LEN);
				ACE_OS::snprintf(command_string ,CMD_LEN ,RAID_MGMT_CMD " -r");
	
				int retCode = ACE_OS::system(command_string);
				if (retCode == -1 ){
					syslog(LOG_ERR, "\"system\" call failed while executing the command %s",command_string);
				}

				retCode = WEXITSTATUS(retCode);
				if (retCode != 0) {
//					syslog(LOG_ERR,"[ %s ]command failed with error code: %d",command_string,retCode);
				}
			}
		}


		syslog(LOG_INFO, "checkAvailableDataDisks Status change, Signling Agent to update");
		
		if (kill (this->HaAgentPid, SIG_UPDATE_DISK) < 0 ){
			syslog(LOG_ERR, "Failed to send SIG_UPDATE_DISK Signal to RDE on. errno:[%d]",errno);
		}	
	}
	
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::getAgentDebugPid(){
        FILE *p_fd;
        ACE_TCHAR command_string[CMD_LEN];
        ACE_TCHAR line[80];
        ACE_OS::memset(command_string ,0 ,CMD_LEN);
        ACE_OS::snprintf(command_string ,CMD_LEN , "pidof apos_ha_rdeagentd");
	line[0]='\0';
	
        p_fd = popen (command_string,"r");

        if ( p_fd == NULL ){
                syslog(LOG_ERR, "DEVMON: popen error to lanuch [%s]" ,command_string);
                return ACS_APGCC_FAILURE ;
        }

        while (!feof(p_fd)) {
                ACE_INT32 attemp_count=0;

                while (fgets(line, sizeof(line)-1, p_fd) == NULL) {
                //if (ferror(p_fd)) syslog(LOG_ERR, "RDE_Agent: ERROR on reading pipe. Error:[%s]", strerror(errno));
                        if (attemp_count++ > 10 ) break; // from inner while
                                continue;
                } // inner while

                if (line[0] == '\0'){
                        syslog(LOG_ERR, "DevMon : Counter NULL data found");
                        break; // from outer while
                }
        }

        this->HaAgentPid=atoi(line);
        syslog(LOG_INFO,"on pid [%d]",this->HaAgentPid);
	pclose(p_fd);
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::getHaAgentPid(){

	FILE *fp;
	ACE_TCHAR buff1[10];
	buff1[0]='\0';
	fp = ACE_OS::fopen(AGENT_PID_FILE, "r");
	if ( fp == NULL ) {
		syslog(LOG_ERR, "Error! FAILED to open FILE [%s]",AGENT_PID_FILE);
		return ACS_APGCC_FAILURE;
	}

	if (fscanf(fp ,"%s" ,buff1) != 1 ) {
		(void)fclose(fp);
		syslog(LOG_ERR ,"Unable to Retreive the pid from file [ %s ]" ,AGENT_PID_FILE);
		return ACS_APGCC_FAILURE;
	}

	this->HaAgentPid=atoi(buff1);
	syslog(LOG_INFO,"on pid [%d]",this->HaAgentPid);

	if (ACE_OS::fclose(fp) != 0 ) {
		syslog(LOG_ERR ,"Error! fclose FAILED");
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}




ACE_INT32 DevMonClass::getGepId() const{

	return this->gep_id;
}

ACS_APGCC_ReturnType DevMonClass::populateDiskInfo(){
	
	ACS_APGCC_BOOL populateStruct=TRUE;
	
	if (monitorControllersAndDatadisks(populateStruct) != ACS_APGCC_SUCCESS){
		return ACS_APGCC_FAILURE;
	}
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType DevMonClass::populateRAIDInfo(){

	ACS_APGCC_BOOL populateStruct = TRUE;
	
	if (Is_RAIDInfoPopulated){
		return ACS_APGCC_SUCCESS;
	}

	if(monitorRAID(populateStruct) != ACS_APGCC_SUCCESS){
		return ACS_APGCC_FAILURE;
	}

	Is_RAIDInfoPopulated=TRUE;
	return ACS_APGCC_SUCCESS;
}
ACS_APGCC_ReturnType DevMonClass::updateDatadiskStatus(){

	int retCode;
	ACE_TCHAR command_string[CMD_LEN];

	ACE_OS::memset(command_string ,0 ,CMD_LEN);
	ACE_OS::snprintf(command_string ,CMD_LEN ,HA_BASE_CMD " --update-diskstatus");

	retCode = ACE_OS::system(command_string);
	if (retCode == -1 ){
		syslog(LOG_ERR, "\"system\" call failed while executing the command %s",command_string);
		return ACS_APGCC_FAILURE;
	}
	
	retCode = WEXITSTATUS(retCode);
	if (retCode != 0) {
		syslog(LOG_ERR,"[ %s ]command failed with error code: %d",command_string,retCode);
		return ACS_APGCC_FAILURE;
	}
	
	return ACS_APGCC_SUCCESS;
}


ACS_APGCC_ReturnType DevMonClass::setNodeId() {

	FILE* fp;
	ACE_TCHAR buff[10];

	fp = ACE_OS::fopen(NODE_ID_FILE,"r");
	if ( fp == NULL ) {
		syslog(LOG_ERR, "Error! fopen FAILED");
		return ACS_APGCC_FAILURE;
	}

	if (fscanf(fp ,"%s" ,buff) != 1 ) {
		(void)fclose(fp);
		syslog(LOG_ERR ,"Unable to Retreive the node id from file [ %s ]" ,NODE_ID_FILE);
		return ACS_APGCC_FAILURE;
	}
	
	if (ACE_OS::fclose(fp) != 0 ) {
		syslog(LOG_ERR ,"Error! fclose FAILED");
		return ACS_APGCC_FAILURE;
	}

	this->node_id= ACE_OS::atoi(buff);
	syslog(LOG_INFO ,"Running on NODE:%d",this->node_id);
	return ACS_APGCC_SUCCESS;
}

ACE_INT32 DevMonClass::getNodeId() const{
	return this->node_id;
}	


