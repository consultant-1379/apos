#ifndef APOS_HA_FDEVMON_ADM_H
#define APOS_HA_FDEVMON_ADM_H

#include <unistd.h>
#include <syslog.h>
#include <ace/Task_T.h>
#include <ace/Sig_Handler.h>
#include <ace/OS.h>
#include <ACS_APGCC_ApplicationManager.h>
#include "apos_ha_fdevmon_class.h"

class HAClass;

class admClass: public ACE_Task<ACE_SYNCH> {

   private:
	HAClass* m_haObj;
	int open(HAClass* haObj);
	int open(int argc, char* argv[]);
   public:
	
	admClass();
	~admClass(){};
	int start(HAClass* haObj );
	int start(int argc, char* argv[]);
	void stop();
	virtual int svc();
	ACE_Sig_Handler sig_shutdown_;
	int handle_signal(int signum, siginfo_t*, ucontext_t *);
}; 

#endif 

