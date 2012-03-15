// State dialog module
#include "burner.h"

char szChoice[256];
extern char debug_root_path[256];

int bDrvSaveAll = 0;

// The automatic save
int StatedAuto(int bSave) {
	static TCHAR szName[32] = "";
	int nRet;
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.fs", debug_root_path,BurnDrvGetText(DRV_NAME));
#else
	sprintf(szName, "/var/mobile/Documents/iFBA/%s.fs", BurnDrvGetText(DRV_NAME));
#endif
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
#ifdef RELEASE_DEBUG
    sprintf(szChoice, "%s/%s_%02x.fs", debug_root_path,BurnDrvGetText(DRV_NAME),nSlot);
#else
	sprintf(szChoice, "/var/mobile/Documents/iFBA/%s_%02x.fs", BurnDrvGetText(DRV_NAME), nSlot);
#endif
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
