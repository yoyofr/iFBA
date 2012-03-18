// Nec V20/V30/V33/V25/V35 interface
// Written by OopsWare
// http://oopsware.googlepages.com
// Heavily modified by iq_132 (Nov, 2011)

#include "burnint.h"
#include "vez.h"
#include "armnec.h"

#define MAX_VEZ		4

//----------------------------------------------------------------------------------
//armnec
void (*ArmNecIrq)(struct ArmNec *, int);
int (*ArmNecRun)(struct ArmNec *);
unsigned int *ArmNecCryptTable;


// nec.cpp
void necInit(INT32 cpu, INT32 type);
void necCpuOpen(INT32 cpu);
void necCpuClose();
INT32 nec_reset();
INT32 nec_execute(INT32 cycles);
void nec_set_irq_line_and_vector(INT32 irqline, INT32 vector, INT32 state);
UINT32 nec_total_cycles();
void nec_new_frame();
INT32 necGetPC(INT32 n);
void necScan(INT32 cpu, INT32 nAction);
void necRunEnd();
void necIdle(INT32 cycles);

// v25.cpp
INT32 v25_reset();
void v25_open(INT32 cpu);
void v25_close();
void v25_set_irq_line_and_vector(INT32 irqline, INT32 vector, INT32 state);
INT32 v25_execute(INT32 cycles);
void v25Init(INT32 cpu, INT32 type, INT32 clock);
void v25_set_decode(UINT8 *table);
UINT32 v25_total_cycles();
void v25_new_frame();
INT32 v25GetPC(INT32 n);
void v25Scan(INT32 cpu, INT32 nAction);
void v25RunEnd();
void v25Idle(INT32 cycles);

//----------------------------------------------------------------------------------

struct VezContext {
	void (*cpu_open)(INT32);
	void (*cpu_close)();
	INT32 (*cpu_reset)();
	INT32 (*cpu_execute)(INT32);
	void (*cpu_set_irq_line)(INT32, INT32, INT32);
	void (*decode)(UINT8*);
	UINT32 (*total_cycles)();
	INT32 (*get_pc)(INT32);
	void (*scan)(INT32, INT32);
	void (*runend)();
	void (*idle)(INT32);
    
    struct ArmNec cpu;
    INT32 cpu_type;
    unsigned int  *pCryptTable;
    int cpu_total_cycles;
    int pending_irq;
    int irq_vector;
    int irq_state;
    int nmi_state;
    
    
	UINT8 * ppMemRead[512];
	UINT8 * ppMemWrite[512];
	UINT8 * ppMemFetch[512];
	UINT8 * ppMemFetchData[512];
    
	// Handlers
#ifdef FASTCALL
	UINT8 (__fastcall *ReadHandler)(UINT32 a);
	void (__fastcall *WriteHandler)(UINT32 a, UINT8 d);
	UINT8 (__fastcall *ReadPort)(UINT32 a);
	void (__fastcall *WritePort)(UINT32 a, UINT8 d);
#else
	UINT8 (__cdecl *ReadHandler)(UINT32 a);
	void (__cdecl *WriteHandler)(UINT32 a, UINT8 d);
	UINT8 (__cdecl *ReadPort)(UINT32 a);
	void (__cdecl *WritePort)(UINT32 a, UINT8 d);
#endif
};

static struct VezContext *VezCPUContext[MAX_VEZ] = { NULL, NULL, NULL, NULL };
struct VezContext *VezCurrentCPU = 0;

#define VEZ_MEM_SHIFT	11
#define VEZ_MEM_MASK	((1 << VEZ_MEM_SHIFT) - 1)

static INT32 nCPUCount = 0;
static INT32 nOpenedCPU = -1;
INT32 nVezCount;

UINT8 __fastcall VezDummyReadHandler(UINT32) { return 0; }
void __fastcall VezDummyWriteHandler(UINT32, UINT8) { }
UINT8 __fastcall VezDummyReadPort(UINT32) { return 0; }
void __fastcall VezDummyWritePort(UINT32, UINT8) { }


UINT8 cpu_readport(UINT32 p)
{
	p &= 0x100ff; // ?
    
	return VezCurrentCPU->ReadPort(p);
}

void cpu_writeport(UINT32 p,UINT32 d)
{
	VezCurrentCPU->WritePort(p, d);
}

UINT8 cpu_readmem20(UINT32 a)
{
	a &= 0xFFFFF;
	
	UINT8 * p = VezCurrentCPU->ppMemRead[ a >> VEZ_MEM_SHIFT ];
	if ( p )
		return *(p + a);
	else
		return VezCurrentCPU->ReadHandler(a);
}

UINT8 cpu_readmem20_op(UINT32 a)
{
	a &= 0xFFFFF;
	
	UINT8 * p = VezCurrentCPU->ppMemFetch[ a >> VEZ_MEM_SHIFT ];
	if ( p )
		return *(p + a);
	else
		return VezCurrentCPU->ReadHandler(a);
}

UINT8 cpu_readmem20_arg(UINT32 a)
{
	a &= 0xFFFFF;
	
	UINT8 * p = VezCurrentCPU->ppMemFetchData[ a >> VEZ_MEM_SHIFT ];
	if ( p )
		return *(p + a);
	else
		return VezCurrentCPU->ReadHandler(a);
}

void cpu_writemem20(UINT32 a, UINT8 d)
{
	a &= 0xFFFFF;
	
	UINT8 * p = VezCurrentCPU->ppMemWrite[ a >> VEZ_MEM_SHIFT ];
	if ( p )
		*(p + a) = d;
	else
		VezCurrentCPU->WriteHandler(a, d);
}

static void VezCheatWrite(UINT32 a, UINT8 d)
{
	a &= 0xfffff;
    
	UINT8 * p;
    
	p = VezCurrentCPU->ppMemWrite[ a >> VEZ_MEM_SHIFT ];
	if ( p ) *(p + a) = d;
    
	p = VezCurrentCPU->ppMemRead[ a >> VEZ_MEM_SHIFT ];
	if ( p ) *(p + a) = d;
    
	p = VezCurrentCPU->ppMemFetch[ a >> VEZ_MEM_SHIFT ];
	if ( p ) *(p + a) = d;
    
	p = VezCurrentCPU->ppMemFetchData[ a >> VEZ_MEM_SHIFT ];
	if ( p ) *(p + a) = d;
    
	VezCurrentCPU->WriteHandler(a, d);
}

void VezSetReadHandler(UINT8 (__fastcall *pHandler)(UINT32))
{
	VezCurrentCPU->ReadHandler = pHandler;
    if (bBurnUseASMCPUVEZEmulation) VezCurrentCPU->cpu.read8 = pHandler;
}

void VezSetWriteHandler(void (__fastcall *pHandler)(UINT32, UINT8))
{
	VezCurrentCPU->WriteHandler = pHandler;
    if (bBurnUseASMCPUVEZEmulation) VezCurrentCPU->cpu.write8 = pHandler;
}

void VezSetReadPort(UINT8 (__fastcall *pHandler)(UINT32))
{
	VezCurrentCPU->ReadPort = pHandler;
    if (bBurnUseASMCPUVEZEmulation) VezCurrentCPU->cpu.in8=pHandler;
}

void VezSetWritePort(void (__fastcall *pHandler)(UINT32, UINT8))
{
	VezCurrentCPU->WritePort = pHandler;
    if (bBurnUseASMCPUVEZEmulation) VezCurrentCPU->cpu.out8=pHandler;
}

void VezSetDecode(UINT8 *table)
{
	if (VezCurrentCPU->decode) {
		VezCurrentCPU->decode(table);
	}
}

static cpu_core_config VezCheatCpuConfig =
{
	VezOpen,
	VezClose,
	cpu_readmem20,
	VezCheatWrite,
	VezGetActive,
	VezTotalCycles,
	VezNewFrame,
	VezRun,
	VezRunEnd,
	VezReset,
	1<<20,
	0
};

void armcpu_open(INT32 cpu) {
    
}
void armcpu_close() {
    
}
INT32 armcpu_reset() {
    if ( VezCurrentCPU ) {
		memset( &(VezCurrentCPU->cpu), 0, 0x24 );
		
		VezCurrentCPU->cpu.sreg[1] = 0xffff;//ps;		// 0xffff is default, currently for m92 system
		VezCurrentCPU->cpu.flags = 0x8000;			// MF
		
		VezCurrentCPU->cpu.mem_base = (unsigned int)VezCurrentCPU->ppMemRead[ 0 ];
		VezCurrentCPU->cpu.pc = VezCurrentCPU->cpu.mem_base + (VezCurrentCPU->cpu.sreg[1] << 4) + VezCurrentCPU->cpu.ip;
	}
	return 0;    
}
INT32 armcpu_execute(INT32 nCycles) {
    VezCurrentCPU->cpu.cycles = nCycles;
    
    if (VezCurrentCPU->pending_irq) {
        if( VezCurrentCPU->pending_irq & (1<<1)/*NMI_IRQ*/ )
        {
            ArmNecIrq(&(VezCurrentCPU->cpu), 2/*ARMNEC_NMI_INT*/);
            
            VezCurrentCPU->cpu.mem_base = (unsigned int)VezCurrentCPU->ppMemRead[ 0 ];
            VezCurrentCPU->cpu.pc = VezCurrentCPU->cpu.mem_base + (VezCurrentCPU->cpu.sreg[1] << 4) + VezCurrentCPU->cpu.ip;
            
            VezCurrentCPU->pending_irq &= ~(1<<1); /*NMI_IRQ*/
        }
        else if( VezCurrentCPU->pending_irq )
        {
            ArmNecIrq(&(VezCurrentCPU->cpu),VezCurrentCPU->irq_vector);
            
            VezCurrentCPU->cpu.mem_base = (unsigned int)VezCurrentCPU->ppMemRead[ 0 ];
            VezCurrentCPU->cpu.pc = VezCurrentCPU->cpu.mem_base + (VezCurrentCPU->cpu.sreg[1] << 4) + VezCurrentCPU->cpu.ip;
            
            VezCurrentCPU->irq_state = 0;//CLEAR_LINE;
            VezCurrentCPU->pending_irq &= ~1;//INT_IRQ;
        }
    }
    
    int cycles_remaining=ArmNecRun( &(VezCurrentCPU->cpu));
    VezCurrentCPU->cpu_total_cycles+=nCycles-cycles_remaining;
    
    VezCurrentCPU->cpu.mem_base = (unsigned int)VezCurrentCPU->ppMemRead[ 0 ];
    VezCurrentCPU->cpu.pc = VezCurrentCPU->cpu.mem_base + (VezCurrentCPU->cpu.sreg[1] << 4) + VezCurrentCPU->cpu.ip;
    
    
    return nCycles - cycles_remaining;
}
void armcpu_set_irq_line(INT32 line, INT32 vector, INT32 status) {
    switch (line) {
        case 0:
            
            VezCurrentCPU->irq_state=status;
            if (status==0/*CLEAR_LINE*/) {
                VezCurrentCPU->pending_irq &= ~1;//INT_IRQ;
            } else {        
                VezCurrentCPU->pending_irq |= 1;//INT_IRQ;
                VezCurrentCPU->irq_vector=vector;
            }
            break;
        case 0x20://INPUT_LINE_NMI:
			if (VezCurrentCPU->nmi_state == (unsigned int)status) return;
            VezCurrentCPU->nmi_state = status;
			if (status != 0)
			{
				VezCurrentCPU->irq_vector = vector;
				VezCurrentCPU->pending_irq |= 1<<1;//NMI_IRQ;
				//VezCurrentCPU->halted = 0;
			}
			break;
		case 20://NEC_INPUT_LINE_POLL:
			VezCurrentCPU->irq_vector = vector;
			//VezCurrentCPU->poll_state = state;
			break;
    }
}

UINT32 armtotal_cycles() {
    return VezCurrentCPU->cpu_total_cycles;
}
INT32 armget_pc(INT32 n) {
    if (n==-1) return VezCurrentCPU->cpu.pc - VezCurrentCPU->cpu.mem_base;
    else return VezCPUContext[n]->cpu.pc - VezCPUContext[n]->cpu.mem_base;
}
void armscan(INT32, INT32){
    
}
void armrunend(){
    
}
void armidle(INT32 cycles){
    VezCurrentCPU->cpu.cycles-=cycles;
}

void armdecryptOpcode(unsigned char * tbl)
{
    //VezCurrentCPU->
    //unsigned int ArmV33CryptTable[]
    unsigned int *pct = ArmNecCryptTable;
    
    unsigned int cnt = 0;
    while ( pct[cnt] ) cnt++;
    
    VezCurrentCPU->pCryptTable = (unsigned int *) malloc ( 0x400 * cnt );
    if (! VezCurrentCPU->pCryptTable ) return;
    
    for(int i=0; i<cnt; i++) {
        unsigned int *pdst = &( VezCurrentCPU->pCryptTable[ 0x100 * i ] );
        unsigned int *psrc = (unsigned int *) (pct[i]);
        // backup opcode jump table
        memcpy( pdst, psrc, 0x400 );
        // decrypt it
        for(int j=0;j<256;j++)
            psrc[j] = pdst[ tbl[j] ];
    }
}

static unsigned int VezDummyReadWordHandler(unsigned int a) 
{ 
	unsigned int a1 = VezCurrentCPU->cpu.read8(a);
	unsigned int a2 = VezCurrentCPU->cpu.read8(a + 1);
	return a1 | (a2 << 8) ;
}

static void VezDummyWriteWordHandler(unsigned int a, unsigned int d) 
{ 
	VezCurrentCPU->cpu.write8(a, d & 0xff);
	VezCurrentCPU->cpu.write8(a + 1, d >> 8);
}



static unsigned int VezDummyCheckPC(unsigned int ps, unsigned int ip) 
{
	return VezCurrentCPU->cpu.mem_base + (ps << 4) + ip;
}

static int VezDummyUnrecognizedCallback(unsigned int a)
{
	a -= VezCurrentCPU->cpu.mem_base ;
	
    //	printf("Unknown Opcode at %08x, Emu Exit!\n", a);
	
    //	PostQuitMessage(0);
	return 0;
}


INT32 VezInit(INT32 cpu, INT32 type, INT32 clock)
{
    DebugCPU_VezInitted = 1;
    
    if (cpu >= MAX_VEZ) {
        bprintf (0, _T("Only %d Vez available! Increase MAX_VEZ in vez.cpp.\n"), MAX_VEZ);
    }
    
    VezCPUContext[cpu] = (VezContext*)BurnMalloc(sizeof(VezContext));
    
    VezCurrentCPU = VezCPUContext[cpu];
    
    memset(VezCurrentCPU, 0, sizeof(struct VezContext));
    VezCurrentCPU->cpu_type=type;
    
    switch (type)
    {
        case V20_TYPE:
        case V30_TYPE:
        case V33_TYPE:
        {
            if (bBurnUseASMCPUVEZEmulation) {
                VezCurrentCPU->cpu_open = armcpu_open;
                VezCurrentCPU->cpu_close = armcpu_close;
                VezCurrentCPU->cpu_reset = armcpu_reset;
                VezCurrentCPU->cpu_execute = armcpu_execute;
                VezCurrentCPU->cpu_set_irq_line = armcpu_set_irq_line;                
                VezCurrentCPU->decode = armdecryptOpcode;
                VezCurrentCPU->total_cycles = armtotal_cycles;
                VezCurrentCPU->get_pc = armget_pc;
                
                VezCurrentCPU->scan = armscan;
                VezCurrentCPU->runend = armrunend;
                VezCurrentCPU->idle = armidle;
                
                VezCurrentCPU->cpu.ReadMemMap = VezCurrentCPU->ppMemRead;
                VezCurrentCPU->cpu.WriteMemMap = VezCurrentCPU->ppMemWrite;
                
                VezCurrentCPU->cpu.read8 = VezDummyReadHandler;
                VezCurrentCPU->cpu.read16 = VezDummyReadWordHandler;
                
                VezCurrentCPU->cpu.write8 = VezDummyWriteHandler;
                VezCurrentCPU->cpu.write16 = VezDummyWriteWordHandler;
                
                VezCurrentCPU->cpu.in8 = VezDummyReadPort;
                VezCurrentCPU->cpu.out8 = VezDummyWritePort;
                
                
                VezCurrentCPU->cpu.checkpc = VezDummyCheckPC;
                VezCurrentCPU->cpu.UnrecognizedCallback =  VezDummyUnrecognizedCallback;
                
            } else {
                
                necInit(cpu, type);
                
                VezCurrentCPU->cpu_open = necCpuOpen;
                VezCurrentCPU->cpu_close = necCpuClose;
                VezCurrentCPU->cpu_reset = nec_reset;
                VezCurrentCPU->cpu_execute = nec_execute;
                VezCurrentCPU->cpu_set_irq_line = nec_set_irq_line_and_vector;
                VezCurrentCPU->decode = NULL; // ?
                
                VezCurrentCPU->total_cycles = nec_total_cycles;
                VezCurrentCPU->get_pc = necGetPC;
                VezCurrentCPU->scan = necScan;
                VezCurrentCPU->runend = necRunEnd;
                VezCurrentCPU->idle = necIdle;
                
            }
            
            
        }
            break;
            
        case V25_TYPE:
        case V35_TYPE:
        {
            v25Init(cpu, type&0xff, clock);
            
            VezCurrentCPU->cpu_open = v25_open;
            VezCurrentCPU->cpu_close = v25_close;
            VezCurrentCPU->cpu_reset = v25_reset;
            VezCurrentCPU->cpu_execute = v25_execute;
            VezCurrentCPU->cpu_set_irq_line = v25_set_irq_line_and_vector;
            VezCurrentCPU->decode = v25_set_decode;
            VezCurrentCPU->total_cycles = v25_total_cycles;
            VezCurrentCPU->get_pc = v25GetPC;
            VezCurrentCPU->scan = v25Scan;
            VezCurrentCPU->runend = v25RunEnd;
            VezCurrentCPU->idle = v25Idle;
            
        }
            break;
    }
    
    VezCurrentCPU->ReadHandler = VezDummyReadHandler;
    VezCurrentCPU->WriteHandler = VezDummyWriteHandler;
    VezCurrentCPU->ReadPort = VezDummyReadPort;
    VezCurrentCPU->WritePort = VezDummyWritePort;
    
    INT32 nCount = nVezCount+1;
    
    nVezCount = nCPUCount = nCount;
    
    CpuCheatRegister(cpu, &VezCheatCpuConfig);
    
    return 0;
}

INT32 VezInit(INT32 cpu, INT32 type)
{
    return VezInit(cpu, type, 0);
}

void VezExit()
{
    if (bBurnUseASMCPUVEZEmulation) {
        for(int j=0;j<MAX_VEZ; j++) {
            if (VezCPUContext[j]) {
                if (! VezCPUContext[j]->pCryptTable ) continue;
                
                unsigned int *pct = ArmV33CryptTable;
                unsigned int cnt = 0;
                while ( pct[cnt] ) cnt++;
                
                for(int i=0; i<cnt; i++) {
                    unsigned int *pdst = & VezCPUContext[j]->pCryptTable[ 0x100 * i ];
                    unsigned int *psrc = (unsigned int *) (pct[i]);
                    // restore opcode jump table
                    memcpy( psrc, pdst, 0x400 );
                }
                free(VezCPUContext[j]->pCryptTable);
            }
        }
    }
    
    for (INT32 i = 0; i < MAX_VEZ; i++) {
        if (VezCPUContext[i]) {
            BurnFree(VezCPUContext[i]);
        }
    }
    
    nCPUCount = 0;
    nOpenedCPU = -1;
    nVezCount = 0;
    
    nOpenedCPU = -1;
    
    DebugCPU_VezInitted = 0;
}

void VezOpen(INT32 nCPU)
{
    if (nCPU >= MAX_VEZ || nCPU < 0) nCPU = 0;
    
    nOpenedCPU = nCPU;
    VezCurrentCPU = VezCPUContext[nCPU];
    VezCurrentCPU->cpu_open(nCPU);
    
    if (bBurnUseASMCPUVEZEmulation) {
        switch( VezCurrentCPU->cpu_type ) {
            case V33_TYPE:
                ArmNecIrq = ArmV33Irq;
                ArmNecRun = ArmV33Run;
                ArmNecCryptTable = ArmV33CryptTable;
                break;
            case V30_TYPE:
                ArmNecIrq = ArmV30Irq;
                ArmNecRun = ArmV30Run;
                ArmNecCryptTable = ArmV30CryptTable;
                break;
        }
    }
}

void VezClose()
{
    nOpenedCPU = -1;
    VezCurrentCPU->cpu_close();
    VezCurrentCPU = 0;
}

void VezNewFrame()
{
    v25_new_frame();
    nec_new_frame();
    // should be separated?
    if (bBurnUseASMCPUVEZEmulation) {
        
    } else {
        
        
    }
}

void VezRunEnd()
{
    VezCurrentCPU->runend();
}

void VezIdle(INT32 cycles)
{
    VezCurrentCPU->idle(cycles);
}

INT32 VezTotalCycles()
{
    return VezCurrentCPU->total_cycles();
}

INT32 VezGetActive()
{
    return nOpenedCPU;
}

INT32 VezMemCallback(INT32 nStart,INT32 nEnd,INT32 nMode)
{
    nStart >>= VEZ_MEM_SHIFT;
    nEnd += VEZ_MEM_MASK;
    nEnd >>= VEZ_MEM_SHIFT;
    
    for (INT32 i = nStart; i < nEnd; i++) {
        switch (nMode) {
            case 0:
                VezCurrentCPU->ppMemRead[i] = NULL;
                break;
            case 1:
                VezCurrentCPU->ppMemWrite[i] = NULL;
                break;
            case 2:
                VezCurrentCPU->ppMemFetch[i] = NULL;
                VezCurrentCPU->ppMemFetchData[i] = NULL;
                break;
        }
    }
    return 0;
}

INT32 VezMapArea(INT32 nStart, INT32 nEnd, INT32 nMode, UINT8 *Mem)
{
    INT32 s = nStart >> VEZ_MEM_SHIFT;
    INT32 e = (nEnd + VEZ_MEM_MASK) >> VEZ_MEM_SHIFT;
    
    for (INT32 i = s; i < e; i++) {
        switch (nMode) {
            case 0:
                VezCurrentCPU->ppMemRead[i] = Mem - nStart;
                break;
            case 1:
                VezCurrentCPU->ppMemWrite[i] = Mem - nStart;
                break;
            case 2:
                VezCurrentCPU->ppMemFetch[i] = Mem - nStart;
                VezCurrentCPU->ppMemFetchData[i] = Mem - nStart;
                break;
        }
    }
    
    return 0;
}

INT32 VezMapArea(INT32 nStart, INT32 nEnd, INT32 nMode, UINT8 *Mem1, UINT8 *Mem2)
{
    INT32 s = nStart >> VEZ_MEM_SHIFT;
    INT32 e = (nEnd + VEZ_MEM_MASK) >> VEZ_MEM_SHIFT;
    
    if (nMode != 2) return 1;
    
    for (INT32 i = s; i < e; i++) {
        VezCurrentCPU->ppMemFetch[i] = Mem1 - nStart;
        VezCurrentCPU->ppMemFetchData[i] = Mem2 - nStart;
    }
    
    return 0;
}

void VezReset()
{
    VezCurrentCPU->cpu_reset();
}

INT32 VezRun(INT32 nCycles)
{
    if (nCycles <= 0) return 0;
    
    return VezCurrentCPU->cpu_execute(nCycles);
}

INT32 VezPc(INT32 n)
{
    if (n == -1) {
        return VezCurrentCPU->get_pc(-1);
    } else {
        if (n >= MAX_VEZ) return 0;
        struct VezContext *CPU = VezCPUContext[n];
        return CPU->get_pc(n);
    }
    
    return 0;
}

INT32 VezScan(INT32 nAction)
{
    if (bBurnUseASMCPUVEZEmulation) return 0;
    
    if ((nAction & ACB_DRIVER_DATA) == 0)
        return 0;
    
    for (INT32 i = 0; i < nCPUCount; i++) {
        struct VezContext *CPU = VezCPUContext[i];
        if (CPU->scan) {
            CPU->scan(i, nAction);
        }
    }
    
    return 0;
}


void VezSetIRQLineAndVector(const INT32 line, const INT32 vector, const INT32 status)
{
    /*    if (bBurnUseASMCPUVEZEmulation) {
     if ( !status ) return ;
     if ( VezCurrentCPU ) {
     if (VezCurrentCPU->cpu.flags & 0x0200)	// check IF
     ArmNecIrq( &(VezCurrentCPU->cpu), vector );
     }
     return;
     }*/
    if (status == VEZ_IRQSTATUS_AUTO)
    {        
        VezCurrentCPU->cpu_set_irq_line(line, vector, VEZ_IRQSTATUS_ACK);
        VezCurrentCPU->cpu_execute(100);
        VezCurrentCPU->cpu_set_irq_line(line, vector, VEZ_IRQSTATUS_NONE);
        VezCurrentCPU->cpu_execute(100);
    }
    else
    {
        VezCurrentCPU->cpu_set_irq_line(line, vector, status);
    }
}

#if TARGET_IPHONE_SIMULATOR
void ArmV33Irq(struct ArmNec *, int) {
    
}
int ArmV33Run(struct ArmNec *) {
    return 0;
}
unsigned int ArmV33CryptTable[1];

void ArmV30Irq(struct ArmNec *, int) {
    
}
int ArmV30Run(struct ArmNec *) {
    return 0;
}
unsigned int ArmV30CryptTable[1];

#endif