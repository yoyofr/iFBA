// Burner DipSwitches Dialog module
#include "burner.h"

static unsigned char nPrevDIPSettings[4];

static int nDIPOffset;

static bool bOK;

static void InpDIPSWGetOffset()
{
	BurnDIPInfo bdi;
    
	nDIPOffset = 0;
	for (int i = 0; BurnDrvGetDIPInfo(&bdi, i) == 0; i++) {
		if (bdi.nFlags == 0xF0) {
			nDIPOffset = bdi.nInput;
			break;
		}
	}
}

void InpDIPSWResetDIPs()
{
	int i = 0;
	BurnDIPInfo bdi;
	struct GameInp* pgi;
    
	InpDIPSWGetOffset();
    
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if (bdi.nFlags == 0xFF) {
			pgi = GameInp + bdi.nInput + nDIPOffset;
			pgi->Input.Constant.nConst = (pgi->Input.Constant.nConst & ~bdi.nMask) | (bdi.nSetting & bdi.nMask);
		}
		i++;
	}
}

static bool CheckSetting(int i)
{
	BurnDIPInfo bdi;
	BurnDrvGetDIPInfo(&bdi, i);
	struct GameInp* pgi = GameInp + bdi.nInput + nDIPOffset;
    
	if ((pgi->Input.Constant.nConst & bdi.nMask) == bdi.nSetting) {
		unsigned char nFlags = bdi.nFlags;
		if ((nFlags & 0x0F) <= 1) {
			return true;
		} else {
			for (int j = 1; j < (nFlags & 0x0F); j++) {
				BurnDrvGetDIPInfo(&bdi, i + j);
				pgi = GameInp + bdi.nInput + nDIPOffset;
				if (nFlags & 0x80) {
					if ((pgi->Input.Constant.nConst & bdi.nMask) == bdi.nSetting) {
						return false;
					}
				} else {
					if ((pgi->Input.Constant.nConst & bdi.nMask) != bdi.nSetting) {
						return false;
					}
				}
			}
			return true;
		}
	}
	return false;
}

int InpDIPSWGetNb() {
    BurnDIPInfo bdi;
	unsigned int i = 0, j = 0, k = 0;
	char* pDIPGroup = NULL;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {
				pDIPGroup = bdi.szText;
				k = i;
			}
			i++;
		} else {
			if (CheckSetting(i)) {                
				j++;
			}
			i += (bdi.nFlags & 0x0F);
		}
	}
    return j;
}

int InpDIPSWGetValueNb(int dip_idx) {
	BurnDIPInfo bdi;
	unsigned int i = 0, k = 0;
	char* pDIPGroup = NULL;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {
				pDIPGroup = bdi.szText;
                if (k==dip_idx) return bdi.nSetting;
				k++;
			}
			i++;
		} else {
			i += (bdi.nFlags & 0x0F);
		}
	}
    return 0;
}

char *InpDIPSWGetValueString(int dip_idx,int val_idx) {
	BurnDIPInfo bdi;
	unsigned int i = 0, k = 0;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {				
                if (k==dip_idx) {
                    //
                    if (BurnDrvGetDIPInfo(&bdi, i+val_idx+1)==0) return bdi.szText;
                }
				k++;
			}
			i++;
		} else {
			i += (bdi.nFlags & 0x0F);
		}
	}
    return NULL;
}

unsigned char InpDIPSWGetDIPValue(int dip_idx, int val_idx) {
    BurnDIPInfo bdi;
	unsigned int i = 0, k = 0;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {				
                if (k==dip_idx) {
                    //
                    if (BurnDrvGetDIPInfo(&bdi, i+val_idx+1)==0) return bdi.nSetting;
                }
				k++;
			}
			i++;
		} else {
			i += (bdi.nFlags & 0x0F);
		}
	}
    return 255;
}


char *InpDIPSWGetCurrentValue(int dip_index,int *dip_current_value) {
	BurnDIPInfo bdi;
	unsigned int i = 0, j = 0, k = 0, dip_ofs=0;
	char* pDIPGroup = NULL;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {
				pDIPGroup = bdi.szText;
				k++;
                dip_ofs=i;
			}
			i++;
		} else {
			if (CheckSetting(i)) {                
                if (k==(dip_index+1)) {
                    if (dip_current_value) *dip_current_value=i-dip_ofs-1;
                    return bdi.szText;
                }
				j++;
			}
			i += (bdi.nFlags & 0x0F);
		}
	}
	return NULL;
}

static bool CheckUpdateSetting(int i,unsigned char newval)
{
	BurnDIPInfo bdi;
	BurnDrvGetDIPInfo(&bdi, i);
	struct GameInp* pgi = GameInp + bdi.nInput + nDIPOffset;
    
	if ((pgi->Input.Constant.nConst & bdi.nMask) == bdi.nSetting) {
		unsigned char nFlags = bdi.nFlags;
		if ((nFlags & 0x0F) <= 1) {
            pgi->Input.Constant.nConst=pgi->Input.Constant.nConst & (~(bdi.nMask));
            pgi->Input.Constant.nConst=pgi->Input.Constant.nConst|newval;
			return true;
		} else {
			for (int j = 1; j < (nFlags & 0x0F); j++) {
				BurnDrvGetDIPInfo(&bdi, i + j);
				pgi = GameInp + bdi.nInput + nDIPOffset;
				if (nFlags & 0x80) {
					if ((pgi->Input.Constant.nConst & bdi.nMask) == bdi.nSetting) {                        
						return false;
					}
				} else {
					if ((pgi->Input.Constant.nConst & bdi.nMask) != bdi.nSetting) {
						return false;
					}
				}
			}
            pgi->Input.Constant.nConst=pgi->Input.Constant.nConst & (~(bdi.nMask));
            pgi->Input.Constant.nConst=pgi->Input.Constant.nConst|newval;
			
			return true;
		}
	}
	return false;
}


int InpDIPSWSetCurrentValue(int dip_index,unsigned char dip_new_value) {
	BurnDIPInfo bdi;
	unsigned int i = 0, j = 0, k = 0, dip_ofs=0;
	char* pDIPGroup = NULL;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {
				pDIPGroup = bdi.szText;
				k++;
                dip_ofs=i;
			}
			i++;
		} else {
            if (k==(dip_index+1)) {
                if (CheckUpdateSetting(i,dip_new_value)) {
                    return 0;
                }
            }
			i += (bdi.nFlags & 0x0F);
		}
	}
	return 1;
}


char *InpDIPSWGetDIPName(int dip_index) {
	BurnDIPInfo bdi;
	unsigned int i = 0, j = 0, k = 0;
	while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
		if ((bdi.nFlags & 0xF0) == 0xF0) {
		   	if (bdi.nFlags == 0xFE || bdi.nFlags == 0xFD) {

                if (k==dip_index) return bdi.szText;
				k++;
			}
			i++;
		} else {
			if (CheckSetting(i)) {                
				j++;
			}
			i += (bdi.nFlags & 0x0F);
		}
	}
	return NULL;
}


static int InpDIPSWInit()
{
	BurnDIPInfo bdi;
	struct GameInp *pgi;
    
	InpDIPSWGetOffset();
    
	for (int i = 0, j = 0; BurnDrvGetDIPInfo(&bdi, i) == 0; i++) {
		if (bdi.nInput >= 0  && bdi.nFlags == 0xFF) {
			pgi = GameInp + bdi.nInput + nDIPOffset;
			nPrevDIPSettings[j] = pgi->Input.Constant.nConst;
			j++;
		}
	}
    
	return 0;
}

static int InpDIPSWExit()
{
	GameInpCheckMouse();
	return 0;
}

static void InpDIPSWCancel()
{
	if (!bOK) {
		int i = 0, j = 0;
		BurnDIPInfo bdi;
		struct GameInp *pgi;
		while (BurnDrvGetDIPInfo(&bdi, i) == 0) {
			if (bdi.nInput >= 0 && bdi.nFlags == 0xFF) {
				pgi = GameInp + bdi.nInput + nDIPOffset;
				pgi->Input.Constant.nConst = nPrevDIPSettings[j];
				j++;
			}
			i++;
		}
	}
}

// Create the list of possible values for a DIPswitch
static void InpDIPSWSelect()
{
}

int InpDIPSWCreate()
{
	if (bDrvOkay == 0) {									// No game is loaded
		return 1;
	}
    
	bOK = false;
    
	return 0;
}
