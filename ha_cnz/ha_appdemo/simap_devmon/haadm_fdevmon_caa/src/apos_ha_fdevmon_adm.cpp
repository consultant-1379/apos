#include "apos_ha_fdevmon_adm.h"
#include "apos_ha_fdevmon_class.h"

const int SHUTDOWN=111;

admClass::admClass(){
	// empty
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
int admClass::start(int argc, char* argv[]) {

	(void)argc;
	(void)argv;
	syslog(LOG_INFO,"app-class: start invoked");
	return this->open(argc, argv);
}
//-------------------------------------------------------------------------------------------------------------
int admClass::open(int argc, char* argv[]) {

	(void)argc;
	(void)argv;

    int status = this->sig_shutdown_.register_handler(SIGINT, this);
    if (status < 0) {
        syslog(LOG_ERR, "app-class: %s() register_handler(SIGINT,this) failed..",__func__);
        return -1;
    }
    status = this->sig_shutdown_.register_handler(SIGTERM, this);
    if (status < 0) {
        syslog(LOG_ERR, "app-class: %s() register_handler(SIGTERM,this) failed.",__func__);
        return -1;
    }
	syslog(LOG_INFO, "app-class: open invoked");
	return this->activate( THR_JOINABLE | THR_NEW_LWP );
}

//--------------------------------------------------------------------------
int admClass::handle_signal(int signum, siginfo_t*, ucontext_t *)
{
    switch (signum) {
        case SIGTERM:
            syslog(LOG_INFO, "app-class: - signal SIGTERM caught...");
            break;
        case SIGINT:
            syslog(LOG_INFO, "app-class: - signal SIGINT caught...");
            break;
        default:
            syslog(LOG_INFO, "app-class: - other signal caught..[%d]", signum);
            break;
    }

	this->stop();
    return 0;
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

	ACE_Message_Block* mb=0;
	while (!done) {
		res = this->getq(mb);
		if (res < 0)
			break;
		
		//Checked received message
		switch( mb->msg_type() ){
			case SHUTDOWN: {
				syslog(LOG_INFO, "app-class: received SHUTDOWN");
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
	}
	return 0;
}
//-------------------------------------------------------------------------------------------------------------

