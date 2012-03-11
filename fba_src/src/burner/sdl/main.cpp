/*----------------
Stuff to finish:

It wouldn't be a stretch of the imagination to think the whole of the sdl 'port' needs a redo but here are the main things wrong with this version:


There is OSD of any kind which makes it hard to display info to the users.
There are lots of problems with the audio output code.
There are lots of problems with the opengl renderer
probably many other things.
------------------*/
#include "burner.h"
#include "fbaconf.h"

extern bool bSoundOn;

int nAppVirtualFps = 6000;			// App fps * 100
bool bRunPause=0;
bool bAlwaysProcessKeyboardInput=0;

extern bool bBurnUseASMCPUEmulation;

void init_emu(int gamenum) {
 	bCheatsAllowed=false;
	ConfigAppLoad();
	ConfigAppSave();
    
#if TARGET_IPHONE_SIMULATOR
    bBurnUseASMCPUEmulation=0;
#else
	bBurnUseASMCPUEmulation=ifba_conf.asm_68k;
#endif    

    
	DrvInit(gamenum,0);
}

void CheckFirstTime()
{

}

void ProcessCommandLine(int argc, char *argv[])
{

}

int fba_main(int argc, char *argv[]) 
{
	UINT32 i=0;
    
    
    bSoundOn=ifba_conf.sound_on;
    bForce60Hz=ifba_conf.video_60hz;
	
	ConfigAppLoad(); 
	
	CheckFirstTime(); // check for first time run
	
	//SDL_Init(SDL_INIT_TIMER|SDL_INIT_VIDEO);

	BurnLibInit(); 

	//SDL_WM_SetCaption( "FBA, SDL port.", "FBA, SDL port.");
	//SDL_ShowCursor(SDL_DISABLE);

	if (argc == 2)
	{
		for (i = 0; i < nBurnDrvCount; i++) {
			//nBurnDrvSelect[0] = i;
            nBurnDrvActive=i;
            if (strcmp(BurnDrvGetTextA(0), argv[1]) == 0) {
				break;
			}
		}

		if (i == nBurnDrvCount) {
			printf("%s is not supported by FB Alpha.",argv[1]);
			return 1;
		}
	}
    
    //Check if console & should patch rom len
    if ((BurnDrvGetHardwareCode()&HARDWARE_PREFIX_PCENGINE==HARDWARE_PREFIX_PCENGINE)||
        (BurnDrvGetHardwareCode()&HARDWARE_PREFIX_SEGA_MEGADRIVE ==HARDWARE_PREFIX_SEGA_MEGADRIVE)||
        (BurnDrvGetHardwareCode()&HARDWARE_PREFIX_NINTENDO_SNES ==HARDWARE_PREFIX_NINTENDO_SNES)) {
        //pcengine
        char *zipName;
        struct ZipEntry* List = NULL;
        int nListCount = 0;
        
        for (int d = 0; d < DIRS_MAX; d++) {
            zipName = (char*)malloc(MAX_PATH);            
			sprintf(zipName, "%s%s", szAppRomPaths[d], argv[1]);
            printf("check: %s\n",zipName);            
			if (ZipOpen(zipName) == 0) {	// Open the rom zip file				
                // Get the list of entries
                ZipGetList(&List, &nListCount);						
                
                // Check file for larger one
                int biggest_file_len=0;
                for (int i = 0; i < nListCount; i++) {
                    if (List[i].nLen>biggest_file_len) biggest_file_len=List[i].nLen;
                }
                
                rom_force_len=biggest_file_len;
                //free zip list
                if (List) {
                    for (int i = 0; i < nListCount; i++) {
                        if (List[i].szName) {
                            free(List[i].szName);
                            List[i].szName = NULL;
                        }
                    }
                    free(List);
                }               
                List = NULL;
                nListCount = 0;
                free(zipName);
                break;
            }
            free(zipName);
        }
    }
    //

	InputInit();
	init_emu(i);
    
    StopProgressBar();
    
	RunMessageLoop();
    
	InputExit();

	DrvExit();
	ConfigAppSave();
	BurnLibExit();
	//SDL_Quit();

	return 0;
}


/* const */ TCHAR* ANSIToTCHAR(const char* pszInString, TCHAR* pszOutString, int nOutSize)
{
#if defined (UNICODE)
	static TCHAR szStringBuffer[1024];

	TCHAR* pszBuffer = pszOutString ? pszOutString : szStringBuffer;
	int nBufferSize  = pszOutString ? nOutSize * 2 : sizeof(szStringBuffer);

	if (MultiByteToWideChar(CP_ACP, 0, pszInString, -1, pszBuffer, nBufferSize)) {
		return pszBuffer;
	}

	return NULL;
#else
	if (pszOutString) {
		_tcscpy(pszOutString, pszInString);
		return pszOutString;
	}

	return (TCHAR*)pszInString;
#endif
}


/* const */ char* TCHARToANSI(const TCHAR* pszInString, char* pszOutString, int nOutSize)
{
#if defined (UNICODE)
	static char szStringBuffer[1024];
	memset(szStringBuffer, 0, sizeof(szStringBuffer));

	char* pszBuffer = pszOutString ? pszOutString : szStringBuffer;
	int nBufferSize = pszOutString ? nOutSize * 2 : sizeof(szStringBuffer);

	if (WideCharToMultiByte(CP_ACP, 0, pszInString, -1, pszBuffer, nBufferSize, NULL, NULL)) {
		return pszBuffer;
	}

	return NULL;
#else
	if (pszOutString) {
		strcpy(pszOutString, pszInString);
		return pszOutString;
	}

	return (char*)pszInString;
#endif
}


bool AppProcessKeyboardInput()
{
	return true;
}

void Reinitialise()
{
    VidReInitialise();
}
