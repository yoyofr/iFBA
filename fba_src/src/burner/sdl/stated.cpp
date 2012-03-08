// State dialog module
#include "burner.h"

char szChoice[256];

int bDrvSaveAll = 0;

// The automatic save
int StatedAuto(int bSave) {
	static TCHAR szName[32] = "";
	int nRet;
    
	sprintf(szName, "/var/mobile/Documents/iFBA/%s.fs", BurnDrvGetText(DRV_NAME));
    
	if (bSave == 0) {
		nRet = BurnStateLoad(szName, bDrvSaveAll, NULL);		// Load ram
		if (nRet && bDrvSaveAll)	{
			nRet = BurnStateLoad(szName, 0, NULL);				// Couldn't get all - okay just try the nvram
		}
	} else {
		nRet = BurnStateSave(szName, bDrvSaveAll);				// Save ram
	}
    
	return nRet;
}

static void CreateStateName(int nSlot) {
	sprintf(szChoice, "/var/mobile/Documents/iFBA/%s_%02x.fs", BurnDrvGetText(DRV_NAME), nSlot);
}

int StatedLoad(int nSlot) {
	int nRet;
    
	CreateStateName(nSlot);
    
	nRet = BurnStateLoad(szChoice, 1, &DrvInitCallback);
    
	return nRet;
}

int StatedSave(int nSlot) {
	int nRet;
    
	if (bDrvOkay == 0) {
		return 1;
	}
    
    CreateStateName(nSlot);
    
	nRet = BurnStateSave(szChoice, 1);
    
	return nRet;
}
