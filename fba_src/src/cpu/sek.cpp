// 680x0 (Sixty Eight K) Interface
#include "burnint.h"
#include "sekdebug.h"

struct Cyclone PicoCpu[SEK_MAX];
static bool bCycloneInited = false;

INT32 nSekM68KContextSize[SEK_MAX];
INT8* SekM68KContext[SEK_MAX];

INT32 nSekCount = -1;							// Number of allocated 68000s
struct SekExt *SekExt[SEK_MAX] = { NULL, }, *pSekExt = NULL;

INT32 nSekActive = -1;								// The cpu which is currently being emulated
INT32 nSekCyclesTotal, nSekCyclesScanline, nSekCyclesSegment, nSekCyclesDone, nSekCyclesToDo;

INT32 nSekCPUType[SEK_MAX], nSekCycles[SEK_MAX], nSekIRQPending[SEK_MAX];


// ----------------------------------------------------------------------------
// Default memory access handlers

UINT8 __fastcall DefReadByte(UINT32) { return 0; }
void __fastcall DefWriteByte(UINT32, UINT8) { }

#define DEFWORDHANDLERS(i)																				\
UINT16 __fastcall DefReadWord##i(UINT32 a) { SEK_DEF_READ_WORD(i, a) }				\
void __fastcall DefWriteWord##i(UINT32 a, UINT16 d) { SEK_DEF_WRITE_WORD(i, a ,d) }
#define DEFLONGHANDLERS(i)																				\
UINT32 __fastcall DefReadLong##i(UINT32 a) { SEK_DEF_READ_LONG(i, a) }					\
void __fastcall DefWriteLong##i(UINT32 a, UINT32 d) { SEK_DEF_WRITE_LONG(i, a , d) }

DEFWORDHANDLERS(0)
DEFLONGHANDLERS(0)

#if SEK_MAXHANDLER >= 2
DEFWORDHANDLERS(1)
DEFLONGHANDLERS(1)
#endif

#if SEK_MAXHANDLER >= 3
DEFWORDHANDLERS(2)
DEFLONGHANDLERS(2)
#endif

#if SEK_MAXHANDLER >= 4
DEFWORDHANDLERS(3)
DEFLONGHANDLERS(3)
#endif

#if SEK_MAXHANDLER >= 5
DEFWORDHANDLERS(4)
DEFLONGHANDLERS(4)
#endif

#if SEK_MAXHANDLER >= 6
DEFWORDHANDLERS(5)
DEFLONGHANDLERS(5)
#endif

#if SEK_MAXHANDLER >= 7
DEFWORDHANDLERS(6)
DEFLONGHANDLERS(6)
#endif

#if SEK_MAXHANDLER >= 8
DEFWORDHANDLERS(7)
DEFLONGHANDLERS(7)
#endif

#if SEK_MAXHANDLER >= 9
DEFWORDHANDLERS(8)
DEFLONGHANDLERS(8)
#endif

#if SEK_MAXHANDLER >= 10
DEFWORDHANDLERS(9)
DEFLONGHANDLERS(9)
#endif

// ----------------------------------------------------------------------------
// Memory access functions

// Mapped Memory lookup (               for read)
#define FIND_R(x) pSekExt->MemMap[ x >> SEK_SHIFT]
// Mapped Memory lookup (+ SEK_WADD     for write)
#define FIND_W(x) pSekExt->MemMap[(x >> SEK_SHIFT) + SEK_WADD]
// Mapped Memory lookup (+ SEK_WADD * 2 for fetch)
#define FIND_F(x) pSekExt->MemMap[(x >> SEK_SHIFT) + SEK_WADD * 2]

// Normal memory access functions
inline static UINT8 ReadByte(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("read8 0x%08X\n"), a);
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		a ^= 1;
		return pr[a & SEK_PAGEM];
	}
	return pSekExt->ReadByte[(uintptr_t)pr](a);
}

inline static UINT8 FetchByte(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("fetch8 0x%08X\n"), a);
    
	pr = FIND_F(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		a ^= 1;
		return pr[a & SEK_PAGEM];
	}
	return pSekExt->ReadByte[(uintptr_t)pr](a);
}

inline static void WriteByte(UINT32 a, UINT8 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("write8 0x%08X\n"), a);
    
	pr = FIND_W(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		a ^= 1;
		pr[a & SEK_PAGEM] = (UINT8)d;
		return;
	}
	pSekExt->WriteByte[(uintptr_t)pr](a, d);
}

inline static void WriteByteROM(UINT32 a, UINT8 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		a ^= 1;
		pr[a & SEK_PAGEM] = (UINT8)d;
		return;
	}
	pSekExt->WriteByte[(uintptr_t)pr](a, d);
}

inline static UINT16 ReadWord(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("read16 0x%08X\n"), a);
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		return BURN_ENDIAN_SWAP_INT16(*((UINT16*)(pr + (a & SEK_PAGEM))));
	}
	return pSekExt->ReadWord[(uintptr_t)pr](a);
}

inline static UINT16 FetchWord(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("fetch16 0x%08X\n"), a);
    
	pr = FIND_F(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		return BURN_ENDIAN_SWAP_INT16(*((UINT16*)(pr + (a & SEK_PAGEM))));
	}
	return pSekExt->ReadWord[(uintptr_t)pr](a);
}

inline static void WriteWord(UINT32 a, UINT16 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("write16 0x%08X\n"), a);
    
	pr = FIND_W(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		*((UINT16*)(pr + (a & SEK_PAGEM))) = (UINT16)BURN_ENDIAN_SWAP_INT16(d);
		return;
	}
	pSekExt->WriteWord[(uintptr_t)pr](a, d);
}

inline static void WriteWordROM(UINT32 a, UINT16 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		*((UINT16*)(pr + (a & SEK_PAGEM))) = (UINT16)d;
		return;
	}
	pSekExt->WriteWord[(uintptr_t)pr](a, d);
}

inline static UINT32 ReadLong(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("read32 0x%08X\n"), a);
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		UINT32 r = *((UINT32*)(pr + (a & SEK_PAGEM)));
		r = (r >> 16) | (r << 16);
		return BURN_ENDIAN_SWAP_INT32(r);
	}
	return pSekExt->ReadLong[(uintptr_t)pr](a);
}

inline static UINT32 FetchLong(UINT32 a)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("fetch32 0x%08X\n"), a);
    
	pr = FIND_F(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		UINT32 r = *((UINT32*)(pr + (a & SEK_PAGEM)));
		r = (r >> 16) | (r << 16);
		return BURN_ENDIAN_SWAP_INT32(r);
	}
	return pSekExt->ReadLong[(uintptr_t)pr](a);
}

inline static void WriteLong(UINT32 a, UINT32 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
    //	bprintf(PRINT_NORMAL, _T("write32 0x%08X\n"), a);
    
	pr = FIND_W(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		d = (d >> 16) | (d << 16);
		*((UINT32*)(pr + (a & SEK_PAGEM))) = BURN_ENDIAN_SWAP_INT32(d);
		return;
	}
	pSekExt->WriteLong[(uintptr_t)pr](a, d);
}

inline static void WriteLongROM(UINT32 a, UINT32 d)
{
	UINT8* pr;
    
	a &= 0xFFFFFF;
    
	pr = FIND_R(a);
	if ((uintptr_t)pr >= SEK_MAXHANDLER) {
		d = (d >> 16) | (d << 16);
		*((UINT32*)(pr + (a & SEK_PAGEM))) = d;
		return;
	}
	pSekExt->WriteLong[(uintptr_t)pr](a, d);
}


extern "C" {
    UINT32 __fastcall M68KReadByte(UINT32 a) { return (UINT32)ReadByte(a); }
    UINT32 __fastcall M68KReadWord(UINT32 a) { return (UINT32)ReadWord(a); }
    UINT32 __fastcall M68KReadLong(UINT32 a) { return               ReadLong(a); }
    
    UINT32 __fastcall M68KFetchByte(UINT32 a) { return (UINT32)FetchByte(a); }
    UINT32 __fastcall M68KFetchWord(UINT32 a) { return (UINT32)FetchWord(a); }
    UINT32 __fastcall M68KFetchLong(UINT32 a) { return               FetchLong(a); }
    
    
    void __fastcall M68KWriteByte(UINT32 a, UINT32 d) { WriteByte(a, d); }
    void __fastcall M68KWriteWord(UINT32 a, UINT32 d) { WriteWord(a, d); }
    void __fastcall M68KWriteLong(UINT32 a, UINT32 d) { WriteLong(a, d); }
}


// ----------------------------------------------------------------------------
// Memory accesses (non-emu specific)

UINT32 SekReadByte(UINT32 a) { return (UINT32)ReadByte(a); }
UINT32 SekReadWord(UINT32 a) { return (UINT32)ReadWord(a); }
UINT32 SekReadLong(UINT32 a) { return ReadLong(a); }

UINT32 SekFetchByte(UINT32 a) { return (UINT32)FetchByte(a); }
UINT32 SekFetchWord(UINT32 a) { return (UINT32)FetchWord(a); }
UINT32 SekFetchLong(UINT32 a) { return FetchLong(a); }

void SekWriteByte(UINT32 a, UINT8 d) { WriteByte(a, d); }
void SekWriteWord(UINT32 a, UINT16 d) { WriteWord(a, d); }
void SekWriteLong(UINT32 a, UINT32 d) { WriteLong(a, d); }

void SekWriteByteROM(UINT32 a, UINT8 d) { WriteByteROM(a, d); }
void SekWriteWordROM(UINT32 a, UINT16 d) { WriteWordROM(a, d); }
void SekWriteLongROM(UINT32 a, UINT32 d) { WriteLongROM(a, d); }


// ----------------------------------------------------------------------------
// Callbacks for Musashi

extern "C" INT32 M68KIRQAcknowledge(INT32 nIRQ)
{
	if (nSekIRQPending[nSekActive] & SEK_IRQSTATUS_AUTO) {
		m68k_set_irq(0);
		nSekIRQPending[nSekActive] = 0;
	}
	
	if (pSekExt->IrqCallback) {
		return pSekExt->IrqCallback(nIRQ);
	}
    
	return M68K_INT_ACK_AUTOVECTOR;
}

extern "C" void M68KResetCallback()
{
	if (pSekExt->ResetCallback) {
		pSekExt->ResetCallback();
	}
}

extern "C" void M68KRTECallback()
{
	if (pSekExt->RTECallback) {
		pSekExt->RTECallback();
	}
}

extern "C" void M68KcmpildCallback(UINT32 val, INT32 reg)
{
	if (pSekExt->CmpCallback) {
		pSekExt->CmpCallback(val, reg);
	}
}

// ----------------------------------------------------------------------------
// Initialisation/exit/reset


static INT32 SekInitCPUM68K(INT32 nCount, INT32 nCPUType)
{
	nSekCPUType[nCount] = nCPUType;
    
	switch (nCPUType) {
		case 0x68000:
			m68k_set_cpu_type(M68K_CPU_TYPE_68000);
			break;
		case 0x68010:
			m68k_set_cpu_type(M68K_CPU_TYPE_68010);
			break;
		case 0x68EC020:
			m68k_set_cpu_type(M68K_CPU_TYPE_68EC020);
			break;
		default:
			return 1;
	}
    
	nSekM68KContextSize[nCount] = m68k_context_size();
	SekM68KContext[nCount] = (INT8*)malloc(nSekM68KContextSize[nCount]);
	if (SekM68KContext[nCount] == NULL) {
		return 1;
	}
	memset(SekM68KContext[nCount], 0, nSekM68KContextSize[nCount]);
	m68k_get_context(SekM68KContext[nCount]);
    
	return 0;
}

void SekNewFrame()
{
    
	for (INT32 i = 0; i <= nSekCount; i++) {
		nSekCycles[i] = 0;
	}
    
	nSekCyclesTotal = 0;
}

void SekSetCyclesScanline(INT32 nCycles)
{
    
	nSekCyclesScanline = nCycles;
}

unsigned int PicoCheckPc(unsigned int pc) {
	pc -= PicoCpu[nSekActive].membase; // Get real pc
	pc &= 0xffffff;
	
	PicoCpu[nSekActive].membase = (int)FIND_F(pc) - (pc & ~SEK_PAGEM); //PicoMemBase(pc);
    
	return PicoCpu[nSekActive].membase + pc;
}

static int PicoIrqCallback(int int_level) {
	if (nSekIRQPending[nSekActive] & SEK_IRQSTATUS_AUTO) {
		PicoCpu[nSekActive].irq = 0;    
        
    }
    nSekIRQPending[nSekActive] = 0;
    
    if (pSekExt->IrqCallback) {
		return pSekExt->IrqCallback(int_level);
	}
        
    return CYCLONE_INT_ACK_AUTOVECTOR;    
}

static void PicoResetCallback()
{
	//dprintf("ResetCallback();\n" );
	
	if (pSekExt->ResetCallback) {
		pSekExt->ResetCallback();
	}
}

static int UnrecognizedCallback()
{
	printf("UnrecognizedCallback();\n");
	return 0;
}

INT32 SekInit(INT32 nCount, INT32 nCPUType)
{
	DebugCPU_SekInitted = 1;
	
	struct SekExt* ps = NULL;
    
	if (nSekActive >= 0) {
		SekClose();
		nSekActive = -1;
	}
    
	if (nCount > nSekCount) {
		nSekCount = nCount;
	}
    
	// Allocate cpu extenal data (memory map etc)
	SekExt[nCount] = (struct SekExt*)malloc(sizeof(struct SekExt));
	if (SekExt[nCount] == NULL) {
		SekExit();
		return 1;
	}
	memset(SekExt[nCount], 0, sizeof(struct SekExt));
    
	// Put in default memory handlers
	ps = SekExt[nCount];
    
	for (INT32 j = 0; j < SEK_MAXHANDLER; j++) {
		ps->ReadByte[j]  = DefReadByte;
		ps->WriteByte[j] = DefWriteByte;
	}
    
	ps->ReadWord[0]  = DefReadWord0;
	ps->WriteWord[0] = DefWriteWord0;
	ps->ReadLong[0]  = DefReadLong0;
	ps->WriteLong[0] = DefWriteLong0;
    
#if SEK_MAXHANDLER >= 2
	ps->ReadWord[1]  = DefReadWord1;
	ps->WriteWord[1] = DefWriteWord1;
	ps->ReadLong[1]  = DefReadLong1;
	ps->WriteLong[1] = DefWriteLong1;
#endif
    
#if SEK_MAXHANDLER >= 3
	ps->ReadWord[2]  = DefReadWord2;
	ps->WriteWord[2] = DefWriteWord2;
	ps->ReadLong[2]  = DefReadLong2;
	ps->WriteLong[2] = DefWriteLong2;
#endif
    
#if SEK_MAXHANDLER >= 4
	ps->ReadWord[3]  = DefReadWord3;
	ps->WriteWord[3] = DefWriteWord3;
	ps->ReadLong[3]  = DefReadLong3;
	ps->WriteLong[3] = DefWriteLong3;
#endif
    
#if SEK_MAXHANDLER >= 5
	ps->ReadWord[4]  = DefReadWord4;
	ps->WriteWord[4] = DefWriteWord4;
	ps->ReadLong[4]  = DefReadLong4;
	ps->WriteLong[4] = DefWriteLong4;
#endif
    
#if SEK_MAXHANDLER >= 6
	ps->ReadWord[5]  = DefReadWord5;
	ps->WriteWord[5] = DefWriteWord5;
	ps->ReadLong[5]  = DefReadLong5;
	ps->WriteLong[5] = DefWriteLong5;
#endif
    
#if SEK_MAXHANDLER >= 7
	ps->ReadWord[6]  = DefReadWord6;
	ps->WriteWord[6] = DefWriteWord6;
	ps->ReadLong[6]  = DefReadLong6;
	ps->WriteLong[6] = DefWriteLong6;
#endif
    
#if SEK_MAXHANDLER >= 8
	ps->ReadWord[7]  = DefReadWord7;
	ps->WriteWord[7] = DefWriteWord7;
	ps->ReadLong[7]  = DefReadLong7;
	ps->WriteLong[7] = DefWriteLong7;
#endif
    
#if SEK_MAXHANDLER >= 9
	ps->ReadWord[8]  = DefReadWord8;
	ps->WriteWord[8] = DefWriteWord8;
	ps->ReadLong[8]  = DefReadLong8;
	ps->WriteLong[8] = DefWriteLong8;
#endif
    
#if SEK_MAXHANDLER >= 10
	ps->ReadWord[9]  = DefReadWord9;
	ps->WriteWord[9] = DefWriteWord9;
	ps->ReadLong[9]  = DefReadLong9;
	ps->WriteLong[9] = DefWriteLong9;
#endif
    
#if SEK_MAXHANDLER >= 11
	for (int j = 10; j < SEK_MAXHANDLER; j++) {
		ps->ReadWord[j]  = DefReadWord0;
		ps->WriteWord[j] = DefWriteWord0;
		ps->ReadLong[j]  = DefReadLong0;
		ps->WriteLong[j] = DefWriteLong0;
	}
#endif
    if (bBurnUseASMCPUEmulation==0) {
        m68k_init();
        if (SekInitCPUM68K(nCount, nCPUType)) {
            SekExit();
            return 1;
        }
    } else {
        nSekCPUType[nCount] = nCPUType;
        if (!bCycloneInited) {
            CycloneInit();
            bCycloneInited = true;
        }
        memset(&PicoCpu[nCount], 0, sizeof(PicoCpu));
        
        PicoCpu[nCount].read8	= ReadByte;
        PicoCpu[nCount].read16	= ReadWord;
        PicoCpu[nCount].read32	= ReadLong;
        
        PicoCpu[nCount].write8	= WriteByte;
        PicoCpu[nCount].write16	= WriteWord;
        PicoCpu[nCount].write32	= WriteLong;
        
        PicoCpu[nCount].fetch8	= FetchByte;
        PicoCpu[nCount].fetch16	= FetchWord;
        PicoCpu[nCount].fetch32	= FetchLong;	
        
        PicoCpu[nCount].checkpc = PicoCheckPc;
        
        PicoCpu[nCount].IrqCallback = PicoIrqCallback;
        PicoCpu[nCount].ResetCallback = PicoResetCallback;
        PicoCpu[nCount].UnrecognizedCallback = UnrecognizedCallback;
        
    }    
    
	nSekCycles[nCount] = 0;
	nSekIRQPending[nCount] = 0;
    
	nSekCyclesTotal = 0;
	nSekCyclesScanline = 0;
    
	CpuCheatRegister(0x0000, nCount);
    
	return 0;
}


static void SekCPUExitM68K(INT32 i){
    if(SekM68KContext[i]) {
        free(SekM68KContext[i]);
        SekM68KContext[i] = NULL;
    }
}

static void PicoReset() {
    memset(&PicoCpu, 0, 22 * 4); // clear all regs
	
    //YOYOFR
	//PicoCpu.stopped	= 0;
    PicoCpu[nSekActive].state_flags = 0;
    
	PicoCpu[nSekActive].srh		= 0x27; // Supervisor mode
	PicoCpu[nSekActive].a[7]	= FetchLong(0); // Stack Pointer
	PicoCpu[nSekActive].membase	= 0;
	PicoCpu[nSekActive].pc		= PicoCpu[nSekActive].checkpc(FetchLong(4)); // Program Counter
}

INT32 SekExit()
{
    
	// Deallocate cpu extenal data (memory map etc)
	for (INT32 i = 0; i <= nSekCount; i++) {
        
        
        if (!bBurnUseASMCPUEmulation) SekCPUExitM68K(i);
        
		// Deallocate other context data
		if (SekExt[i]) {
			free(SekExt[i]);
			SekExt[i] = NULL;
		}
	}
    
	pSekExt = NULL;
    
	nSekActive = -1;
	nSekCount = -1;
	
	DebugCPU_SekInitted = 0;
    
	return 0;
}

void SekReset() {
    if (!bBurnUseASMCPUEmulation) m68k_pulse_reset();
    else PicoReset();
}

// ----------------------------------------------------------------------------
// Control the active CPU

// Open a CPU
void SekOpen(const INT32 i) {
	if (i != nSekActive) {
		nSekActive = i;        
		pSekExt = SekExt[nSekActive];						// Point to cpu context                
        if (!bBurnUseASMCPUEmulation) m68k_set_context(SekM68KContext[nSekActive]);
        else nSekCyclesTotal = nSekCycles[nSekActive];
	}
}

// Close the active cpu
void SekClose() {
    if (!bBurnUseASMCPUEmulation) m68k_get_context(SekM68KContext[nSekActive]);
	nSekCycles[nSekActive] = nSekCyclesTotal;
	nSekActive = -1;
}

// Get the current CPU
INT32 SekGetActive() {
	return nSekActive;
}

// Set the status of an IRQ line on the active CPU
void SekSetIRQLine(const INT32 line, const INT32 status) {
    //	bprintf(PRINT_NORMAL, _T("  - irq line %i -> %i\n"), line, status);
    
	if (status) {
		nSekIRQPending[nSekActive] = line | status;
        
        
        if (!bBurnUseASMCPUEmulation) m68k_set_irq(line);
        else {
            m68k_ICount=PicoCpu[nSekActive].cycles;
            nSekCyclesTotal += (nSekCyclesToDo - nSekCyclesDone) - m68k_ICount;
            nSekCyclesDone += (nSekCyclesToDo - nSekCyclesDone) - m68k_ICount;
            PicoCpu[nSekActive].irq = line;
            PicoCpu[nSekActive].cycles=m68k_ICount = nSekCyclesToDo = -1;
        }                
		return;
	}
    
	nSekIRQPending[nSekActive] = 0;
        
    if (!bBurnUseASMCPUEmulation) m68k_set_irq(0);
    else PicoCpu[nSekActive].irq = 0;
}

// Adjust the active CPU's timeslice
void SekRunAdjust(const INT32 nCycles) {    
    if (!bBurnUseASMCPUEmulation) {
        if (nCycles < 0 && m68k_ICount < -nCycles) {
            SekRunEnd();
            return;
        }
        nSekCyclesToDo += nCycles;
        m68k_modify_timeslice(nCycles);
    } else {
        m68k_ICount=PicoCpu[nSekActive].cycles;
        if (nCycles < 0 && m68k_ICount < -nCycles) {
            SekRunEnd();
            return;
        }

        m68k_ICount += nCycles;
        nSekCyclesToDo += nCycles;
        nSekCyclesSegment += nCycles;
        PicoCpu[nSekActive].cycles=m68k_ICount;
    }    
}

// End the active CPU's timeslice
void SekRunEnd() {
    if (!bBurnUseASMCPUEmulation) m68k_end_timeslice();
    else {
        m68k_ICount=PicoCpu[nSekActive].cycles;
        nSekCyclesTotal += (nSekCyclesToDo - nSekCyclesDone) - m68k_ICount;
        nSekCyclesDone += (nSekCyclesToDo - nSekCyclesDone) - m68k_ICount;
        nSekCyclesSegment = nSekCyclesDone;
        PicoCpu[nSekActive].cycles=m68k_ICount = nSekCyclesToDo = -1;
    }
    
}

// Run the active CPU
INT32 SekRun(const INT32 nCycles) {
    if (!bBurnUseASMCPUEmulation) {
        nSekCyclesToDo = nCycles;
        
        nSekCyclesSegment = m68k_execute(nCycles);
        
        nSekCyclesTotal += nSekCyclesSegment;
        nSekCyclesToDo = m68k_ICount = -1;
        
        return nSekCyclesSegment;
    } else {
        nSekCyclesDone = 0;
        nSekCyclesSegment = nCycles;
        do {
            m68k_ICount = PicoCpu[nSekActive].cycles = nSekCyclesToDo = nSekCyclesSegment - nSekCyclesDone;
            
            if (PicoCpu[nSekActive].irq == 0x80) {						// Cpu is in stopped state till interrupt
                // dprintf("Cpu is in stopped state till interrupt\n", nCycles);
                nSekCyclesDone = nSekCyclesSegment;
                nSekCyclesTotal += nSekCyclesSegment;
            } else {
                CycloneRun(&PicoCpu[nSekActive]);
                m68k_ICount=PicoCpu[nSekActive].cycles;
                nSekCyclesDone += nSekCyclesToDo - m68k_ICount;
                nSekCyclesTotal += nSekCyclesToDo - m68k_ICount;
            }
        } while (nSekCyclesDone < nSekCyclesSegment);
        
        
        nSekCyclesSegment = nSekCyclesDone;
        PicoCpu[nSekActive].cycles = nSekCyclesToDo = m68k_ICount = -1;
        nSekCyclesDone = 0;
        
        return nSekCyclesSegment;		
        
    }
    
}
// ----------------------------------------------------------------------------
// Memory map setup

// Note - each page is 1 << SEK_BITS.
INT32 SekMapMemory(UINT8* pMemory, UINT32 nStart, UINT32 nEnd, INT32 nType)
{
    
	UINT8* Ptr = pMemory - nStart;
	UINT8** pMemMap = pSekExt->MemMap + (nStart >> SEK_SHIFT);
    
	// Special case for ROM banks
	if (nType == SM_ROM) {
		for (UINT32 i = (nStart & ~SEK_PAGEM); i <= nEnd; i += SEK_PAGE_SIZE, pMemMap++) {
			pMemMap[0]			  = Ptr + i;
			pMemMap[SEK_WADD * 2] = Ptr + i;
		}
        
		return 0;
	}
    
	for (UINT32 i = (nStart & ~SEK_PAGEM); i <= nEnd; i += SEK_PAGE_SIZE, pMemMap++) {
        
		if (nType & SM_READ) {					// Read
			pMemMap[0]			  = Ptr + i;
		}
		if (nType & SM_WRITE) {					// Write
			pMemMap[SEK_WADD]	  = Ptr + i;
		}
		if (nType & SM_FETCH) {					// Fetch
			pMemMap[SEK_WADD * 2] = Ptr + i;
		}
	}
    
	return 0;
}

INT32 SekMapHandler(uintptr_t nHandler, UINT32 nStart, UINT32 nEnd, INT32 nType)
{
	UINT8** pMemMap = pSekExt->MemMap + (nStart >> SEK_SHIFT);
    
	// Add to memory map
	for (UINT32 i = (nStart & ~SEK_PAGEM); i <= nEnd; i += SEK_PAGE_SIZE, pMemMap++) {
        
		if (nType & SM_READ) {					// Read
			pMemMap[0]			  = (UINT8*)nHandler;
		}
		if (nType & SM_WRITE) {					// Write
			pMemMap[SEK_WADD]	  = (UINT8*)nHandler;
		}
		if (nType & SM_FETCH) {					// Fetch
			pMemMap[SEK_WADD * 2] = (UINT8*)nHandler;
		}
	}
    
	return 0;
}

// Set callbacks
INT32 SekSetResetCallback(pSekResetCallback pCallback)
{
    
	pSekExt->ResetCallback = pCallback;
    
	return 0;
}

INT32 SekSetRTECallback(pSekRTECallback pCallback)
{
	pSekExt->RTECallback = pCallback;
    
	return 0;
}

INT32 SekSetIrqCallback(pSekIrqCallback pCallback)
{
	pSekExt->IrqCallback = pCallback;
    
	return 0;
}

INT32 SekSetCmpCallback(pSekCmpCallback pCallback)
{
	pSekExt->CmpCallback = pCallback;
    
	return 0;
}

// Set handlers
INT32 SekSetReadByteHandler(INT32 i, pSekReadByteHandler pHandler)
{
    
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->ReadByte[i] = pHandler;
    
	return 0;
}

INT32 SekSetWriteByteHandler(INT32 i, pSekWriteByteHandler pHandler)
{
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->WriteByte[i] = pHandler;
    
	return 0;
}

INT32 SekSetReadWordHandler(INT32 i, pSekReadWordHandler pHandler)
{
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->ReadWord[i] = pHandler;
    
	return 0;
}

INT32 SekSetWriteWordHandler(INT32 i, pSekWriteWordHandler pHandler)
{
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->WriteWord[i] = pHandler;
    
	return 0;
}

INT32 SekSetReadLongHandler(INT32 i, pSekReadLongHandler pHandler)
{
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->ReadLong[i] = pHandler;
    
	return 0;
}

INT32 SekSetWriteLongHandler(INT32 i, pSekWriteLongHandler pHandler)
{
	if (i >= SEK_MAXHANDLER) {
		return 1;
	}
    
	pSekExt->WriteLong[i] = pHandler;
    
	return 0;
}

// ----------------------------------------------------------------------------
// Query register values

INT32 SekGetPC(INT32) {
    if (!bBurnUseASMCPUEmulation) return m68k_get_reg(NULL, M68K_REG_PC);
    else return PicoCpu[nSekActive].pc-PicoCpu[nSekActive].membase;
}

INT32 SekDbgGetCPUType() {
    if (bBurnUseASMCPUEmulation) return 0x68000;
    else {
        switch (nSekCPUType[nSekActive]) {
            case 0:
            case 0x68000:
                return M68K_CPU_TYPE_68000;
            case 0x68010:
                return M68K_CPU_TYPE_68010;
            case 0x68EC020:
                return M68K_CPU_TYPE_68EC020;
        }
        return 0;
    }
}

INT32 SekDbgGetPendingIRQ() {
	return nSekIRQPending[nSekActive] & 7;
}

UINT32 SekDbgGetRegister(SekRegister nRegister){
    return 0;
}

bool SekDbgSetRegister(SekRegister nRegister, UINT32 nValue) {
    return false;
}

// ----------------------------------------------------------------------------
// Savestate support

INT32 SekScan(INT32 nAction) {
	// Scan the 68000 states
	struct BurnArea ba;
    
	if ((nAction & ACB_DRIVER_DATA) == 0) {
		return 1;
	}
    
	memset(&ba, 0, sizeof(ba));
    
	nSekActive = -1;
    
	for (INT32 i = 0; i <= nSekCount; i++) {
        char szName[11];
        if (bBurnUseASMCPUEmulation) strcpy(szName,"Cyclone #n");
        else strcpy(szName,"MC68000 #n");
        
		szName[9] = '0' + i;
        
		SCAN_VAR(nSekCPUType[i]);
        
        if (bBurnUseASMCPUEmulation) {
            //if (nSekCPUType != 0) {
            ba.Data = &PicoCpu[i];
            ba.nLen = 24 * 4;
            ba.szName = szName;
            BurnAcb(&ba);
            //}
        } else {
            if (nSekCPUType[i] != 0) {
                ba.Data = SekM68KContext[i];
                ba.nLen = nSekM68KContextSize[i];
                ba.szName = szName;
                BurnAcb(&ba);
            }
        }
        
	}
    
	return 0;
}

#if TARGET_IPHONE_SIMULATOR
void CycloneInit(void) {
    
}

// Run cyclone. Cycles should be specified in context (pcy->cycles)
void CycloneRun(struct Cyclone *pcy) {
    
}

#endif

