#ifndef APG_APP2_APPCLASS_H
#define APG_APP2_APPCLASS_H

#include "unistd.h"
#include "syslog.h"
#include <ace/Task_T.h>
#include <ace/OS.h>

class DevMonClass;
class APOS_HA_ReactorRunner;

class devmonClass: public ACE_Task<ACE_SYNCH> {

   private:

	DevMonClass* m_haObj;
	APOS_HA_ReactorRunner* m_reactorRunner; 
	ACE_INT32 m_timerid;

   public:
	devmonClass();
	~devmonClass(){};
	int active(DevMonClass*);
	int svc();
	int passive(DevMonClass*);
	void stop();
	int close(u_long);
	int handle_timeout(const ACE_Time_Value& tv, const void*);
}; 

#endif /* APG_APP2_APPCLASS_H */
