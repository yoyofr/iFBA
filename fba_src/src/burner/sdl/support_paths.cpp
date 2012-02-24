#include "burner.h"


TCHAR szAppPreviewsPath[MAX_PATH]	= "support/previews/";
TCHAR szAppTitlesPath[MAX_PATH]		= "support/titles/";
TCHAR szAppCheatsPath[MAX_PATH]		= "support/cheats/";
TCHAR szAppHiscorePath[MAX_PATH]	= "support/hiscores/";
TCHAR szAppSamplesPath[MAX_PATH]	= "support/samples/";
TCHAR szAppIpsPath[MAX_PATH]		= "support/ips/";
TCHAR szAppIconsPath[MAX_PATH]		= "support/icons/";

static TCHAR szCheckIconsPath[MAX_PATH];

bool bDoIpsPatch = 0;

void IpsApplyPatches(UINT8* base, char* rom_name) {
    
}

