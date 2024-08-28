#include "apos_ha_fagent_adm.h"
#include "apos_ha_fagent_class.h"

const int SHUTDOWN=111;
ACS_APGCC_BOOL debugEnabled;

admClass::admClass(){
	passiveToActive=0;
}	

//-------------------------------------------------------------------------------------------------------------
int admClass::start(HAClass* haObj ){

	if (0 == haObj) {
		syslog(LOG_ERR, "NULL haObj found");
		return -1;
	}
	m_haObj=haObj;
	syslog(LOG_INFO,"app-class: start invoked");
	return this->open(0,0);
}

//-------------------------------------------------------------------------------------------------------------
int admClass::open(int argc, char* argv[]) {

	(void)argc;
	(void)argv;
	syslog(LOG_INFO, "app-class: open invoked");
	return this->activate( THR_JOINABLE | THR_NEW_LWP );
}

//-------------------------------------------------------------------------------------------------------------
void admClass::stop() {
	syslog(LOG_INFO, "app-class: stop invoked");
	ACE_Message_Block* mb=0;

	ACE_NEW_NORETURN(mb, ACE_Message_Block());
	if (mb == 0){
		syslog(LOG_ERR, "app-class:Failed create message SHUTDOWN");
	} else {
		mb->msg_type(SHUTDOWN);
		if (this->putq(mb) < 0){
			mb->release();
			mb=0;
			syslog(LOG_ERR, "app-class:Failed to send msg SHUTDOWN");
		}else{
			syslog(LOG_INFO, "app-class:SHUTDOWN Ordered Internally");
		}	
	}
}

//-------------------------------------------------------------------------------------------------------------
int admClass::svc() {
	
	bool done=false;
	int res=0;

	// mount the data disks here.
	
	if ( mountRAIDandActivateMIPs()!= ACS_APGCC_SUCCESS ) {
		if (!this->IsRAIDConfigured) {
			syslog(LOG_INFO ,"RDE_Agent: RAID and MIP Configure FAILED on Active Node.");
			return -1;
		}
	}	
	ACE_Message_Block* mb=0;
	while (!done){
		res = this->getq(mb);
		if (res < 0)
			break;
		
		//Checked received message
		switch( mb->msg_type() ){

			case SHUTDOWN: {
				syslog(LOG_INFO, "app-class: received SHUTDOWN");
				if (this->umountRAIDandDeactivateMIPs() != ACS_APGCC_SUCCESS){
					syslog(LOG_ERR, "RDE_Agent: unmount and Deactivate MIP FAILED");
				}	

				mb->release();					   
				mb=0;
				done=true;
				break;
			}

			default: {
		      		mb->release();
       				mb=0;
				syslog(LOG_ERR, "app-class:[%d] Unknown message received:", mb->msg_type());				
				break;
			}	
		}		
	}// end of while
	return ACS_APGCC_SUCCESS;
}

//-------------------------------------------------------------------------------------------------------------

ACS_APGCC_ReturnType admClass::mountRAIDandActivateMIPs(){

        /* Mount RAID Using APOS script raidmgmt
         * Check for the MIP status. If it is already
         * configured then do nothing, else Configure MIP
         */

        ACE_TCHAR command_string[CMD_LEN];
        ACS_APGCC_ReturnType errorCode;

        if (this->IsRAIDConfigured == TRUE) {
                syslog(LOG_INFO, "RDE_Agent: Configure RAID already done");
        }
        else {
                ACE_OS::memset(command_string ,0 ,CMD_LEN);
                ACE_OS::snprintf(command_string ,CMD_LEN,DISK_MGMT_CMD " --assemble --mount --force");
                errorCode = launchCommand(command_string);
                if ( errorCode == ACS_APGCC_FAILURE ) {
                        syslog (LOG_ERR,"RDE_Agent: RAID Config on Active Node FAILED.Initiating Failover...");
                        InitiateFailover(ACS_APGCC_COMPONENT_FAILOVER);
                        return ACS_APGCC_FAILURE;
                }

                this->IsRAIDConfigured=TRUE;
                syslog(LOG_INFO ,"RDE_Agent: Mount and Configure RAID Success!");
        }

        /* Activate MIPs and do necessary actions*/
        if (this->IsMIPConfigured == TRUE){
                syslog(LOG_INFO, "RDE_Agent: Configure MIP already done");
        }
        else {
                ACE_OS::memset(command_string ,0 ,CMD_LEN);
                if (this->passiveToActive)
                        ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -f passive");
                else
                        ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -s");

                errorCode = launchCommand(command_string);
                if ( errorCode == ACS_APGCC_FAILURE ) {
                        syslog (LOG_ERR,"RDE_Agent: MIP Activate FAILED on Active Node");
                        return ACS_APGCC_SUCCESS; // This is to not let the daemon go down for MIP Fail
                }
                this->IsMIPConfigured = TRUE;
                syslog(LOG_INFO ,"RDE_Agent: Activating MIP Success on Active Node");
        }

        return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType admClass::umountRAIDandDeactivateMIPs(){

        /* Deactivate RAID Using APOS script raidmgmt
	 *          * and unmount Data disks and Deactivate MIPs
	 *                   */
        syslog(LOG_INFO ,"RDE_Agent: Request to deactivate RAID And MIP");
        ACE_TCHAR command_string[CMD_LEN];
        ACS_APGCC_ReturnType errorCode=ACS_APGCC_SUCCESS;
        ACS_APGCC_ReturnType rCode=ACS_APGCC_SUCCESS;

        if (this->IsMIPConfigured == FALSE){
	        syslog(LOG_INFO, "RDE_Agent: MIP already deactivated");
	}
	else {
		/* Deactivate MIPs */
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
	        ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " -f active");
	        errorCode = launchCommand(command_string);
	        if ( errorCode == ACS_APGCC_FAILURE ) {
		        syslog (LOG_ERR,"RDE_Agent: MIP Deactivate FAILED on Active Node");
		        rCode=ACS_APGCC_FAILURE;
		}
		syslog(LOG_INFO, "RDE_Agent: MIP deactivated Successfully");
	}

	if (this->IsRAIDConfigured == FALSE) {
		syslog(LOG_INFO, "RDE_Agent: RAID already disabled");
	}
	else {
		/* Cleanup Active RAID Users  */
		syslog (LOG_ERR,"RDE_Agent: Cleanup Active RAID Users.");
		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN ,APOS_BASE_CMD " --cleanup");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: Cleanup Active RAID users FAILED");
		}

		ACE_OS::memset(command_string ,0 ,CMD_LEN);
		ACE_OS::snprintf(command_string ,CMD_LEN,DISK_MGMT_CMD " --disable --unmount");
		errorCode = launchCommand(command_string);
		if ( errorCode == ACS_APGCC_FAILURE ) {
			syslog (LOG_ERR,"RDE_Agent: Unmount RAID FAILED");
			rCode=ACS_APGCC_FAILURE;
		}
		else {
			syslog(LOG_INFO ,"RDE_Agent: Umount RAID Success!");
		}
	}
	return ACS_APGCC_SUCCESS;
}

ACS_APGCC_ReturnType admClass::launchCommand(char *command_string) {

        int retCode;

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

ACS_APGCC_ReturnType admClass::handleRdeAgentGracefullDownJobs(){

        /* handle all gracefull jobs here  */

        if (!this->Is_State_Assgned) {
                syslog(LOG_INFO, "RDE_Agent: No Graceful jobs required, Active assignment not done");
                return ACS_APGCC_SUCCESS;
        }

        if (this->Is_Agent_Stanby){
                syslog(LOG_INFO, "RDE_Agent: STNDBY - No gracefullJobs to be done");
                return ACS_APGCC_SUCCESS;
        }

        if (this->handleRdeAgentGracefullDownJobsDone) {
                syslog(LOG_INFO, "RDE_Agent: Gracefull down Jobs are already performed");
                return ACS_APGCC_SUCCESS;
        }

        if (this->umountRAIDandDeactivateMIPs() != ACS_APGCC_SUCCESS){
                syslog(LOG_ERR, "RDE_Agent: unmount and Deactivate MIP FAILED");
                return ACS_APGCC_FAILURE;
        }

        /* handle here if there are any left out jobs */
        this->handleRdeAgentGracefullDownJobsDone=TRUE;
        return ACS_APGCC_SUCCESS;
}


void admClass::InitiateFailover(ACS_APGCC_AMF_RecommendedRecoveryT recommendedRecovery){

        syslog(LOG_INFO, "RDE_Agent: InitiateFailover Received");

        if ( !this->handleRdeAgentGracefullDownJobsDone) {
                if (this->handleRdeAgentGracefullDownJobs() != ACS_APGCC_SUCCESS){
                        syslog(LOG_ERR, "RDE_Agent: handleRdeAgentGracefullDownJobs FAILED! Forcing the Failover anyway.");
                        /* Force Node to failover if the gracefuldown jobs fail */
                        recommendedRecovery=ACS_APGCC_NODE_FAILOVER;
                }
        }
        else {
                syslog(LOG_INFO, "RDE_Agent: Gracefull jobs already performed!");
        }

        if (m_haObj->componentReportError(recommendedRecovery) != ACS_APGCC_SUCCESS){
                syslog(LOG_ERR, "RDE_Agent: componentReportError FAILED NODE FAILOVER Recovery Action");
                /* FAILOVER Action FAILED. Try rebooting the node forcefully */
                reboot_local_node();
        }
}

void admClass::reboot_local_node() {

        ACE_TCHAR command_string[CMD_LEN];
        ACS_APGCC_ReturnType errorCode;
	
        syslog(LOG_INFO, "RDE_Agent: RDE Agent initiating reboot...");

        if (debugEnabled) {
                syslog(LOG_INFO, "RDE_Agent: Releasing AMF registration...");
        }
        /* release amf registrations */
        if (m_haObj->finalize() != ACS_APGCC_SUCCESS ){
                syslog(LOG_ERR, "RDE_Agent :rdaObj->finalize FAILED");
        }

        ACE_OS::memset(command_string ,0 ,CMD_LEN);
        ACE_OS::snprintf(command_string ,CMD_LEN,HA_BASE_CMD " --reboot-node");
        errorCode = launchCommand(command_string);
}
