#include "apos_ha_devmon_appclass.h"
#include "apos_ha_devmon_class.h"
#include "apos_ha_reactorrunner.h"

//ACE_THR_FUNC_RETURN svc_run(void *);

//ACE_thread_t devmon_worker_thread_id;
const int SHUTDOWN=111;
const int TIMEOUT =110;
static bool shutDownRcvd=false;

devmonClass::devmonClass():
m_timerid(0)
{

}

int devmonClass::active(DevMonClass* haObj ){

	m_haObj=haObj;
	ACE_NEW_NORETURN(m_reactorRunner, APOS_HA_ReactorRunner());
	if (0 == m_reactorRunner) {
		syslog(LOG_ERR, "%s() Failed to create APOS_HA_ReactorRunner", __func__);
		return -1;
	}	
	int res = m_reactorRunner->open();
	if (res < 0) {
		syslog(LOG_ERR, "Failed to start ACS_HA_ReactorRunner");
		return -1;
	}	
	if( this->activate( THR_JOINABLE | THR_NEW_LWP ) < 0 ){
		syslog(LOG_ERR, "%s() Failed to start main svc thread.", __func__);
		return -1;
	}
	// schedule a timer to monitor data disks.
	const ACE_Time_Value schedule_time(TWO_SECONDS_INTERVAL); // First interation interval
	m_timerid = m_reactorRunner->m_reactor->schedule_timer(this, 0, schedule_time);

	if (this->m_timerid < 0){
		syslog(LOG_ERR, "%s() - Unable to schedule timer.", __func__);
		return -1;
	}	
	return 0;
}


int devmonClass::passive(DevMonClass* haObj ){

	m_haObj=haObj;
	ACE_NEW_NORETURN(m_reactorRunner, APOS_HA_ReactorRunner());
	if (0 == m_reactorRunner) {
		syslog(LOG_ERR, "%s() Failed to create APOS_HA_ReactorRunner", __func__);
		return -1;
	}	
	int res = m_reactorRunner->open();
	if (res < 0) {
		syslog(LOG_ERR, "Failed to start ACS_HA_ReactorRunner");
		return -1;
	}	
	if( this->activate( THR_JOINABLE | THR_NEW_LWP ) < 0 ){
		syslog(LOG_ERR, "%s() Failed to start main svc thread.", __func__);
		return -1;
	}
	// schedule a timer to monitor data disks.
	const ACE_Time_Value schedule_time(TWO_SECONDS_INTERVAL);  
	m_timerid = m_reactorRunner->m_reactor->schedule_timer(this, 0, schedule_time);

	if (this->m_timerid < 0){
		syslog(LOG_ERR, "%s() - Unable to schedule timer.", __func__);
		return -1;
	}	
	return 0;
}

void devmonClass::stop() {
	// start shutdown activities.
	/* We were active and now losing active state due to some shutdown admin
	 * operation performed on our SU.
	 * Inform the thread to go to "stop" state
	 */
	
	syslog(LOG_INFO, "Received QUIESING state assignment!!!");
	//ACE_Thread_Manager::instance()->join(devmon_worker_thread_id);
	/* Inform the thread to go "stop" state */

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
			shutDownRcvd=true;
                        syslog(LOG_INFO, "app-class:SHUTDOWN Ordered Internally");
                }
        }
}

int devmonClass::svc() {

        bool done=false;
        int res=0;
//	m_haObj->populateStruct=FALSE;	
	//	DevMonClass *dMonObj;
	syslog(LOG_INFO, "Application is thread is starting...");

        if ( m_haObj->Initialize()!= ACS_APGCC_SUCCESS ) {
		syslog(LOG_ERR,"RDE_Devmon: Devmon Initialized.");
		return -1;
        }
	
	ACE_Message_Block* mb=0;

        while (!done){
                res = this->getq(mb);
                if (res < 0){
			syslog(LOG_ERR, " devmonClass: getq Failed");
                        break;
		}

                //Checked received message
                switch( mb->msg_type() ){

                        case SHUTDOWN: {
                                syslog(LOG_INFO, "app-class: received SHUTDOWN");
				shutDownRcvd=false;
                                done=true;
                                mb->release();
                                mb=0;
                                break;
                        }
			
			case TIMEOUT: {
                                if( true == shutDownRcvd ){
					shutDownRcvd=false;
					done=true;
				        syslog(LOG_INFO, "In devmonClass: TIMEOUT - shutDownRcvd");
					mb->release();
					mb=0;
					break;
				}	
                                mb->release();
                                mb=0;

				//syslog(LOG_INFO, "devmonClass: TIMEOUT");
				if (ACS_APGCC_SUCCESS != m_haObj->monitorControllersAndDatadisks(m_haObj->populateStruct)){
					syslog(LOG_ERR, "Failed to monitor Controllers and Data disks");
                		}
				
                		if(m_haObj->Is_Active){
                        		if (m_haObj->monitorRAID(m_haObj->populateStruct) != ACS_APGCC_SUCCESS){
                                		syslog(LOG_ERR, "RAID Monitor FAILED!");
					}
                        	}
				break;
			}		      
						       
                        default: {
                                syslog(LOG_ERR, "app-class:[%d] Unknown message received:", mb->msg_type());
                                mb->release();
                                mb=0;
                                break;
                        }
                }
        }// end of while

        return 0;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------

int devmonClass::handle_timeout(const ACE_Time_Value&, const void* ) {


        ACE_Message_Block* mb = 0;
        ACE_NEW_NORETURN(mb, ACE_Message_Block());
        int rCode=0;

//        syslog(LOG_INFO, "%s(): ZombieMon: handle_timeout", __func__);

        // Post a new ZMBE_TIMEOUT message to svc.
        if (mb != 0) {
                mb->msg_type(TIMEOUT);
                if (this->putq(mb) < 0) {
                        mb->release();
                }
        }

        // re-schedule the timer
		ACE_Time_Value schedule_time(FIVE_SECONDS_INTERVAL);// monitor every 5secs for GEP2
		if (m_haObj ->getGepId() == GEP_ONE) { 
			schedule_time=TEN_SECONDS_INTERVAL; // monitor every 10secs for GEP1
		}
	
        m_timerid = m_reactorRunner->m_reactor->schedule_timer(this, 0, schedule_time);

        if (this->m_timerid < 0){
                syslog(LOG_ERR, "%s() - Unable to schedule timer.", __func__);
                rCode=-1;
        }

        return rCode;
}

//----------------------------------------------------------------------------------------------------------------------------------
int devmonClass::close(u_long /* flags */){

	// Stop reactor
	if (m_reactorRunner != 0) {
		m_reactorRunner->stop();
		m_reactorRunner->wait();
		delete m_reactorRunner;
		m_reactorRunner = 0;
	}	
	return 0;
}

//----------------------------------------------------------------------------------------------------------------------------------
