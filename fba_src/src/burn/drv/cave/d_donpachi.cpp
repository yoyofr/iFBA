// Donpachi
#include "cave.h"
#include "msm6295.h"

//HACK
#include "fbaconf.h"

#define CAVE_VBLANK_LINES 12

static UINT8 DrvJoy1[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
static UINT8 DrvJoy2[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
static UINT16 DrvInput[2] = {0x0000, 0x0000};

static UINT8 *Mem = NULL, *MemEnd = NULL;
static UINT8 *RamStart, *RamEnd;
static UINT8 *Rom01;
static UINT8 *Ram01;
static UINT8 *DefaultEEPROM = NULL;

static UINT8 DrvReset = 0;
static UINT8 bDrawScreen;
static bool bVBlank;

static INT32 nBankSize[2] = {0x200000, 0x300000};

static INT8 nVideoIRQ;
static INT8 nSoundIRQ;
static INT8 nUnknownIRQ;

static INT8 nIRQPending;

static struct BurnInputInfo donpachiInputList[] = {
	{"P1 Coin",		BIT_DIGITAL,	DrvJoy1 + 8,	"p1 coin"},
	{"P1 Start",	BIT_DIGITAL,	DrvJoy1 + 7,	"p1 start"},
    
	{"P1 Up",		BIT_DIGITAL,	DrvJoy1 + 0, 	"p1 up"},
	{"P1 Down",		BIT_DIGITAL,	DrvJoy1 + 1, 	"p1 down"},
	{"P1 Left",		BIT_DIGITAL,	DrvJoy1 + 2, 	"p1 left"},
	{"P1 Right",	BIT_DIGITAL,	DrvJoy1 + 3, 	"p1 right"},
	{"P1 Button 1",	BIT_DIGITAL,	DrvJoy1 + 4,	"p1 fire 1"},
	{"P1 Button 2",	BIT_DIGITAL,	DrvJoy1 + 5,	"p1 fire 2"},
	{"P1 Button 3",	BIT_DIGITAL,	DrvJoy1 + 6,	"p1 fire 3"},
    
	{"P2 Coin",		BIT_DIGITAL,	DrvJoy2 + 8,	"p2 coin"},
	{"P2 Start",	BIT_DIGITAL,	DrvJoy2 + 7,	"p2 start"},
    
	{"P2 Up",		BIT_DIGITAL,	DrvJoy2 + 0, 	"p2 up"},
	{"P2 Down",		BIT_DIGITAL,	DrvJoy2 + 1, 	"p2 down"},
	{"P2 Left",		BIT_DIGITAL,	DrvJoy2 + 2, 	"p2 left"},
	{"P2 Right",	BIT_DIGITAL,	DrvJoy2 + 3, 	"p2 right"},
	{"P2 Button 1",	BIT_DIGITAL,	DrvJoy2 + 4,	"p2 fire 1"},
	{"P2 Button 2",	BIT_DIGITAL,	DrvJoy2 + 5,	"p2 fire 2"},
	{"P2 Button 3",	BIT_DIGITAL,	DrvJoy2 + 6,	"p2 fire 3"},
    
	{"Reset",		BIT_DIGITAL,	&DrvReset,		"reset"},
	{"Diagnostics",	BIT_DIGITAL,	DrvJoy1 + 9,	"diag"},
	{"Service",		BIT_DIGITAL,	DrvJoy2 + 9,	"service"},
};

STDINPUTINFO(donpachi)

static void UpdateIRQStatus()
{
	nIRQPending = (nVideoIRQ == 0 || nSoundIRQ == 0 || nUnknownIRQ == 0);
	SekSetIRQLine(1, nIRQPending ? SEK_IRQSTATUS_ACK : SEK_IRQSTATUS_NONE);
}

UINT8 __fastcall donpachiReadByte(UINT32 sekAddress)
{
	switch (sekAddress) {
            
		case 0x900000:
		case 0x900001:
		case 0x900002:
		case 0x900003: {
			UINT8 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			return nRet;
		}
		case 0x900004:
		case 0x900005: {
			UINT8 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			nVideoIRQ = 1;
			UpdateIRQStatus();
			return nRet;
		}
		case 0x900006:
		case 0x900007: {
			UINT8 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			nUnknownIRQ = 1;
			UpdateIRQStatus();
			return nRet;
		}
            
		case 0xB00001:
			return MSM6295ReadStatus(0);
		case 0xB00011:
			return MSM6295ReadStatus(1);
            
		case 0xC00000:
			return (DrvInput[0] >> 8) ^ 0xFF;
		case 0xC00001:
			return (DrvInput[0] & 0xFF) ^ 0xFF;
		case 0xC00002:
			return ((DrvInput[1] >> 8) ^ 0xF7) | (EEPROMRead() << 3);
		case 0xC00003:
			return (DrvInput[1] & 0xFF) ^ 0xFF;
            
		default: {
            //			bprintf(PRINT_NORMAL, "Attempt to read byte value of location %x\n", sekAddress);
		}
	}
	return 0;
}

UINT16 __fastcall donpachiReadWord(UINT32 sekAddress)
{
	switch (sekAddress) {
		case 0x900000:
		case 0x900002: {
			UINT16 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			return nRet;
		}
            
		case 0x900004: {
			UINT16 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			nVideoIRQ = 1;
			UpdateIRQStatus();
			return nRet;
		}
		case 0x900006: {
			UINT16 nRet = (nUnknownIRQ << 1) | nVideoIRQ;
			nUnknownIRQ = 1;
			UpdateIRQStatus();
			return nRet;
		}
            
		case 0xB00000:
			return MSM6295ReadStatus(0);
		case 0xB00010:
			return MSM6295ReadStatus(1);
            
		case 0xC00000:
			return DrvInput[0] ^ 0xFFFF;
		case 0xC00002:
			return (DrvInput[1] ^ 0xF7FF) | (EEPROMRead() << 11);
            
		default: {
            // 			bprintf(PRINT_NORMAL, "Attempt to read word value of location %x\n", sekAddress);
		}
	}
	return 0;
}

void __fastcall donpachiWriteByte(UINT32 sekAddress, UINT8 byteValue)
{
    printf("w8.%08X:%02X\n",sekAddress,byteValue);
	switch (sekAddress) {
            
		case 0xB00000:
		case 0xB00001:
		case 0xB00002:
		case 0xB00003:
			MSM6295Command(0, byteValue);
			break;
		case 0xB00010:
		case 0xB00011:
		case 0xB00012:
		case 0xB00013:
			MSM6295Command(1, byteValue);
			break;
            
		case 0xB00020:
		case 0xB00021:
		case 0xB00022:
		case 0xB00023:
		case 0xB00024:
		case 0xB00025:
		case 0xB00026:
		case 0xB00027:
		case 0xB00028:
		case 0xB00029:
		case 0xB0002A:
		case 0xB0002B:
		case 0xB0002C:
		case 0xB0002D:
		case 0xB0002E:
		case 0xB0002F: {
			INT32 nBank = (sekAddress >> 1) & 3;
			INT32 nChip = (sekAddress >> 3) & 1;
			INT32 nAddress = byteValue << 16;
			while (nAddress > nBankSize[nChip]) {
				nAddress -= nBankSize[nChip];
			}
            
			if (nChip == 1) {
				MSM6295SampleData[1][nBank] = MSM6295ROM + nAddress;
				MSM6295SampleInfo[1][nBank] = MSM6295ROM + nAddress + (nBank << 8);
			} else {
				MSM6295SampleData[0][nBank] = MSM6295ROM + 0x100000 + nAddress;
				if (nBank == 0) {
					MSM6295SampleInfo[0][0] = MSM6295ROM + 0x100000 + nAddress + 0x0000;
					MSM6295SampleInfo[0][1] = MSM6295ROM + 0x100000 + nAddress + 0x0100;
					MSM6295SampleInfo[0][2] = MSM6295ROM + 0x100000 + nAddress + 0x0200;
					MSM6295SampleInfo[0][3] = MSM6295ROM + 0x100000 + nAddress + 0x0300;
				}
			}
			break;
		}
            
		case 0xD00000:
			EEPROMWrite(byteValue & 0x04, byteValue & 0x02, byteValue & 0x08);
			break;
            
		default: {
            //			bprintf(PRINT_NORMAL, "Attempt to write byte value %x to location %x\n", byteValue, sekAddress);
		}
	}
}

void __fastcall donpachiWriteWord(UINT32 sekAddress, UINT16 wordValue)
{
    //    if (sekAddress==0x00600000) printf("w16.%08X:%04X\n",sekAddress,wordValue);
	switch (sekAddress) {
		case 0x600000:
			CaveTileReg[1][0] = wordValue;
			break;
		case 0x600002:
			CaveTileReg[1][1] = wordValue;
			break;
		case 0x600004:
			CaveTileReg[1][2] = wordValue;
			break;
		case 0x700000:
			CaveTileReg[0][0] = wordValue;
			break;
		case 0x700002:
			CaveTileReg[0][1] = wordValue;
			break;
		case 0x700004:
			CaveTileReg[0][2] = wordValue;
			break;
		case 0x800000:
			CaveTileReg[2][0] = wordValue;
			break;
		case 0x800002:
			CaveTileReg[2][1] = wordValue;
			break;
		case 0x800004:
			CaveTileReg[2][2] = wordValue;
			break;
		case 0x900000:
			nCaveXOffset = wordValue;
			return;
		case 0x900002:
			nCaveYOffset = wordValue;
			return;
		case 0x900008:
			CaveSpriteBuffer();
			nCaveSpriteBank = wordValue;
			return;
		case 0xB00000:
		case 0xB00002:
			MSM6295Command(0, wordValue);
			break;
		case 0xB00010:
		case 0xB00012:
			MSM6295Command(1, wordValue);
			break;
		case 0xB00020:
		case 0xB00021:
		case 0xB00022:
		case 0xB00023:
		case 0xB00024:
		case 0xB00025:
		case 0xB00026:
		case 0xB00027:
		case 0xB00028:
		case 0xB00029:
		case 0xB0002A:
		case 0xB0002B:
		case 0xB0002C:
		case 0xB0002D:
		case 0xB0002E:
		case 0xB0002F: {
			INT32 nBank = (sekAddress >> 1) & 3;
			INT32 nChip = (sekAddress >> 3) & 1;
			INT32 nAddress = wordValue << 16;
			while (nAddress > nBankSize[nChip]) {
				nAddress -= nBankSize[nChip];
			}
            
			if (nChip == 1) {
				MSM6295SampleData[1][nBank] = MSM6295ROM + nAddress;
				MSM6295SampleInfo[1][nBank] = MSM6295ROM + nAddress + (nBank << 8);
			} else {
				MSM6295SampleData[0][nBank] = MSM6295ROM + 0x100000 + nAddress;
				if (nBank == 0) {
					MSM6295SampleInfo[0][0] = MSM6295ROM + 0x100000 + nAddress + 0x0000;
					MSM6295SampleInfo[0][1] = MSM6295ROM + 0x100000 + nAddress + 0x0100;
					MSM6295SampleInfo[0][2] = MSM6295ROM + 0x100000 + nAddress + 0x0200;
					MSM6295SampleInfo[0][3] = MSM6295ROM + 0x100000 + nAddress + 0x0300;
				}
			}
			break;
		}
            
		case 0xD00000:
			wordValue >>= 8;
			EEPROMWrite(wordValue & 0x04, wordValue & 0x02, wordValue & 0x08);
			break;
            
		default: {
            //			bprintf(PRINT_NORMAL, "Attempt to write word value %x to location %x\n", wordValue, sekAddress);
            
		}
	}
}

static INT32 DrvExit()
{
	EEPROMExit();
	
	MSM6295Exit(0);
	MSM6295Exit(1);
    
	CaveTileExit();
	CaveSpriteExit();
    CavePalExit();
    
	SekExit();				// Deallocate 68000s
    
	BurnFree(Mem);
    
	return 0;
}

static INT32 DrvDoReset()
{
	SekOpen(0);
	SekReset();
	SekClose();
    
	EEPROMReset();
    
	nVideoIRQ = 1;
	nSoundIRQ = 1;
	nUnknownIRQ = 1;
    
	nIRQPending = 0;
    
	MSM6295Reset(0);
	MSM6295Reset(1);
    
	return 0;
}

static INT32 DrvDraw()
{
	CavePalUpdate4Bit(0, 128);				// Update the palette
	CaveClearScreen(CavePalette[0x7F00]);
    
	if (bDrawScreen) {
        //		CaveGetBitmap();
        
		CaveTileRender(1);					// Render tiles
	}
    
	return 0;
}

inline static INT32 CheckSleep(INT32)
{
	return 0;
}

static INT32 DrvFrame()
{
	INT32 nCyclesVBlank;
	INT32 nInterleave = 8;
    
	INT32 nCyclesTotal[2];
	INT32 nCyclesDone[2];
    
	INT32 nCyclesSegment;
    
	if (DrvReset) {														// Reset machine
        //HACK
        wait_control=60;
        glob_framecpt=0;
        glob_replay_last_dx16=glob_replay_last_dy16=0;
        glob_replay_last_fingerOn=0;
        //
		DrvDoReset();
	}
    
    if (glob_replay_mode==REPLAY_PLAYBACK_MODE) { //REPLAY
        unsigned int next_frame_event;
        next_frame_event=(unsigned int)(glob_replay_data_stream[glob_replay_data_index])|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+1])<<8)
        |((unsigned int)(glob_replay_data_stream[glob_replay_data_index+2])<<16)|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+3])<<24);
        
        
        if (glob_framecpt==next_frame_event) {
            glob_replay_data_index+=4;
            glob_replay_flag=glob_replay_data_stream[glob_replay_data_index++];
            if (glob_replay_flag&REPLAY_FLAG_TOUCHONOFF) {
                glob_replay_last_fingerOn^=1;
            }
            if (glob_replay_flag&REPLAY_FLAG_POSX) {
                glob_replay_last_dx16=(unsigned int)(glob_replay_data_stream[glob_replay_data_index])|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+1])<<8);
                glob_replay_data_index+=2;
            }
            if (glob_replay_flag&REPLAY_FLAG_POSY) {
                glob_replay_last_dy16=(unsigned int)(glob_replay_data_stream[glob_replay_data_index])|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+1])<<8);
                glob_replay_data_index+=2;
            }
            if (glob_replay_flag&REPLAY_FLAG_IN0) {
                last_DrvInput[0]=(unsigned int)(glob_replay_data_stream[glob_replay_data_index])|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+1])<<8);
                glob_replay_data_index+=2;
            }
            if (glob_replay_flag&REPLAY_FLAG_IN1) {
                last_DrvInput[1]=(unsigned int)(glob_replay_data_stream[glob_replay_data_index])|((unsigned int)(glob_replay_data_stream[glob_replay_data_index+1])<<8);
                glob_replay_data_index+=2;
            }
        }
        DrvInput[0]=last_DrvInput[0];
        DrvInput[1]=last_DrvInput[1];
        
    } else {
        
        // Compile digital inputs
        DrvInput[0] = 0x0000;  												// Player 1
        DrvInput[1] = 0x0000;  												// Player 2
        for (INT32 i = 0; i < 10; i++) {
            DrvInput[0] |= (DrvJoy1[i] & 1) << i;
            DrvInput[1] |= (DrvJoy2[i] & 1) << i;
        }
        //HACK
        if (glob_ffingeron) {
            DrvInput[0]&=~((1<<4)); //clear fire 1
            if (glob_mov_y>0) DrvInput[0]|=1;
            if (glob_mov_y<0) DrvInput[0]|=2;
            if (glob_mov_x<0) DrvInput[0]|=4;
            if (glob_mov_x>0) DrvInput[0]|=8;
            if (glob_shooton) {
                switch (glob_shootmode) {
                    case 0: //shoot
                        if ((glob_autofirecpt%10)==0) DrvInput[0]|=1<<4;
                        glob_autofirecpt++;
                        break;
                    case 1: //laser
                        DrvInput[0]|=1<<4;
                        break;
                }
            }
        }
        //
        CaveClearOpposites(&DrvInput[0]);
        CaveClearOpposites(&DrvInput[1]);
        
        //HACK
        //replay data - drvinputs
        
        if (glob_replay_mode==REPLAY_RECORD_MODE) {//SAVE REPLAY
            glob_replay_flag=0;
            if (glob_framecpt==0) {//first frame
                //STORE FRAME_INDEX (0)
                glob_replay_data_stream[glob_replay_data_index++]=glob_framecpt&0xFF; //frame index
                glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>8)&0xFF; //frame index
                glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>16)&0xFF; //frame index
                glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>24)&0xFF; //frame index
                //STORE FLAG (00001100b)
                glob_replay_data_stream[glob_replay_data_index++]=REPLAY_FLAG_IN0|REPLAY_FLAG_IN1;
                //STORE INPUT0 & INPUT1
                glob_replay_data_stream[glob_replay_data_index++]=DrvInput[0]&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(DrvInput[0]>>8)&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=DrvInput[1]&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(DrvInput[1]>>8)&0xFF;
                
                last_DrvInput[0]=DrvInput[0];
                last_DrvInput[1]=DrvInput[1];
            } else {
                
                if (last_DrvInput[0]!=DrvInput[0]) {
                    glob_replay_flag|=REPLAY_FLAG_IN0;
                    last_DrvInput[0]=DrvInput[0];
                }
                if (last_DrvInput[1]!=DrvInput[1]) {
                    glob_replay_flag|=REPLAY_FLAG_IN1;
                    last_DrvInput[1]=DrvInput[1];
                }
            }
            
        }
        
    }
    
    SekNewFrame();
    
    nCyclesTotal[0] = (INT32)((INT64)16000000 * nBurnCPUSpeedAdjust / (0x0100 * CAVE_REFRESHRATE));
    nCyclesDone[0] = 0;
    
    nCyclesVBlank = nCyclesTotal[0] - (INT32)((nCyclesTotal[0] * CAVE_VBLANK_LINES) / 271.5);
    bVBlank = false;
    
    INT32 nSoundBufferPos = 0;
    
    SekOpen(0);
    
    //HACK for 'follow finger' touchpad mode
    if (glob_ffingeron) {
        if ( wait_control==0 ) PatchMemory68KFFinger();
        else wait_control--;
    }
    //
    
    //8 bits => 0/1: touch off/on switch
    //          1/2: posX
    //          2/4: posY
    //          3/8: input0
    //          4/16: input1
    //          5/32: ...
    //          6/64:
    //          7/128:
    
    if (glob_replay_mode==REPLAY_RECORD_MODE) {
        if (glob_replay_flag) {
            //STORE FRAME_INDEX
            glob_replay_data_stream[glob_replay_data_index++]=glob_framecpt&0xFF; //frame index
            glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>8)&0xFF; //frame index
            glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>16)&0xFF; //frame index
            glob_replay_data_stream[glob_replay_data_index++]=(glob_framecpt>>24)&0xFF; //frame index
            //STORE FLAG
            glob_replay_data_stream[glob_replay_data_index++]=glob_replay_flag;
            
            if (glob_replay_flag&REPLAY_FLAG_POSX) { //MEMX HAS CHANGED
                glob_replay_data_stream[glob_replay_data_index++]=glob_replay_last_dx16&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(glob_replay_last_dx16>>8)&0xFF;
            }
            if (glob_replay_flag&REPLAY_FLAG_POSY) { //MEMY HAS CHANGED
                glob_replay_data_stream[glob_replay_data_index++]=glob_replay_last_dy16&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(glob_replay_last_dy16>>8)&0xFF;
            }
            if (glob_replay_flag&REPLAY_FLAG_IN0) { //INPUT0 HAS CHANGED
                glob_replay_data_stream[glob_replay_data_index++]=last_DrvInput[0]&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(last_DrvInput[0]>>8)&0xFF;
            }
            if (glob_replay_flag&REPLAY_FLAG_IN1) { //INPUT1 HAS CHANGED
                glob_replay_data_stream[glob_replay_data_index++]=last_DrvInput[1]&0xFF;
                glob_replay_data_stream[glob_replay_data_index++]=(last_DrvInput[1]>>8)&0xFF;
            }
            
        }
    }
    
    
    for (INT32 i = 1; i <= nInterleave; i++) {
        INT32 nCurrentCPU = 0;
        INT32 nNext = i * nCyclesTotal[nCurrentCPU] / nInterleave;
        
        // Run 68000
        
        // See if we need to trigger the VBlank interrupt
        if (!bVBlank && nNext > nCyclesVBlank) {
            if (nCyclesDone[nCurrentCPU] < nCyclesVBlank) {
                nCyclesSegment = nCyclesVBlank - nCyclesDone[nCurrentCPU];
                if (!CheckSleep(nCurrentCPU)) {							// See if this CPU is busywaiting
                    nCyclesDone[nCurrentCPU] += SekRun(nCyclesSegment);
                    
                } else {
                    nCyclesDone[nCurrentCPU] += SekIdle(nCyclesSegment);
                }
            }
            
            if (pBurnDraw != NULL) {
                DrvDraw();												// Draw screen if needed
            }
            
            bVBlank = true;
            nVideoIRQ = 0;
            UpdateIRQStatus();
        }
        
        nCyclesSegment = nNext - nCyclesDone[nCurrentCPU];
        if (!CheckSleep(nCurrentCPU)) {									// See if this CPU is busywaiting
            nCyclesDone[nCurrentCPU] += SekRun(nCyclesSegment);
        } else {
            nCyclesDone[nCurrentCPU] += SekIdle(nCyclesSegment);
        }
    }
    
    // Make sure the buffer is entirely filled.
    {
        if (pBurnSoundOut) {
            INT32 nSegmentLength = nBurnSoundLen - nSoundBufferPos;
            INT16* pSoundBuf = pBurnSoundOut + (nSoundBufferPos << 1);
            if (nSegmentLength) {
                MSM6295Render(0, pSoundBuf, nSegmentLength);
                MSM6295Render(1, pSoundBuf, nSegmentLength);
            }
        }
    }
    
    SekClose();
    
    glob_framecpt++;
    if ((glob_replay_mode==REPLAY_PLAYBACK_MODE)&&(glob_replay_data_index>=glob_replay_data_index_max)) {
        //should end replay here
        nShouldExit=1;
    }
    
    
    return 0;
}

// This routine is called first to determine how much memory is needed (MemEnd-(UINT8 *)0),
// and then afterwards to set up all the pointers
static INT32 MemIndex()
{
	UINT8* Next; Next = Mem;
	Rom01			= Next; Next += 0x080000;		// 68K program
	CaveSpriteROM	= Next; Next += 0x800000;
	CaveTileROM[0]	= Next; Next += 0x200000;		// Tile layer 0
	CaveTileROM[1]	= Next; Next += 0x200000;		// Tile layer 1
	CaveTileROM[2]	= Next; Next += 0x080000;		// Tile layer 2
	MSM6295ROM		= Next; Next += 0x300000;
	DefaultEEPROM	= Next; Next += 0x000080;
	RamStart		= Next;
	Ram01			= Next; Next += 0x010000;		// CPU #0 work RAM
	CaveTileRAM[0]	= Next; Next += 0x008000;
	CaveTileRAM[1]	= Next; Next += 0x008000;
	CaveTileRAM[2]	= Next; Next += 0x008000;
	CaveSpriteRAM	= Next; Next += 0x010000;
	CavePalSrc		= Next; Next += 0x001000;		// palette
	RamEnd			= Next;
	MemEnd			= Next;
    
	return 0;
}

static void NibbleSwap2(UINT8* pData, INT32 nLen)
{
	UINT8* pOrg = pData + nLen - 1;
	UINT8* pDest = pData + ((nLen - 1) << 1);
    
	for (INT32 i = 0; i < nLen; i++, pOrg--, pDest -= 2) {
		pDest[1] = *pOrg & 15;
		pDest[0] = *pOrg >> 4;
	}
    
	return;
}

static INT32 LoadRoms()
{
	// Load 68000 ROM
	BurnLoadRom(Rom01, 0, 1);
    
	BurnLoadRom(CaveSpriteROM + 0x000000, 1, 1);
	BurnLoadRom(CaveSpriteROM + 0x200000, 2, 1);
	BurnByteswap(CaveSpriteROM, 0x400000);
	NibbleSwap2(CaveSpriteROM, 0x400000);
    
	BurnLoadRom(CaveTileROM[0], 3, 1);
	NibbleSwap2(CaveTileROM[0], 0x100000);
	BurnLoadRom(CaveTileROM[1], 4, 1);
	NibbleSwap2(CaveTileROM[1], 0x100000);
	BurnLoadRom(CaveTileROM[2], 5, 1);
	NibbleSwap2(CaveTileROM[2], 0x040000);
    
	// Load MSM6295 ADPCM data
	BurnLoadRom(MSM6295ROM, 6, 1);
	BurnLoadRom(MSM6295ROM + 0x100000, 7, 1);
	
	BurnLoadRom(DefaultEEPROM, 8, 1);
    
	return 0;
}

// Scan ram
static INT32 DrvScan(INT32 nAction, INT32 *pnMin)
{
	struct BurnArea ba;
    
	if (pnMin) {						// Return minimum compatible version
		*pnMin = 0x020902;
	}
    
	EEPROMScan(nAction, pnMin);			// Scan EEPROM
    
	if (nAction & ACB_VOLATILE) {		// Scan volatile ram
        
		memset(&ba, 0, sizeof(ba));
    	ba.Data		= RamStart;
		ba.nLen		= RamEnd - RamStart;
		ba.szName	= "RAM";
		BurnAcb(&ba);
        
		SekScan(nAction);				// scan 68000 states
        
		MSM6295Scan(0, nAction);
		MSM6295Scan(1, nAction);
        
		SCAN_VAR(nVideoIRQ);
		SCAN_VAR(nSoundIRQ);
		SCAN_VAR(nUnknownIRQ);
		SCAN_VAR(bVBlank);
        
		CaveScanGraphics();
        
		SCAN_VAR(DrvInput);
	}
    
	if (nAction & ACB_WRITE) {
		CaveRecalcPalette = 1;
	}
    
	return 0;
}

static INT32 DrvInit()
{
	INT32 nLen;
    
	BurnSetRefreshRate(CAVE_REFRESHRATE);
    
	// Find out how much memory is needed
	Mem = NULL;
	MemIndex();
	nLen = MemEnd - (UINT8 *)0;
	if ((Mem = (UINT8 *)BurnMalloc(nLen)) == NULL) {
		return 1;
	}
	memset(Mem, 0, nLen);										// blank all memory
	MemIndex();													// Index the allocated memory
    
	// Load the roms into memory
	if (LoadRoms()) {
		return 1;
	}
	
	EEPROMInit(&eeprom_interface_93C46);
	if (!EEPROMAvailable()) EEPROMFill(DefaultEEPROM,0, 0x80);
    
	{
		SekInit(0, 0x68000);													// Allocate 68000
	    SekOpen(0);
        
		// Map 68000 memory:
		SekMapMemory(Rom01,						0x000000, 0x07FFFF, SM_ROM);	// CPU 0 ROM
		SekMapMemory(Ram01,						0x100000, 0x10FFFF, SM_RAM);
		SekMapMemory(CaveTileRAM[1],			0x200000, 0x207FFF, SM_RAM);
		SekMapMemory(CaveTileRAM[0],			0x300000, 0x307FFF, SM_RAM);
		SekMapMemory(CaveTileRAM[2] + 0x4000,	0x400000, 0x403FFF, SM_RAM);
		SekMapMemory(CaveTileRAM[2] + 0x4000,	0x404000, 0x407FFF, SM_RAM);
		SekMapMemory(CaveSpriteRAM,				0x500000, 0x50FFFF, SM_RAM);
		SekMapMemory(CavePalSrc,				0xA08000, 0xA08FFF, SM_RAM);	// Palette RAM
        
		SekSetReadWordHandler(0, donpachiReadWord);
		SekSetReadByteHandler(0, donpachiReadByte);
		SekSetWriteWordHandler(0, donpachiWriteWord);
		SekSetWriteByteHandler(0, donpachiWriteByte);
        
		SekClose();
	}
    
	CavePalInit(0x8000);
	CaveTileInit();
	CaveSpriteInit(0, 0x0800000);
	CaveTileInitLayer(0, 0x200000, 8, 0x4000);
	CaveTileInitLayer(1, 0x200000, 8, 0x4000);
	CaveTileInitLayer(2, 0x080000, 8, 0x4000);
    
	MSM6295Init(0, 8000, 0);
	MSM6295Init(1, 16000, 0);
	MSM6295SetRoute(0, 1.60, BURN_SND_ROUTE_BOTH);
	MSM6295SetRoute(1, 1.00, BURN_SND_ROUTE_BOTH);
    
	MSM6295SampleData[0][0] = MSM6295ROM + 0x100000;
	MSM6295SampleInfo[0][0] = MSM6295ROM + 0x100000 + 0x0000;
	MSM6295SampleData[0][1] = MSM6295ROM + 0x100000;
	MSM6295SampleInfo[0][1] = MSM6295ROM + 0x100000 + 0x0100;
	MSM6295SampleData[0][2] = MSM6295ROM + 0x100000;
	MSM6295SampleInfo[0][2] = MSM6295ROM + 0x100000 + 0x0200;
	MSM6295SampleData[0][3] = MSM6295ROM + 0x100000;
	MSM6295SampleInfo[0][3] = MSM6295ROM + 0x100000 + 0x0300;
    
	bDrawScreen = true;
    
	DrvDoReset(); // Reset machine
    
	return 0;
}

// Rom information
static struct BurnRomInfo donpachiRomDesc[] = {
	{ "prgu.u29",     0x080000, 0x89C36802, BRF_ESS | BRF_PRG }, //  0 CPU #0 code
    
	{ "atdp.u44",     0x200000, 0x7189E953, BRF_GRA },			 //  1 Sprite data
	{ "atdp.u45",     0x200000, 0x6984173F, BRF_GRA },			 //  2
    
	{ "atdp.u54",     0x100000, 0x6BDA6B66, BRF_GRA },			 //  3 Layer 0 Tile data
	{ "atdp.u57",     0x100000, 0x0A0E72B9, BRF_GRA },			 //  4 Layer 1 Tile data
	{ "text.u58",     0x040000, 0x5DBA06E7, BRF_GRA },			 //  5 Layer 2 Tile data
    
	{ "atdp.u32",     0x100000, 0x0D89FCCA, BRF_SND },			 //  6 MSM6295 #1 ADPCM data
	{ "atdp.u33",     0x200000, 0xD749DE00, BRF_SND },			 //  7 MSM6295 #0/1 ADPCM data
	
	{ "eeprom-donpachi.u10", 0x0080, 0x315fb546, BRF_ESS | BRF_PRG },
	
	{ "peel18cv8p-15.u18", 0x0155, 0x3f4787e9, BRF_OPT },
};


STD_ROM_PICK(donpachi)
STD_ROM_FN(donpachi)

static struct BurnRomInfo donpachijRomDesc[] = {
	{ "prg.u29",      0x080000, 0x6BE14AF6, BRF_ESS | BRF_PRG }, //  0 CPU #0 code
    
	{ "atdp.u44",     0x200000, 0x7189E953, BRF_GRA },			 //  1 Sprite data
	{ "atdp.u45",     0x200000, 0x6984173F, BRF_GRA },			 //  2
    
	{ "atdp.u54",     0x100000, 0x6BDA6B66, BRF_GRA },			 //  3 Layer 0 Tile data
	{ "atdp.u57",     0x100000, 0x0A0E72B9, BRF_GRA },			 //  4 Layer 1 Tile data
	{ "u58.bin",      0x040000, 0x285379FF, BRF_GRA },			 //  5 Layer 2 Tile data
    
	{ "atdp.u32",     0x100000, 0x0D89FCCA, BRF_SND },			 //  6 MSM6295 #1 ADPCM data
	{ "atdp.u33",     0x200000, 0xD749DE00, BRF_SND },			 //  7 MSM6295 #0/1 ADPCM data
	
	{ "eeprom-donpachi.bin", 0x0080, 0x315fb546, BRF_ESS | BRF_PRG },
	
	{ "peel18cv8p-15.u18", 0x0155, 0x3f4787e9, BRF_OPT },
};


STD_ROM_PICK(donpachij)
STD_ROM_FN(donpachij)

static struct BurnRomInfo donpachikrRomDesc[] = {
	{ "prgk.u26",     0x080000, 0xBBAF4C8B, BRF_ESS | BRF_PRG }, //  0 CPU #0 code
    
	{ "atdp.u44",     0x200000, 0x7189E953, BRF_GRA },			 //  1 Sprite data
	{ "atdp.u45",     0x200000, 0x6984173F, BRF_GRA },			 //  2
    
	{ "atdp.u54",     0x100000, 0x6BDA6B66, BRF_GRA },			 //  3 Layer 0 Tile data
	{ "atdp.u57",     0x100000, 0x0A0E72B9, BRF_GRA },			 //  4 Layer 1 Tile data
	{ "u58.bin",      0x040000, 0x285379FF, BRF_GRA },			 //  5 Layer 2 Tile data
    
	{ "atdp.u32",     0x100000, 0x0D89FCCA, BRF_SND },			 //  6 MSM6295 #1 ADPCM data
	{ "atdp.u33",     0x200000, 0xD749DE00, BRF_SND },			 //  7 MSM6295 #0/1 ADPCM data
	
	{ "eeprom-donpachi.bin", 0x0080, 0x315fb546, BRF_ESS | BRF_PRG },
	
	{ "peel18cv8p-15.u18", 0x0155, 0x3f4787e9, BRF_OPT },
};


STD_ROM_PICK(donpachikr)
STD_ROM_FN(donpachikr)

static struct BurnRomInfo donpachihkRomDesc[] = {
	{ "37.u29",       0x080000, 0x71f39f30, BRF_ESS | BRF_PRG }, //  0 CPU #0 code
    
	{ "atdp.u44",     0x200000, 0x7189E953, BRF_GRA },			 //  1 Sprite data
	{ "atdp.u45",     0x200000, 0x6984173F, BRF_GRA },			 //  2
    
	{ "atdp.u54",     0x100000, 0x6BDA6B66, BRF_GRA },			 //  3 Layer 0 Tile data
	{ "atdp.u57",     0x100000, 0x0A0E72B9, BRF_GRA },			 //  4 Layer 1 Tile data
	{ "u58.bin",      0x040000, 0x285379ff, BRF_GRA },			 //  5 Layer 2 Tile data
    
	{ "atdp.u32",     0x100000, 0x0D89FCCA, BRF_SND },			 //  6 MSM6295 #1 ADPCM data
	{ "atdp.u33",     0x200000, 0xD749DE00, BRF_SND },			 //  7 MSM6295 #0/1 ADPCM data
	
	{ "eeprom-donpachi.bin", 0x0080, 0x315fb546, BRF_ESS | BRF_PRG },
	
	{ "peel18cv8p-15.u18", 0x0155, 0x3f4787e9, BRF_OPT },
};


STD_ROM_PICK(donpachihk)
STD_ROM_FN(donpachihk)


struct BurnDriver BurnDrvDonpachi = {
	"donpachi", NULL, NULL, NULL, "1995",
	"DonPachi (USA, ver. 1.12, 95/05/2x)\0", NULL, "Atlus / Cave", "Cave",
	L"\u9996\u9818\u8702 DonPachi (USA, ver. 1.12, 95/05/2x)\0", NULL, NULL, NULL,
	BDF_GAME_WORKING | BDF_ORIENTATION_VERTICAL | BDF_16BIT_ONLY, 2, HARDWARE_CAVE_68K_ONLY | HARDWARE_CAVE_M6295, GBF_VERSHOOT, 0,
	NULL, donpachiRomInfo, donpachiRomName, NULL, NULL, donpachiInputInfo, NULL,
	DrvInit, DrvExit, DrvFrame, DrvDraw, DrvScan,
	&CaveRecalcPalette, 0x8000, 240, 320, 3, 4
};

struct BurnDriver BurnDrvDonpachij = {
	"donpachij", "donpachi", NULL, NULL, "1995",
	"DonPachi (Japan, ver. 1.01, 95/05/11)\0", NULL, "Atlus / Cave", "Cave",
	L"\u9996\u9818\u8702 DonPachi (Japan, ver. 1.01, 95/05/11)\0", NULL, NULL, NULL,
	BDF_GAME_WORKING | BDF_CLONE | BDF_ORIENTATION_VERTICAL | BDF_16BIT_ONLY, 2, HARDWARE_CAVE_68K_ONLY | HARDWARE_CAVE_M6295, GBF_VERSHOOT, 0,
	NULL, donpachijRomInfo, donpachijRomName, NULL, NULL, donpachiInputInfo, NULL,
	DrvInit, DrvExit, DrvFrame, DrvDraw, DrvScan,
	&CaveRecalcPalette, 0x8000, 240, 320, 3, 4
};

struct BurnDriver BurnDrvDonpachikr = {
	"donpachikr", "donpachi", NULL, NULL, "1995",
	"DonPachi (Korea, ver. 1.12, 95/05/2x)\0", NULL, "Atlus / Cave", "Cave",
	L"\u9996\u9818\u8702 DonPachi (Korea, ver. 1.12, 95/05/2x)\0", NULL, NULL, NULL,
	BDF_GAME_WORKING | BDF_CLONE | BDF_ORIENTATION_VERTICAL | BDF_16BIT_ONLY, 2, HARDWARE_CAVE_68K_ONLY | HARDWARE_CAVE_M6295, GBF_VERSHOOT, 0,
	NULL, donpachikrRomInfo, donpachikrRomName, NULL, NULL, donpachiInputInfo, NULL,
	DrvInit, DrvExit, DrvFrame, DrvDraw, DrvScan,
	&CaveRecalcPalette, 0x8000, 240, 320, 3, 4
};

struct BurnDriver BurnDrvDonpachihk = {
	"donpachihk", "donpachi", NULL, NULL, "1995",
	"DonPachi (Hong Kong, ver. 1.10, 95/05/17)\0", NULL, "Atlus / Cave", "Cave",
	L"\u9996\u9818\u8702 DonPachi (Hong Kong, ver. 1.10, 95/05/17)\0", NULL, NULL, NULL,
	BDF_GAME_WORKING | BDF_CLONE | BDF_ORIENTATION_VERTICAL | BDF_16BIT_ONLY, 2, HARDWARE_CAVE_68K_ONLY | HARDWARE_CAVE_M6295, GBF_VERSHOOT, 0,
	NULL, donpachihkRomInfo, donpachihkRomName, NULL, NULL, donpachiInputInfo, NULL,
	DrvInit, DrvExit, DrvFrame, DrvDraw, DrvScan,
	&CaveRecalcPalette, 0x8000, 240, 320, 3, 4
};
