#include "apg_app2_appclass.h"
#include "apg_app2_class.h"

int myClass::active(HAClass* haObj ){

	m_haObj=haObj;
	m_haObj->log.Write("app-class: active invoked", LOG_LEVEL_INFO);

	// start with active activities.
	return 0;
}

int myClass::passive(HAClass* haObj ){

	m_haObj=haObj;
	m_haObj->log.Write("app-class: passive invoked", LOG_LEVEL_INFO);

	// start with passive activities.
	return 0;
}

void myClass::stop() {
	m_haObj->log.Write("app-class: stop invoked", LOG_LEVEL_INFO);
	// start shutdown activities.
}



