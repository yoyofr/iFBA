//
//  EmuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define VPAD_SPECIALS_BUTTON_NB 4
#define MAX_JOYSTICKS 4
#define min(a,b) (a<b?a:b)

#ifdef TESTFLIGHT
#import "TestFlight.h"
#endif

#include "inp_sdl_keys.h"
unsigned char joy_state[MAX_JOYSTICKS][GN_MAX_KEY];

#import "EmuViewController.h"
#include "string.h"
#include "sdl_font.h"
#import "fbaconf.h"
ifba_conf_t ifba_conf;

#import "BTstack/BTDevice.h"
#import "BTstack/btstack.h"
#import "BTstack/run_loop.h"
#import "BTstack/hci_cmds.h"
#import "BTstack/wiimote.h"
static BTDevice *device;
static uint16_t wiiMoteConHandle = 0;
void startWiimoteDetection(void);
void stopWiimoteDetection(void);

int iOS_wiiDeadZoneValue;
int iOS_inGame;
int iOS_waysStick=0;
float joy_analog_x[MAX_JOYSTICKS];
float joy_analog_y[MAX_JOYSTICKS];
float joy_analog_l[MAX_JOYSTICKS];
float joy_analog_r[MAX_JOYSTICKS];
int wm_joy_pl[MAX_JOYSTICKS];
int wm_prev_joy_pl[MAX_JOYSTICKS];

t_button_map joymap_iCade[10]={
    {"Start",4},
    {"Select/Coin",8},
    {"Menu",0},
    {"Turbo",0},
    {"Fire 1",1},
    {"Fire 2",2},
    {"Fire 3",3},
    {"Fire 4",5},
    {"Fire 5",6},
    {"Fire 6",7},    
};
int joymap_dir_iCade[8];


extern int fba_main( int argc, char **argv );
extern bool bAppDoFast;

volatile int mNewGLFrame;
void updateVbuffer(unsigned short *buff,int w,int h,int pitch);

static unsigned short *vbuffer;
static int visible_area_w,visible_area_h;
static int vid_rotated,vid_aspectX,vid_aspectY;
int nShouldExit;
static GLuint txt_vbuffer;  
static volatile float pb_value;
static volatile int pb_total;
static char pb_msg[256];


int device_isIpad;
unsigned int virtual_stick_buttons_alpha=75;
unsigned int virtual_stick_buttons_alpha2=150;
int virtual_stick_on;
long virtual_stick_padfinger;


int virtual_stick_pad;
int virtual_stick_posx=70;
int virtual_stick_posy=320-70;
int virtual_stick_maxdist=70;
int virtual_stick_mindist=10;
int virtual_stick_maxdist2=70*70;
int virtual_stick_mindist2=10*10;
int vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;
float virtual_stick_angle;
typedef struct {int button_id,x,y,w,h,sw,sh;unsigned char r,g,b;long finger_id;} t_touch_area;
t_touch_area *virtual_stick;

void computeButtonLayout(int btnsize,int nb_button,int width,int height);

void computeButtonLayout(int btnsize,int nb_button,int width,int height){
    int w=width;
    int h=height;
    if (device_isIpad) h-=40;
    for (int i=0;i<nb_button;i++) {
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].r=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].g=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].b=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].w=btnsize;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].sw=btnsize;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].h=btnsize;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].sh=btnsize;
    }
    if (width>height) {//horizontal        
        switch (nb_button) {
            case 0:
                break;
            case 1:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                break;
            case 2:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize*2.1f; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*2.1f;
                break;
            case 3:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize*2.1f; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize;      virtual_stick[6].y=h-btnsize;
                break;
            case 4:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize*2.1f; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize*2.1f; virtual_stick[6].y=h-btnsize;
                virtual_stick[7].x=w-btnsize;      virtual_stick[7].y=h-btnsize;
                break;
            case 5:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize*3.15f; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                virtual_stick[5].x=w-btnsize*2.1f; virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize;      virtual_stick[6].y=h-btnsize*2.1f;
                virtual_stick[7].x=w-btnsize*2.1f; virtual_stick[7].y=h-btnsize;
                virtual_stick[8].x=w-btnsize;      virtual_stick[8].y=h-btnsize;
                break;
            case 6:
            default:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize*3.15f; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.1f;
                virtual_stick[5].x=w-btnsize*2.1f; virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize;      virtual_stick[6].y=h-btnsize*2.1f;
                virtual_stick[7].x=w-btnsize*3.15f; virtual_stick[7].y=h-btnsize;
                virtual_stick[8].x=w-btnsize*2.1f; virtual_stick[8].y=h-btnsize;
                virtual_stick[9].x=w-btnsize;      virtual_stick[9].y=h-btnsize;            
                break;
        }
    } else {//vertical
        switch (nb_button) {
            case 0:
                break;
            case 1:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.6f;
                break;
            case 2:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize; virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.6f;
                virtual_stick[5].x=w-btnsize; virtual_stick[5].y=h-btnsize*1.5f;
                break;
            case 3:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize;      virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.6f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*1.5f;
                virtual_stick[6].x=w-btnsize*2.1f; virtual_stick[6].y=h-btnsize*2.6f;
                break;
            case 4:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize;      virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*2.6f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*1.5f;
                virtual_stick[6].x=w-btnsize*2.1f; virtual_stick[6].y=h-btnsize*2.6f;
                virtual_stick[7].x=w-btnsize*2.1f; virtual_stick[7].y=h-btnsize*1.5f;
                break;
            case 5:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize;      virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*3.15f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize;      virtual_stick[6].y=h-btnsize;
                virtual_stick[7].x=w-btnsize*2.1f; virtual_stick[7].y=h-btnsize*3.15f;
                virtual_stick[8].x=w-btnsize*2.1f; virtual_stick[8].y=h-btnsize*2.1f;
                break;
            case 6:
            default:
                virtual_stick[VPAD_SPECIALS_BUTTON_NB].x=w-btnsize;      virtual_stick[VPAD_SPECIALS_BUTTON_NB].y=h-btnsize*3.15f;
                virtual_stick[5].x=w-btnsize;      virtual_stick[5].y=h-btnsize*2.1f;
                virtual_stick[6].x=w-btnsize;      virtual_stick[6].y=h-btnsize;
                virtual_stick[7].x=w-btnsize*2.1f; virtual_stick[7].y=h-btnsize*3.15f;
                virtual_stick[8].x=w-btnsize*2.1f; virtual_stick[8].y=h-btnsize*2.1f;
                virtual_stick[9].x=w-btnsize*2.1f; virtual_stick[9].y=h-btnsize;            
                break;
        }
        
    }
}

t_touch_area virtual_stick_iphone_landscape[VSTICK_NB_BUTTON]={
    {GN_START,      480-48,         0,              48,48,32,32,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,480-48,         48,             48,48,32,32,0xDF,0xDF,0x3F,0},
    {GN_MENU_KEY,     0,            0,              48,48,32,32,0x4F,0xFF,0x1F,0},
    {GN_TURBO,        0,            48,             48,48,32,32,0xFF,0xFF,0x2F,0},
    {GN_A,          480-64-10-64,   320-64-6-64,   64,64,64,64,0xCF,0xCF,0xCF,0},
    {GN_B,          480-64,         320-64-6-64-10,   64,64,64,64,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          480-64-10-64,   320-64,         64,64,64,64,0x00,0xFF,0x00,0},  //green
    {GN_D,          480-64,         320-64-10,         64,64,64,64,0x00,0x00,0xFF,0},  //blue
    {GN_E,          480-64,         320-64-10,         64,64,64,64,0x00,0x00,0xFF,0},  //blue
    {GN_F,          480-64,         320-64-10,         64,64,64,64,0x00,0x00,0xFF,0}  //blue    
};

t_touch_area virtual_stick_iphone_portrait[VSTICK_NB_BUTTON]={
    {GN_START,      270,         0,               48,48,32,32,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,195,         0,               48,48,32,32,0xDF,0xDF,0x3F,0},
    {GN_MENU_KEY,     0,            0,            48,48,32,32,0x4F,0xFF,0x1F,0},
    {GN_TURBO,        75,            0,           48,48,32,32,0xFF,0xFF,0x2F,0},
    {GN_A,          320-64-10-64,   480-2*64-6-0,   64,64,64,64,0xFF,0x00,0x00,0},  //red
    {GN_B,          320-64,         480-2*64-6-10,   64,64,64,64,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          320-64-10-64,   480-64-0,         64,64,64,64,0x00,0xFF,0x00,0},  //green
    {GN_D,          320-64,         480-64-10,         64,64,64,64,0x00,0x00,0xFF,0},  //blue
    {GN_E,          320-64,         480-64-10,         64,64,64,64,0x00,0x00,0xFF,0},  //blue
    {GN_F,          320-64,         480-64-10,         64,64,64,64,0x00,0x00,0xFF,0}  //blue        
};


t_touch_area virtual_stick_ipad_landscape[VSTICK_NB_BUTTON]={
    {GN_START,      1024-80,        0,              64,64,64,64,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,1024-80,        100,            64,64,64,64,0xDF,0xDF,0xDF,0},
    {GN_MENU_KEY,     0,            0,              64,64,64,64,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        0,            100,            64,64,64,64,0xFF,0x7F,0xFF,0},
    {GN_A,          1024-96*2-10,   768-96*2-6,    96,96,96,96,0xFF,0x00,0x00,0},  //red
    {GN_B,          1024-96,        768-96*2-6-20,    96,96,96,96,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          1024-96*2-10,   768-96,         96,96,96,96,0x00,0xFF,0x00,0},  //green
    {GN_D,          1024-96,        768-96-20,         96,96,96,96,0x00,0x00,0xFF,0},  //blue
    {GN_E,          1024-96,        768-96-20,         96,96,96,96,0x00,0x00,0xFF,0},  //blue
    {GN_F,          1024-96,        768-96-20,         96,96,96,96,0x00,0x00,0xFF,0}  //blue
};

t_touch_area virtual_stick_ipad_portrait[VSTICK_NB_BUTTON]={
    {GN_START,      768-80,        0,             64,64,64,64,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,768-80-120,    0,             64,64,64,64,0xDF,0xDF,0xDF,0},
    {GN_MENU_KEY,     0,           0,             64,64,64,64,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        120,         0,             64,64,64,64,0xFF,0x7F,0xFF,0},
    {GN_A,          768-96*2-20,   1024-96*2-6-60,    96,96,96,96,0xFF,0x00,0x00,0},  //red
    {GN_B,          768-96,        1024-96*2-6-20-60,    96,96,96,96,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          768-96*2-20,   1024-96-60,         96,96,96,96,0x00,0xFF,0x00,0},  //green
    {GN_D,          768-96,        1024-96-20-60,         96,96,96,96,0x00,0x00,0xFF,0},  //blue
    {GN_E,          768-96,        1024-96-20-60,         96,96,96,96,0x00,0x00,0xFF,0},  //blue
    {GN_F,          768-96,        1024-96-20-60,         96,96,96,96,0x00,0x00,0xFF,0}  //blue
};


int gTurboMode;

static uint vpad_button_texture,vpad_dpad_texture;

char gameName[64];
int launchGame;

volatile int emuThread_running;

static GLfloat vertices[5][2];  /* Holds Float Info For 4 Sets Of Vertices */
static GLfloat texcoords[5][2]; /* Holds Float Info For 4 Sets Of Texture coordinates. */

static void *context; //hack to call objective C func from C

@implementation EmuViewController

@synthesize control;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Emu", @"Emu");
        //self.tabBarItem.image = [UIImage imageNamed:@"Emu"];
        launchGame=0;        
        
        //WIIMOTE
        // create discovery controller
        //discoveryView = [[BTDiscoveryViewController alloc] init];
        //[discoveryView setDelegate:self];
        //[self.view addSubview:discoveryView.view];
        //    discoveryView.view.hidden=TRUE;
        // BTstack
        bt = [BTstackManager sharedInstance];
        if (bt) {
            [bt setDelegate:self];
            [bt addListener:self];
            //[bt addListener:discoveryView];
            if (ifba_conf.btstack_on) [bt activate];
        }
        
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (uint) loadTexture:(UIImage*)uiimage {
	CGImage* image = uiimage.CGImage;
	assert(image != NULL);
	const int width = CGImageGetWidth(image);
	const int height = CGImageGetHeight(image);
	const int dataSize = width * height * 4;
	uint handle;
	
	uint8_t* textureData = (uint8_t*)malloc(dataSize);
    if (!textureData) {
        NSLog(@"Error: cannot allocate texture");
    }
    memset(textureData,0,dataSize);
	CGContext* textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image);
	CGContextRelease(textureContext);
	
    
	glGenTextures(1, &handle);
	glBindTexture(GL_TEXTURE_2D, handle);
	
	glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);//TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
	
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST));
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glBindTexture(GL_TEXTURE_2D, 0);
	
	free(textureData);
	return handle;
}


#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    context=self;
    
	// Do any additional setup after loading the view, typically from a nib.
    m_oglView=(OGLView*)(self.view);
    
    mScaleFactor=1.0f;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		mDeviceType=1; //ipad
		mDevice_hh=1024;
		mDevice_ww=768;
	}
	else {
		
		mDeviceType=0; //iphone   (iphone 4 res currently not handled)
		mDevice_hh=480;
		mDevice_ww=320;
		UIScreen* mainscr = [UIScreen mainScreen];
		if ([mainscr respondsToSelector:@selector(currentMode)]) {
			if (mainscr.currentMode.size.width>480) {  //iphone 4
				mDeviceType=2;
				mScaleFactor=1;//(float)mainscr.currentMode.size.width/480.0f;
                
				// mDevice_ww = mainscr.currentMode.size.width;
				// mDevice_hh = mainscr.currentMode.size.height;
			}
		}
		
	}
    
    m_oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	[EAGLContext setCurrentContext:m_oglContext];
	[m_oglView initialize:m_oglContext scaleFactor:mScaleFactor];
    
    //create texture
    glGenTextures(1, &txt_vbuffer);               /* Create 1 Texture */
    glBindTexture(GL_TEXTURE_2D, txt_vbuffer);    /* Bind The Texture */
	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST));
    
	glBindTexture(GL_TEXTURE_2D, 0);
    
    /************************************/
    /* init texture for vpad */
    
    // a,b,c,d buttons
    vpad_dpad_texture=[self loadTexture:[UIImage imageNamed:@"dpad.png"]];
    vpad_button_texture=[self loadTexture:[UIImage imageNamed:@"button.png"]];
    vpad_button_nb=VPAD_SPECIALS_BUTTON_NB; //0button by default. Activated when scanned by emu
    /**************************************/
    
    
    vbuffer=(unsigned short*)malloc(TEXTURE_W*TEXTURE_H*2);
    if (!vbuffer) {
        NSLog(@"Critical issue: vbuffer cannot be allocated");
    }
    memset(vbuffer,0,TEXTURE_W*TEXTURE_H*2);
    vid_rotated=0;
    vid_aspectX=4;
    vid_aspectY=3;
    virtual_stick_on=1;
    visible_area_w=480;
    visible_area_h=320;
    
    for (int i=0;i<MAX_JOYSTICKS;i++) {
        joy_analog_x[i]=0;
        joy_analog_y[i]=0;
        joy_analog_l[i]=0;
        joy_analog_r[i]=0;
    }
    
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden=YES;    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if (bt&&ifba_conf.btstack_on) {
        stopWiimoteDetection();
    }
    
    //
    for (int i=0;i<num_of_joys;i++) {
        wm_joy_pl[i]=wm_prev_joy_pl[i]=0;
    }
    joy_state[0][GN_MENU_KEY]=0;
    
    //icade map
    memset(joymap_dir_iCade,0,sizeof(joymap_dir_iCade));
    for (int i=0;i<10;i++) {
        int j=joymap_iCade[i].dev_btn;
        if (j) {
            switch (i) {
                case 0:joymap_dir_iCade[j-1]=GN_START;break;
                case 1:joymap_dir_iCade[j-1]=GN_SELECT_COIN;break;
                case 2:joymap_dir_iCade[j-1]=GN_MENU_KEY;break;
                case 3:joymap_dir_iCade[j-1]=GN_TURBO;break;
                case 4:joymap_dir_iCade[j-1]=GN_A;break;
                case 5:joymap_dir_iCade[j-1]=GN_B;break;
                case 6:joymap_dir_iCade[j-1]=GN_C;break;
                case 7:joymap_dir_iCade[j-1]=GN_D;break;
                case 8:joymap_dir_iCade[j-1]=GN_E;break;
                case 9:joymap_dir_iCade[j-1]=GN_F;break;                    
            }
        }
    }
    
    //ICADE
    control = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:control];
    control.active = YES;
    control.delegate = self;
    [control release];    

    
    
    int cur_width=m_oglView.frame.size.width;
    int cur_height=m_oglView.frame.size.height;
    
    if (device_isIpad) {
        virtual_stick=(cur_width>cur_height?virtual_stick_ipad_landscape:virtual_stick_ipad_portrait);
        computeButtonLayout(64,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,cur_width,cur_height);
    } else {
        virtual_stick=(cur_width>cur_height?virtual_stick_iphone_landscape:virtual_stick_iphone_portrait);
        computeButtonLayout(48,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,cur_width,cur_height);
    }
    virtual_stick_pad=0;
    joy_analog_x[0]=0;joy_analog_y[0]=0;
    joy_state[0][GN_UP]=0;
    joy_state[0][GN_DOWN]=0;
    joy_state[0][GN_LEFT]=0;
    joy_state[0][GN_RIGHT]=0;
    joy_state[0][GN_UPRIGHT]=0;
    joy_state[0][GN_DOWNRIGHT]=0;
    joy_state[0][GN_UPLEFT]=0;
    joy_state[0][GN_DOWNLEFT]=0;
    for (int i=0;i<VSTICK_NB_BUTTON;i++)  {
        virtual_stick[i].finger_id=0;
        joy_state[0][virtual_stick[i].button_id]=0;
    }
    
}

- (void)viewDidAppear:(BOOL)animated {    
    [super viewDidAppear:animated];
    
    //If resuming
    if (nShouldExit==2) {
        //launch new game ?
        if (launchGame) {//yes, exit current one                                    
            nShouldExit=1;
            while (emuThread_running) {
                [NSThread sleepForTimeInterval:0.01]; //10ms        
            }
            [NSThread sleepForTimeInterval:0.1]; //100ms        
        } else {//no, only resume
            nShouldExit=0;
        }
    }
    //If required launch game / emuthread
    if (launchGame) {    
        nShouldExit=0;    
        pb_value=0;
        pb_total=0;
        pb_msg[0]=0;
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"LOADGAME-%s",gameName]];
        [NSThread detachNewThreadSelector:@selector(emuThread) toTarget:self withObject:NULL];
        launchGame=0;
    }
    
    //update ogl framebuffer
    [m_oglView didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    mNewGLFrame=1;
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doFrame)];
    m_displayLink.frameInterval = 1; //60fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];    
    if (m_displayLink) [m_displayLink invalidate];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    if (nShouldExit==1) {
        while (emuThread_running) {
            [NSThread sleepForTimeInterval:0.01]; //10ms        
        }
    }
    if (bt&&ifba_conf.btstack_on) {
        startWiimoteDetection();        
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ((interfaceOrientation==UIInterfaceOrientationPortrait)||(interfaceOrientation==UIInterfaceOrientationPortraitUpsideDown)) {
        m_oglView.frame=CGRectMake(0,0,mDevice_ww,mDevice_hh);        
        
        /*        if (device_isIpad) {
         virtual_stick=virtual_stick_ipad_portrait;
         computeButtonLayout(96,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,mDevice_ww,mDevice_hh);            
         } else {
         virtual_stick=virtual_stick_iphone_portrait;
         computeButtonLayout(48,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,mDevice_ww,mDevice_hh);
         }
         */
    } else {
        m_oglView.frame=CGRectMake(0,0,mDevice_hh,mDevice_ww);
        
        /*        if (device_isIpad) {
         virtual_stick=virtual_stick_ipad_landscape;
         computeButtonLayout(96,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,mDevice_hh,mDevice_ww);                
         } else {
         virtual_stick=virtual_stick_iphone_landscape;
         computeButtonLayout(48,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,mDevice_hh,mDevice_ww);            
         }
         */ 
    }
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [m_oglView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/

- (void)setICadeState:(BOOL)state forButton:(iCadeState)button {
    virtual_stick_on=0;
    switch (button) {
        case iCadeButtonA:
            joy_state[0][joymap_dir_iCade[0]]=state;
            break;
        case iCadeButtonB:
            joy_state[0][joymap_dir_iCade[1]]=state;
            break;
        case iCadeButtonC:
            joy_state[0][joymap_dir_iCade[2]]=state;
            break;
        case iCadeButtonD:
            joy_state[0][joymap_dir_iCade[3]]=state;
            break;
        case iCadeButtonE:
            joy_state[0][joymap_dir_iCade[4]]=state;
            break;
        case iCadeButtonF:
            joy_state[0][joymap_dir_iCade[5]]=state;
            break;
        case iCadeButtonG:
            joy_state[0][joymap_dir_iCade[6]]=state;
            break;
        case iCadeButtonH:
            joy_state[0][joymap_dir_iCade[7]]=state;
            break;
        case iCadeJoystickUp:
            joy_state[0][GN_UP]=state;
            break;
        case iCadeJoystickRight:
            joy_state[0][GN_RIGHT]=state;
            break;
        case iCadeJoystickDown:
            joy_state[0][GN_DOWN]=state;
            break;
        case iCadeJoystickLeft:
            joy_state[0][GN_LEFT]=state;
            break;            
        default:
            break;
    }
}

- (void)buttonDown:(iCadeState)button {
    [self setICadeState:YES forButton:button];
}

- (void)buttonUp:(iCadeState)button {
    [self setICadeState:NO forButton:button];    
}

/****************************************************/
/****************************************************/
/*        BTSTACK / WIIMOTE                         */
/****************************************************/
/****************************************************/

void updateWiimotes(void) {
    //Wiimotes update
    for (int i=0;i<num_of_joys;i++) {
        if (wm_joy_pl[i]=iOS_wiimote_check(&(joys[i]))) virtual_stick_on=0;
        if (wm_joy_pl[i]!=wm_prev_joy_pl[i]) {
            wm_prev_joy_pl[i]=wm_joy_pl[i];
            
            joy_state[i][GN_UP]=(wm_joy_pl[i]&WII_JOY_UP?1:0);
            joy_state[i][GN_DOWN]=(wm_joy_pl[i]&WII_JOY_DOWN?1:0);
            joy_state[i][GN_LEFT]=(wm_joy_pl[i]&WII_JOY_LEFT?1:0);
            joy_state[i][GN_RIGHT]=(wm_joy_pl[i]&WII_JOY_RIGHT?1:0);
            joy_state[i][GN_A]=(wm_joy_pl[i]&WII_JOY_A?1:0);
            joy_state[i][GN_B]=(wm_joy_pl[i]&WII_JOY_B?1:0);
            joy_state[i][GN_C]=(wm_joy_pl[i]&WII_JOY_C?1:0);
            joy_state[i][GN_D]=(wm_joy_pl[i]&WII_JOY_D?1:0);
            joy_state[i][GN_SELECT_COIN]=(wm_joy_pl[i]&WII_JOY_SELECT?1:0);
            joy_state[i][GN_START]=(wm_joy_pl[i]&WII_JOY_START?1:0);
            joy_state[i][GN_MENU_KEY]=(wm_joy_pl[i]&WII_JOY_HOME?1:0);
            joy_state[i][GN_TURBO]=(wm_joy_pl[i]&WII_JOY_E?1:0);
        }
    }
    
    if (joy_state[0][GN_MENU_KEY]) nShouldExit=2;
    bAppDoFast=joy_state[0][GN_TURBO];
}

void startWiimoteDetection(void) {
    //    NSLog(@"Looking for wiimote");
    
    BTstackManager * bt = [BTstackManager sharedInstance];
    if (bt) {BTstackError err = [bt activate];
        if (err) NSLog(@"activate err 0x%02x!", err);
    }
}

void stopWiimoteDetection(void) {
    // NSLog(@"Stop looking for wiimote");
    BTstackManager * bt = [BTstackManager sharedInstance];
	if (bt) [bt stopDiscovery];
}


-(void) activatedBTstackManager:(BTstackManager*) manager {
    //	NSLog(@"activated!");
	[[BTstackManager sharedInstance] startDiscovery];
}

-(void) btstackManager:(BTstackManager*)manager deviceInfo:(BTDevice*)newDevice {
    //	NSLog(@"Device Info: addr %@ name %@ COD 0x%06x", [newDevice addressString], [newDevice name], [newDevice classOfDevice] ); 
	if ([newDevice name] && [[newDevice name] caseInsensitiveCompare:@"Nintendo RVL-CNT-01"] == NSOrderedSame){
        //		NSLog(@"WiiMote found with address %@", [newDevice addressString]);
		device = newDevice;
		[[BTstackManager sharedInstance] stopDiscovery];
	}
}

-(void) discoveryStoppedBTstackManager:(BTstackManager*) manager {
    //	NSLog(@"discoveryStopped!");
	// connect to device
	if (device) bt_send_cmd(&l2cap_create_channel, [device address], 0x13);
}


// direct access
-(void) btstackManager:(BTstackManager*) manager
  handlePacketWithType:(uint8_t) packet_type
			forChannel:(uint16_t) channel
			   andData:(uint8_t *)packet
			   withLen:(uint16_t) size
{
	bd_addr_t event_addr;
	
    switch (packet_type) {
            
        case L2CAP_DATA_PACKET://0x06
        {
            struct wiimote_t *wm = NULL; 
            
            wm = wiimote_get_by_source_cid(channel);
            
            if(wm!=NULL)
            {
                
                byte* msg = packet + 2;
                byte event = packet[1];
                
                switch (event) {
                    case WM_RPT_BTN:
                    {
                        /* button */
                        wiimote_pressed_buttons(wm, msg);
                        break;
                    }
                    case WM_RPT_READ:
                    {
                        /* data read */
                        
                        if(WIIMOTE_DBG)printf("WM_RPT_READ data arrive!\n");
                        
                        wiimote_pressed_buttons(wm, msg);
                        
                        byte err = msg[2] & 0x0F;
                        
                        if (err == 0x08)
                            printf("Unable to read data - address does not exist.\n");
                        else if (err == 0x07)
                            printf("Unable to read data - address is for write-only registers.\n");
                        else if (err)
                            printf("Unable to read data - unknown error code %x.\n", err);
                        
                        unsigned short offset = BIG_ENDIAN_SHORT(*(unsigned short*)(msg + 3));
                        
                        byte len = ((msg[2] & 0xF0) >> 4) + 1;
                        
                        byte *data = (msg + 5);
                        
                        if(WIIMOTE_DBG)
                        {
                            int i = 0;
                            printf("Read: 0x%04x ; ",offset);
                            for (; i < len; ++i)
                                printf("%x ", data[i]);
                            printf("\n");
                        }
                        
                        if(wiimote_handshake(wm,WM_RPT_READ,data,len))
                        {
                            //btUsed = 1;                                                    
                            //                            [inqViewControl showConnected:nil];
                            //                            [inqViewControl showConnecting:nil];
                            //Create UIAlertView alert
                            //                            [inqViewControl showConnecting:nil];
                            
                            /*                            UIAlertView* alert = 
                             [[UIAlertView alloc] initWithTitle:@"Connection detected!"
                             message: [NSString stringWithFormat:@"%@ '%@' connection sucessfully completed!",
                             (wm->exp.type != EXP_NONE ? @"Classic Controller" : @"WiiMote"),
                             [NSNumber numberWithInt:(wm->unid)+1]]        
                             delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                             [alert show];                                           
                             //[alert dismissWithClickedButtonIndex:0 animated:TRUE];                                           
                             [alert release];
                             */
                            if(device!=nil)
                            {
                                [device setConnectionState:kBluetoothConnectionConnected];
                                device = nil;
                            }
                            [[BTstackManager sharedInstance] startDiscovery];
                        }										
                        
                        return;
                    }
                    case WM_RPT_CTRL_STATUS:
                    {
                        wiimote_pressed_buttons(wm, msg);
                        
                        /* find the battery level and normalize between 0 and 1 */
                        if(WIIMOTE_DBG)
                        {
                            wm->battery_level = (msg[5] / (float)WM_MAX_BATTERY_CODE);
                            
                            printf("BATTERY LEVEL %d\n", wm->battery_level);
                        }
                        
                        //handshake stuff!
                        if(wiimote_handshake(wm,WM_RPT_CTRL_STATUS,msg,-1))
                        {
                            //btUsed = 1;                                                    
                            //                            [inqViewControl showConnected:nil];
                            //                            [inqViewControl showConnecting:nil];
                            /*                            UIAlertView* alert = 
                             [[UIAlertView alloc] initWithTitle:@"Connection detected!"
                             message: [NSString stringWithFormat:@"WiiMote '%@' connection sucessfully completed!",[NSNumber numberWithInt:(wm->unid)+1]]        
                             delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                             [alert show];                                           
                             //[alert dismissWithClickedButtonIndex:0 animated:TRUE];                                           
                             [alert release];*/
                            [device setConnectionState:kBluetoothConnectionConnected];
                            
                            if(device!=nil)
                            {
                                [device setConnectionState:kBluetoothConnectionConnected];
                                device = nil;
                            }
                            [[BTstackManager sharedInstance] startDiscovery];
                        }
                        
                        return;
                    }
                    case WM_RPT_BTN_EXP:
                    {
                        /* button - expansion */
                        wiimote_pressed_buttons(wm, msg);
                        wiimote_handle_expansion(wm, msg+2);
                        
                        break;
                    }
                    case WM_RPT_WRITE:
                    {
                        /* write feedback - safe to skip */
                        break;
                    }
                    default:
                    {
                        printf("Unknown event, can not handle it [Code 0x%x].", event);
                        return;
                    }
                }                   
            }                                                                 
            break;
        }
        case HCI_EVENT_PACKET://0x04
        {
            switch (packet[0]){
                    
                case L2CAP_EVENT_CHANNEL_OPENED:
                    
                    // data: event (8), len(8), status (8), address(48), handle (16), psm (16), local_cid(16), remote_cid (16)                                         
                    if (packet[2] == 0) {
                        
                        // inform about new l2cap connection
                        bt_flip_addr(event_addr, &packet[3]);
                        uint16_t psm = READ_BT_16(packet, 11);
                        uint16_t source_cid = READ_BT_16(packet, 13);
                        wiiMoteConHandle = READ_BT_16(packet, 9);
                        //                        NSLog(@"Channel successfully opened: handle 0x%02x, psm 0x%02x, source cid 0x%02x, dest cid 0x%02x", wiiMoteConHandle, psm, source_cid,  READ_BT_16(packet, 15));
                        
                        if (psm == 0x13) {
                            
                            // interupt channel openedn succesfully, now open control channel, too.
                            if(WIIMOTE_DBG)printf("open control channel\n");
                            bt_send_cmd(&l2cap_create_channel, event_addr, 0x11);
                            struct wiimote_t *wm = NULL;  
                            wm = &joys[num_of_joys];
                            memset(wm, 0, sizeof(struct wiimote_t));
                            wm->unid = num_of_joys;                                                        
                            wm->i_source_cid = source_cid;
                            memcpy(&wm->addr,&event_addr,BD_ADDR_LEN);
                            if(WIIMOTE_DBG)printf("addr %02x:%02x:%02x:%02x:%02x:%02x\n", wm->addr[0], wm->addr[1], wm->addr[2],wm->addr[3], wm->addr[4], wm->addr[5]);                                                    
                            if(WIIMOTE_DBG)printf("saved 0x%02x  0x%02x\n",source_cid,wm->i_source_cid);
                            wm->exp.type = EXP_NONE;
                            
                        } else {
                            
                            //inicializamos el wiimote!   
                            struct wiimote_t *wm = NULL;  
                            wm = &joys[num_of_joys];                                                                                                                                                                  
                            wm->wiiMoteConHandle = wiiMoteConHandle; 
                            wm->c_source_cid = source_cid;                                                           
                            wm->state = WIIMOTE_STATE_CONNECTED;
                            num_of_joys++;
                            if(WIIMOTE_DBG)printf("Devices Number: %d\n",num_of_joys);
                            wiimote_handshake(wm,-1,NULL,-1);                                                                                                                                                                                                                                                                      
                        }
                    }
                    break;
                case L2CAP_EVENT_CHANNEL_CLOSED:
                {                                
                    // data: event (8), len(8), channel (16)                                                                                       
                    uint16_t  source_cid = READ_BT_16(packet, 2);                                              
                    //NSLog(@"Channel successfully closed: cid 0x%02x",source_cid);
                    
                    bd_addr_t addr;
                    int unid = wiimote_remove(source_cid,&addr);
                    if(unid!=-1)
                    {
                        //                        [inqViewControl removeDeviceForAddress:&addr];
                        UIAlertView* alert = 
                        [[UIAlertView alloc] initWithTitle:@"Disconnection!"
                                                   message:[NSString stringWithFormat:@"WiiMote '%@' disconnection detected.\nIs battery drainned?",[NSNumber numberWithInt:(unid+1)]] 
                                                  delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                        [alert show];                                           
                        
                        [alert release];
                    }
                    
                }
                    break;                                        
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
	
}

//******************************************

-(void) emuThread {
    emuThread_running=1;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    int argc=2;
    char *argv[2];
    argv[0]=(char*)malloc(5);
    if (!argv[0]) {
        NSLog(@"Error: cannot allocate argv[0]");
    }
    sprintf(argv[0],"%s","iFBA");
    argv[1]=(char*)malloc(strlen(gameName)+1);
    if (!argv[1]) {
        NSLog(@"Error: cannot allocate argv[1]");
    }
    sprintf(argv[1],"%s",gameName);
    fba_main(argc,(char**)argv);
    free (argv[0]);
    free (argv[1]);
    
    [pool release];
    emuThread_running=0;
}

int vstick_update_status(int rx,int ry) {
    float angle;
    //compute distance    
    //    printf("%d %d / %d %d\n",rx,ry,virtual_stick_posx,virtual_stick_posy);
    float dist=(rx-virtual_stick_posx)*(rx-virtual_stick_posx)+(ry-virtual_stick_posy)*(ry-virtual_stick_posy);
    
    
    virtual_stick_pad=0; //Reset pad state
    joy_analog_x[0]=0;joy_analog_y[0]=0;
    if ((dist>virtual_stick_mindist2)&&(dist<virtual_stick_maxdist2)) {
        //compute angle
        //        float rdist=sqrtf(dist);
        float dx=rx-virtual_stick_posx;
        float dy=-ry+virtual_stick_posy;
        if (dx!=0) {
            
            angle=atanf(dy/dx);
            if ((dx>=0)&&(dy>=0)) { //TOP RIGHT
                
            } else if ((dx<=0)&&(dy>=0)) { //TOP LEFT
                angle=M_PI+angle;
            } else if ((dx<=0)&&(dy<=0)) { //BOTTOM LEFT
                angle=M_PI+angle;
            } else if ((dx>=0)&&(dy<=0)) { //BOTTOM RIGHT
                angle=M_PI*2+angle;
            }
        } else {
            if (dy>0) angle=M_PI/2;
            else angle=M_PI*3/2;
        }        
        virtual_stick_angle=angle;
        
        joy_analog_x[0]=dx*2/virtual_stick_maxdist;
        joy_analog_y[0]=dy*2/virtual_stick_maxdist;
        
        if ( ((virtual_stick_angle<M_PI*2)&&(virtual_stick_angle>=M_PI*2-M_PI/8))||((virtual_stick_angle<M_PI/8)&&(virtual_stick_angle>=0))) { //Right
            virtual_stick_pad=GN_RIGHT;
        } else if ((virtual_stick_angle>=-M_PI/8+M_PI/4)&&(virtual_stick_angle<M_PI/8+M_PI/4)) { //Up&Right
            virtual_stick_pad=GN_UPRIGHT;
        } else if ((virtual_stick_angle>=-M_PI/8+2*M_PI/4)&&(virtual_stick_angle<M_PI/8+2*M_PI/4)) { //Up
            virtual_stick_pad=GN_UP;
        } else if ((virtual_stick_angle>=-M_PI/8+3*M_PI/4)&&(virtual_stick_angle<M_PI/8+3*M_PI/4)) { //Up&Left
            virtual_stick_pad=GN_UPLEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+4*M_PI/4)&&(virtual_stick_angle<M_PI/8+4*M_PI/4)) { //Left
            virtual_stick_pad=GN_LEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+5*M_PI/4)&&(virtual_stick_angle<M_PI/8+5*M_PI/4)) { //Left&Down
            virtual_stick_pad=GN_DOWNLEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+6*M_PI/4)&&(virtual_stick_angle<M_PI/8+6*M_PI/4)) { //Down
            virtual_stick_pad=GN_DOWN;
        } else if ((virtual_stick_angle>=-M_PI/8+7*M_PI/4)&&(virtual_stick_angle<M_PI/8+7*M_PI/4)) { //Down&Right
            virtual_stick_pad=GN_DOWNRIGHT;
        }
        //    printf("angle: %f pad:%02X\n",angle*180/M_PI,virtual_stick_pad);
    }
    
    return virtual_stick_pad;
}


void ios_fingerEvent(long touch_id, int evt_type, float x, float y) {
    //printf("touch %08X, type %d, %f x %f\n",touch_id,evt_type,x,y);
    switch (evt_type) {
        case 1: //Pressed            
            virtual_stick_on=1;
            if (vstick_update_status(x,y)) { //finger is on pad
                joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
                virtual_stick_padfinger=touch_id;
            } else { //check if finger is on a button
                for (int i=0;i<vpad_button_nb;i++) {
                    if ((x>virtual_stick[i].x)&&(x<virtual_stick[i].x+virtual_stick[i].w)&&
                        (y>virtual_stick[i].y)&&(y<virtual_stick[i].y+virtual_stick[i].h)){
                        joy_state[0][virtual_stick[i].button_id]=1;
                        virtual_stick[i].finger_id=touch_id;
                        break;
                    }
                }       
            }
            
            break;
        case 2: //Moved
            virtual_stick_on=1;
            if (touch_id==virtual_stick_padfinger) { //is it the finger on pad
                if (vstick_update_status(x,y)==0) {
                    virtual_stick_padfinger=0;
                    joy_analog_x[0]=0;joy_analog_y[0]=0;
                }
                joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
            } else if (virtual_stick_padfinger==0) {
                if (vstick_update_status(x,y)) virtual_stick_padfinger=touch_id;
                joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
            }
            
            for (int i=0;i<vpad_button_nb;i++) {                    
                //is there a button already pressed with this finger ?
                if (virtual_stick[i].finger_id==touch_id) {
                    //a button was pressed and finger moved
                    //check if finger is still in button area
                    if ((x>virtual_stick[i].x)&&(x<virtual_stick[i].x+virtual_stick[i].w)&&
                        (y>virtual_stick[i].y)&&(y<virtual_stick[i].y+virtual_stick[i].h)){
                        break;
                    } else {
                        //button not pressed anymore
                        //do not break to check if finger moved to a new button
                        virtual_stick[i].finger_id=0;
                        joy_state[0][virtual_stick[i].button_id]=0;                            
                    }
                } else {
                    //did the finger move to a new button area ?
                    if ((x>virtual_stick[i].x)&&(x<virtual_stick[i].x+virtual_stick[i].w)&&
                        (y>virtual_stick[i].y)&&(y<virtual_stick[i].y+virtual_stick[i].h)){
                        joy_state[0][virtual_stick[i].button_id]=1;
                        virtual_stick[i].finger_id=touch_id;
                    }
                }
            }
            
            break;
        case 0: //Release
            virtual_stick_on=1;
            if (virtual_stick_padfinger==touch_id) {
                virtual_stick_pad=0;
                joy_analog_x[0]=0;joy_analog_y[0]=0;
                joy_state[0][GN_UP]=0;
                joy_state[0][GN_DOWN]=0;
                joy_state[0][GN_LEFT]=0;
                joy_state[0][GN_RIGHT]=0;
                joy_state[0][GN_UPRIGHT]=0;
                joy_state[0][GN_DOWNRIGHT]=0;
                joy_state[0][GN_UPLEFT]=0;
                joy_state[0][GN_DOWNLEFT]=0;
            } 
            
            
            for (int i=0;i<VSTICK_NB_BUTTON;i++) 
                if (virtual_stick[i].finger_id==touch_id) {
                    virtual_stick[i].finger_id=0;
                    joy_state[0][virtual_stick[i].button_id]=0;
                    break;
                }
            break;
    }
    
    if (joy_state[0][GN_MENU_KEY]) nShouldExit=2;
    bAppDoFast=joy_state[0][GN_TURBO];
}



void updateVbuffer(unsigned short *buff,int w,int h,int pitch,int rotated,int nXAspect,int nYAspect) {
    vid_rotated=rotated;
    visible_area_w=w; 
    if (visible_area_w>TEXTURE_W) {
        NSLog(@"ERROR: width is too large (%d/%d)",visible_area_w,TEXTURE_W);
    }
    if (visible_area_h>TEXTURE_H) {
        NSLog(@"ERROR: width is too large (%d/%d)",visible_area_h,TEXTURE_H);
    }
    visible_area_h=h;
    vid_aspectX=nXAspect;
    vid_aspectY=nYAspect;
    pitch>>=1;
    unsigned short *src,*dst;
    src=buff;
    dst=vbuffer;
    for (int y=0;y<h;y++) {
        memcpy(dst,src,w<<1);
        dst+=TEXTURE_W;
        src+=pitch;
        //for (int x=0;x<w;x++) {
        //vbuffer[y*TEXTURE_W+x]=buff[y*pitch+x];
        //}    
    }
    mNewGLFrame++;
}


- (void)drawVPad {
    int cur_width=m_oglView.frame.size.width;
    int cur_height=m_oglView.frame.size.height;
    
    if (device_isIpad) {
        virtual_stick=(cur_width>cur_height?virtual_stick_ipad_landscape:virtual_stick_ipad_portrait);        
        computeButtonLayout(ifba_conf.vpad_btnsize*16+64,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,cur_width,cur_height);
    } else {
        virtual_stick=(cur_width>cur_height?virtual_stick_iphone_landscape:virtual_stick_iphone_portrait);
        computeButtonLayout(ifba_conf.vpad_btnsize*16+48,vpad_button_nb-VPAD_SPECIALS_BUTTON_NB,cur_width,cur_height);
    }
    
    
    virtual_stick_buttons_alpha=32*ifba_conf.vpad_alpha;
    virtual_stick_buttons_alpha2=64*ifba_conf.vpad_alpha;
    if (virtual_stick_buttons_alpha>255) virtual_stick_buttons_alpha=255;
    if (virtual_stick_buttons_alpha2>255) virtual_stick_buttons_alpha2=255;
    
    if (ifba_conf.vpad_padsize==0) virtual_stick_maxdist=64;
    else if (ifba_conf.vpad_padsize==1) virtual_stick_maxdist=80;
    else if (ifba_conf.vpad_padsize==2) virtual_stick_maxdist=96;
    
    switch (cur_height) {
        case 320:
            virtual_stick_posx = virtual_stick_maxdist;
            virtual_stick_posy = cur_height-virtual_stick_maxdist;
            break;
        case 480:
            virtual_stick_posx = virtual_stick_maxdist;
            virtual_stick_posy = cur_height-virtual_stick_maxdist-0;
            break;    
        case 768:
            virtual_stick_posx = virtual_stick_maxdist+40;
            virtual_stick_posy = cur_height-virtual_stick_maxdist-40;
            break;
        case 1024:
            virtual_stick_posx = virtual_stick_maxdist;
            virtual_stick_posy = cur_height-virtual_stick_maxdist-80;
            break;
        default:
            virtual_stick_posx = virtual_stick_maxdist;
            virtual_stick_posy = cur_height-virtual_stick_maxdist;
            break;
    }    
    virtual_stick_maxdist2=virtual_stick_maxdist*virtual_stick_maxdist;
    virtual_stick_mindist2=virtual_stick_mindist*virtual_stick_mindist;
    
    //update viewport to match real device screen
    
    glViewport(0, 0, cur_width, cur_height);                        
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);            
    /* Enable Vertex Pointer */
    texcoords[0][0]=0; texcoords[0][1]=0;
    texcoords[1][0]=1; texcoords[1][1]=0;
    texcoords[2][0]=0; texcoords[2][1]=1;
    texcoords[3][0]=1; texcoords[3][1]=1;
    
    glBindTexture(GL_TEXTURE_2D, vpad_button_texture);    /* Bind The Texture */    
    for (int i=(ifba_conf.vpad_showSpecial?0:VPAD_SPECIALS_BUTTON_NB);i<vpad_button_nb;i++) {            
        vertices[0][0]=(float)(virtual_stick[i].x+((virtual_stick[i].w-virtual_stick[i].sw)>>1))/cur_width;
        vertices[0][1]=(float)(virtual_stick[i].y+((virtual_stick[i].h-virtual_stick[i].sh)>>1))/cur_height;
        
        vertices[1][0]=vertices[0][0]+(float)(virtual_stick[i].sw)/cur_width;
        vertices[1][1]=(float)(virtual_stick[i].y+((virtual_stick[i].h-virtual_stick[i].sh)>>1))/cur_height;
        
        vertices[2][0]=(float)(virtual_stick[i].x+((virtual_stick[i].w-virtual_stick[i].sw)>>1))/cur_width;
        vertices[2][1]=vertices[0][1]+(float)(virtual_stick[i].sh)/cur_height;
        
        vertices[3][0]=vertices[0][0]+(float)(virtual_stick[i].sw)/cur_width;
        vertices[3][1]=vertices[0][1]+(float)(virtual_stick[i].sh)/cur_height;
        
        vertices[0][0]=vertices[0][0]*2-1;
        vertices[1][0]=vertices[1][0]*2-1;
        vertices[2][0]=vertices[2][0]*2-1;
        vertices[3][0]=vertices[3][0]*2-1;
        vertices[0][1]=-vertices[0][1]*2+1;
        vertices[1][1]=-vertices[1][1]*2+1;
        vertices[2][1]=-vertices[2][1]*2+1;
        vertices[3][1]=-vertices[3][1]*2+1;
        
        if (virtual_stick[i].finger_id) glColor4ub(virtual_stick[i].r,virtual_stick[i].g,virtual_stick[i].b,virtual_stick_buttons_alpha2);
        else glColor4ub(virtual_stick[i].r,virtual_stick[i].g,virtual_stick[i].b,virtual_stick_buttons_alpha);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    //now the stick
    glBindTexture(GL_TEXTURE_2D, vpad_dpad_texture);    /* Bind The Texture */
    vertices[0][0]=(float)(virtual_stick_posx-virtual_stick_maxdist)/cur_width;
    vertices[0][1]=(float)(virtual_stick_posy+virtual_stick_maxdist)/cur_height;            
    vertices[1][0]=(float)(virtual_stick_posx+virtual_stick_maxdist)/cur_width;;
    vertices[1][1]=(float)(virtual_stick_posy+virtual_stick_maxdist)/cur_height;            
    vertices[2][0]=(float)(virtual_stick_posx-virtual_stick_maxdist)/cur_width;
    vertices[2][1]=(float)(virtual_stick_posy-virtual_stick_maxdist)/cur_height;            
    vertices[3][0]=(float)(virtual_stick_posx+virtual_stick_maxdist)/cur_width;
    vertices[3][1]=(float)(virtual_stick_posy-virtual_stick_maxdist)/cur_height;
    
    vertices[0][0]=vertices[0][0]*2-1;
    vertices[1][0]=vertices[1][0]*2-1;
    vertices[2][0]=vertices[2][0]*2-1;
    vertices[3][0]=vertices[3][0]*2-1;
    vertices[0][1]=-vertices[0][1]*2+1;
    vertices[1][1]=-vertices[1][1]*2+1;
    vertices[2][1]=-vertices[2][1]*2+1;
    vertices[3][1]=-vertices[3][1]*2+1;
    glColor4ub(250,245,255,virtual_stick_buttons_alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_TEXTURE_2D);
    for (int i=0;i<4;i++) {
        vertices[0][0]=(float)(virtual_stick_posx+0.9f*virtual_stick_maxdist*cosf(i*M_PI/2))/cur_width;
        vertices[0][1]=(float)(virtual_stick_posy-0.9f*virtual_stick_maxdist*sinf(i*M_PI/2))/cur_height;
        
        vertices[1][0]=(float)(virtual_stick_posx+0.6f*virtual_stick_maxdist*cosf(i*M_PI/2+M_PI/8))/cur_width;
        vertices[1][1]=(float)(virtual_stick_posy-0.6f*virtual_stick_maxdist*sinf(i*M_PI/2+M_PI/8))/cur_height;
        
        vertices[2][0]=(float)(virtual_stick_posx+0.6f*virtual_stick_maxdist*cosf(i*M_PI/2-M_PI/8))/cur_width;
        vertices[2][1]=(float)(virtual_stick_posy-0.6f*virtual_stick_maxdist*sinf(i*M_PI/2-M_PI/8))/cur_height;
        
        vertices[0][0]=vertices[0][0]*2-1;
        vertices[1][0]=vertices[1][0]*2-1;
        vertices[2][0]=vertices[2][0]*2-1;
        vertices[0][1]=-vertices[0][1]*2+1;
        vertices[1][1]=-vertices[1][1]*2+1;
        vertices[2][1]=-vertices[2][1]*2+1;
        
        
        if (virtual_stick_pad) {
            if (((virtual_stick_pad-1)>>1==i)||((((virtual_stick_pad)>>1)&3)==i)) glColor4ub(250,245,255,virtual_stick_buttons_alpha2);
            else glColor4ub(250,245,255,virtual_stick_buttons_alpha);
        } else glColor4ub(250,245,255,virtual_stick_buttons_alpha);
        
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
    }                
    glDisable(GL_BLEND);        
}

int ErrorWhileLoading(const char* pszText) {
    int strHeight=1;
    int i=0;
    while (pszText[i]) {
        if (pszText[i]<32) strHeight++;
        i++;
    }
    DrawRect((uint16 *) vbuffer, 20, 20, visible_area_w-40, 9*strHeight+10, 0x00FFA0A0, TEXTURE_W,vid_rotated);
    DrawRect((uint16 *) vbuffer, 21, 21, visible_area_w-42, 9*strHeight+8, 0x00EF2020, TEXTURE_W,vid_rotated);
	
	DrawString (pszText, (uint16 *) vbuffer, 22, 24, TEXTURE_W,vid_rotated);
    
    mNewGLFrame++;
    usleep(3000000); //3s
}

int ProgressUpdateBurner(int nLen,int totalLen, const char* pszText) {
    
    pb_total+=nLen;
    if (totalLen) {
        if (pb_total>totalLen) pb_total=totalLen;
        pb_value=(float)pb_total/(float)totalLen;
    } else {
        pb_total=0;
        pb_value=1;
    }
    
	DrawRect((uint16 *) vbuffer, 20, 100, visible_area_w-40, 20, 0x00A0A0FF, TEXTURE_W,vid_rotated);
    DrawRect((uint16 *) vbuffer, 21, 101, visible_area_w-42, 18, 0x002020EF, TEXTURE_W,vid_rotated);
	
	if (pszText)
		DrawString (pszText, (uint16 *) vbuffer, 22, 104, TEXTURE_W,vid_rotated);
	
	if (totalLen == 0) {
		DrawRect((uint16 *) vbuffer, 20, 120, visible_area_w-40, 12, 0x00FFFFFF, TEXTURE_W,vid_rotated);
		DrawRect((uint16 *) vbuffer, 21, 121, visible_area_w-42, 10, 0x00808080, TEXTURE_W,vid_rotated);
	} else {
        DrawRect((uint16 *) vbuffer, 20, 120, visible_area_w-40, 12, 0x00A0A0FF, TEXTURE_W,vid_rotated);
        DrawRect((uint16 *) vbuffer, 21, 121, visible_area_w-42, 10, 0x002020EF, TEXTURE_W,vid_rotated);
		DrawRect((uint16 *) vbuffer, 22, 122, pb_value * (visible_area_w-44), 8, 0x00AFFF3F, TEXTURE_W,vid_rotated);
	}
    
    mNewGLFrame++;
	return 0;
}

int StopProgressBar() {
    pb_value=1;
    mNewGLFrame++;
}

-(void) loopCheck {
    
}


- (void)doFrame {
    int width,height,rw,rh;
    
    if (nShouldExit) {
        self.navigationController.navigationBar.hidden=NO;        
        [[self navigationController] popViewControllerAnimated:NO];
    }
    
    //New frame to draw?
    if (!mNewGLFrame) return;
    //todo: how many was there?
    mNewGLFrame=0;
    
    //get ogl context & bind
    
    
    [EAGLContext setCurrentContext:m_oglContext];
	[m_oglView bind];
    
    
    width=m_oglView.frame.size.width;
    height=m_oglView.frame.size.height;
    
    /*********************/
    /*Handle input*/
    /*********************/
    /**********************************/
    /* Redraw */
    /**********************************/
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, txt_vbuffer);    /* Bind The Texture */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (ifba_conf.filtering?GL_LINEAR:GL_NEAREST));
    
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, TEXTURE_W, TEXTURE_H, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, vbuffer);
    
    /* Begin Drawing Quads, setup vertex and texcoord array pointers */
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    
    /* Enable Vertex Pointer */
    glEnableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glColor4ub(255,255,255,255);
    
    if (vid_rotated&&(pb_value==1)) {
        texcoords[1][0]=(float)0/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
        texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)0/TEXTURE_H;
        texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)(visible_area_h)/TEXTURE_H;
        texcoords[2][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
    } else {
        texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)0/TEXTURE_H;
        texcoords[1][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
        texcoords[2][0]=(float)0/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
        texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)(visible_area_h)/TEXTURE_H;
        
    }
    float ios_aspect=(float)width/(float)height;
    float game_aspect=(float)vid_aspectX/(float)vid_aspectY;        
    
    switch (ifba_conf.screen_mode) {
        case 0://org
            if (ios_aspect>game_aspect) {
                rh=min(height,visible_area_h);
                rw=rh*(ifba_conf.aspect_ratio?game_aspect:ios_aspect);
                
            } else {
                rw=min(width,visible_area_w);
                rh=rw/(ifba_conf.aspect_ratio?game_aspect:ios_aspect);
                
            }
            break;
        case 1://max with room for vpad
            if (ios_aspect>game_aspect) {                    
                rh=height-virtual_stick_maxdist*(device_isIpad?2.5f:1.1f);
                rw=rh*(ifba_conf.aspect_ratio?game_aspect:ios_aspect);                    
            } else {
                rw=width-virtual_stick_maxdist*(device_isIpad?2.5f:1.1f)*vid_aspectX/vid_aspectY;
                rh=rw/(ifba_conf.aspect_ratio?game_aspect:ios_aspect);
            }
            break;
        case 2://full
            if (ios_aspect>game_aspect) {
                rh=height;
                rw=rh*(ifba_conf.aspect_ratio?game_aspect:ios_aspect);
                
            } else {
                rw=width;
                rh=rw/(ifba_conf.aspect_ratio?game_aspect:ios_aspect);
            }
            break;
    }
    
    glViewport((width-rw)>>1, height-rh, rw, rh);                    
    if (vid_rotated&&(pb_value==1)) {
        vertices[0][0]=1; vertices[0][1]=-1;
        vertices[1][0]=-1; vertices[1][1]=-1;
        vertices[2][0]=1; vertices[2][1]=1;
        vertices[3][0]=-1; vertices[3][1]=1;
    } else {
        vertices[0][0]=-1; vertices[0][1]=1;
        vertices[1][0]=1; vertices[1][1]=1;
        vertices[2][0]=-1; vertices[2][1]=-1;
        vertices[3][0]=1; vertices[3][1]=-1;    
    }
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if (virtual_stick_on) [self drawVPad];
    
    [m_oglContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

@end
