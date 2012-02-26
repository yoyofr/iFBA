//
//  EmuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "inp_sdl_keys.h"
unsigned char joy_state[4][GN_MAX_KEY];

#import "EmuViewController.h"
#include "string.h"

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
unsigned char virtual_stick_buttons_alpha=64;
unsigned char virtual_stick_buttons_alpha2=128;
int virtual_stick_on;
long virtual_stick_padfinger;

int virtual_stick_pad;
int virtual_stick_posx=70;
int virtual_stick_posy=320-70;
int virtual_stick_maxdist=70;
int virtual_stick_mindist=16;
int virtual_stick_maxdist2=70*70;
int virtual_stick_mindist2=16*16;
int vpad_button_nb=4;
float virtual_stick_angle;
typedef struct {int button_id,x,y,w,h;unsigned char r,g,b;long finger_id;} t_touch_area;
t_touch_area virtual_stick_iphone_landscape[VSTICK_NB_BUTTON]={
    {GN_START,      480-48,         0,              48,48,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,480-48,         48,             48,48,0x8F,0x8F,0x8F,0},
    {GN_MENU_KEY,     0,            0,              48,48,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        0,            48,             48,48,0xFF,0x7F,0xFF,0},
    {GN_A,          480-64-10-64,   320-64-6-64,   64,64,0xFF,0x00,0x00,0},  //red
    {GN_B,          480-64,         320-64-6-64-10,   64,64,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          480-64-10-64,   320-64,         64,64,0x00,0xFF,0x00,0},  //green
    {GN_D,          480-64,         320-64-10,         64,64,0x00,0x00,0xFF,0},  //blue
    {GN_E,          480-64,         320-64-10,         64,64,0x00,0x00,0xFF,0},  //blue
    {GN_F,          480-64,         320-64-10,         64,64,0x00,0x00,0xFF,0}  //blue    
};

t_touch_area virtual_stick_iphone_portrait[VSTICK_NB_BUTTON]={
    {GN_START,      270,         0,               48,48,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,195,         0,               48,48,0x8F,0x8F,0x8F,0},
    {GN_MENU_KEY,     0,            0,            48,48,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        75,            0,           48,48,0xFF,0x7F,0xFF,0},
    {GN_A,          320-64-10-64,   480-2*64-6-20,   64,64,0xFF,0x00,0x00,0},  //red
    {GN_B,          320-64,         480-2*64-6-30,   64,64,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          320-64-10-64,   480-64-20,         64,64,0x00,0xFF,0x00,0},  //green
    {GN_D,          320-64,         480-64-30,         64,64,0x00,0x00,0xFF,0},  //blue
    {GN_E,          320-64,         480-64-30,         64,64,0x00,0x00,0xFF,0},  //blue
    {GN_F,          320-64,         480-64-30,         64,64,0x00,0x00,0xFF,0}  //blue        
};


t_touch_area virtual_stick_ipad_landscape[VSTICK_NB_BUTTON]={
    {GN_START,      1024-80,        0,              64,64,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,1024-80,        100,            64,64,0x8F,0x8F,0x8F,0},
    {GN_MENU_KEY,     0,            0,              64,64,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        0,            100,            64,64,0xFF,0x7F,0xFF,0},
    {GN_A,          1024-96*2-10,   768-96*2-6,    96,96,0xFF,0x00,0x00,0},  //red
    {GN_B,          1024-96,        768-96*2-6-20,    96,96,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          1024-96*2-10,   768-96,         96,96,0x00,0xFF,0x00,0},  //green
    {GN_D,          1024-96,        768-96-20,         96,96,0x00,0x00,0xFF,0},  //blue
    {GN_E,          1024-96,        768-96-20,         96,96,0x00,0x00,0xFF,0},  //blue
    {GN_F,          1024-96,        768-96-20,         96,96,0x00,0x00,0xFF,0}  //blue
};

t_touch_area virtual_stick_ipad_portrait[VSTICK_NB_BUTTON]={
    {GN_START,      768-80,        600,             64,64,0xFF,0xFF,0xFF,0},
    {GN_SELECT_COIN,768-80-120,    600,             64,64,0x8F,0x8F,0x8F,0},
    {GN_MENU_KEY,     0,           600,             64,64,0xEF,0xFF,0x7F,0},
    {GN_TURBO,        120,         600,             64,64,0xFF,0x7F,0xFF,0},
    {GN_A,          768-96*2-20,   1024-96*2-6-60,    96,96,0xFF,0x00,0x00,0},  //red
    {GN_B,          768-96,        1024-96*2-6-20-60,    96,96,0xFF,0xFF,0x00,0},  //yellow
    {GN_C,          768-96*2-20,   1024-96-60,         96,96,0x00,0xFF,0x00,0},  //green
    {GN_D,          768-96,        1024-96-20-60,         96,96,0x00,0x00,0xFF,0},  //blue
    {GN_E,          768-96,        1024-96-20-60,         96,96,0x00,0x00,0xFF,0},  //blue
    {GN_F,          768-96,        1024-96-20-60,         96,96,0x00,0x00,0xFF,0}  //blue
};

t_touch_area *virtual_stick=virtual_stick_iphone_portrait;
int gTurboMode;

static uint vpad_button_texture,vpad_dpad_texture;

char gameName[64];
int launchGame;

volatile int emuThread_running;

static GLfloat vertices[5][2];  /* Holds Float Info For 4 Sets Of Vertices */
static GLfloat texcoords[5][2]; /* Holds Float Info For 4 Sets Of Texture coordinates. */

@implementation EmuViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Emu", @"Emu");
        //self.tabBarItem.image = [UIImage imageNamed:@"Emu"];
        launchGame=0;        
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
    memset(textureData,0,dataSize);
	CGContext* textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image);
	CGContextRelease(textureContext);
	
    
	glGenTextures(1, &handle);
	glBindTexture(GL_TEXTURE_2D, handle);
	
	glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);//TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
	
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glBindTexture(GL_TEXTURE_2D, 0);
	
	free(textureData);
	return handle;
}


#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
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
				mScaleFactor=(float)mainscr.currentMode.size.width/480.0f;
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
	
    if (1) {
        glTexParameterx(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterx(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	} else {
        glTexParameterx(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterx(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	    
    }
	glBindTexture(GL_TEXTURE_2D, 0);
    
    /************************************/
    /* init texture for vpad */
    
    // a,b,c,d buttons
    vpad_dpad_texture=[self loadTexture:[UIImage imageNamed:@"dpad.png"]];
    vpad_button_texture=[self loadTexture:[UIImage imageNamed:@"button.png"]];
    vpad_button_nb=4; //0button by default. Activated when scanned by emu
    /**************************************/
    
    
    vbuffer=(unsigned short*)malloc(TEXTURE_W*TEXTURE_H*2);
    visible_area_w=480;
    visible_area_h=320;
    vid_rotated=0;
    vid_aspectX=4;
    vid_aspectY=3;
    virtual_stick_on=1;
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
    
    //
    joy_state[0][GN_MENU_KEY]=0;
    
    //Setup opengl & activate frame update
	[EAGLContext setCurrentContext:m_oglContext];	
    [m_oglView bind];
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doFrame)];
    m_displayLink.frameInterval = 1;
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    //If resuming
    if (nShouldExit==2) {
        //launch new game ?
        if (launchGame) {//yes, exit current one
            nShouldExit=1;
            while (emuThread_running) {
                [NSThread sleepForTimeInterval:0.01]; //10ms        
            }
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
        [NSThread detachNewThreadSelector:@selector(emuThread) toTarget:self withObject:NULL];
        launchGame=0;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];    
    if (m_displayLink) [m_displayLink invalidate];
    
    if (nShouldExit==1) {
    while (emuThread_running) {
        [NSThread sleepForTimeInterval:0.01]; //10ms        
    }
    }
    self.navigationController.navigationBar.hidden = NO;    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ((interfaceOrientation==UIInterfaceOrientationPortrait)||(interfaceOrientation==UIInterfaceOrientationPortraitUpsideDown)) {
        m_oglView.frame=CGRectMake(0,0,mDevice_ww,mDevice_hh);
    } else {
        m_oglView.frame=CGRectMake(0,0,mDevice_hh,mDevice_ww);
    }
    return YES;
}
//******************************************
extern int fba_main( int argc, char **argv );

-(void) emuThread {
    emuThread_running=1;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    /* Set working directory to resource path */
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: documentsDirectory];
    
    int argc=2;
    char *argv[2];
    argv[0]=(char*)malloc(5);
    sprintf(argv[0],"%s","iFBA");
    argv[1]=(char*)malloc(strlen(gameName)+1);
    sprintf(argv[1],"%s",gameName);
    fba_main(argc,(char**)argv);
    
    [pool release];
    emuThread_running=0;
}

int vstick_update_status(int rx,int ry) {
    float angle;
    //compute distance    
    //    printf("%d %d / %d %d\n",rx,ry,virtual_stick_posx,virtual_stick_posy);
    float dist=(rx-virtual_stick_posx)*(rx-virtual_stick_posx)+(ry-virtual_stick_posy)*(ry-virtual_stick_posy);
    
    
    virtual_stick_pad=0; //Reset pad state
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
                if (vstick_update_status(x,y)==0) virtual_stick_padfinger=0;
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
}

void updateVbuffer(unsigned short *buff,int w,int h,int pitch,int rotated,int nXAspect,int nYAspect) {
    vid_rotated=rotated;
    visible_area_w=w;
    visible_area_h=h;
    vid_aspectX=nXAspect;
    vid_aspectY=nYAspect;
    pitch>>=1;
    for (int y=0;y<h;y++) 
        for (int x=0;x<w;x++) {
            vbuffer[y*TEXTURE_W+x]=buff[y*pitch+x];
        }    
}


- (void)drawVPad {
    int cur_width=m_oglView.frame.size.width;
    int cur_height=m_oglView.frame.size.height;
    
    if (device_isIpad) {
        if (cur_width>cur_height) virtual_stick=virtual_stick_ipad_landscape;
        else virtual_stick=virtual_stick_ipad_portrait;
    } else {
        if (cur_width>cur_height) virtual_stick=virtual_stick_iphone_landscape;
        else virtual_stick=virtual_stick_iphone_portrait;
    }
    
        switch (cur_height) {
            case 320:
                virtual_stick_posx = virtual_stick_maxdist;
                virtual_stick_posy = cur_height-virtual_stick_maxdist;
                virtual_stick_buttons_alpha=64;
                virtual_stick_buttons_alpha2=128;
                break;
            case 480:
                virtual_stick_posx = virtual_stick_maxdist;
                virtual_stick_posy = cur_height-virtual_stick_maxdist-20;
                virtual_stick_buttons_alpha=64;
                virtual_stick_buttons_alpha2=128;
                break;    
            case 768:
                virtual_stick_posx = virtual_stick_maxdist;
                virtual_stick_posy = cur_height-virtual_stick_maxdist;
                virtual_stick_buttons_alpha=64;
                virtual_stick_buttons_alpha2=128;
                break;
            case 1024:
                virtual_stick_posx = virtual_stick_maxdist;
                virtual_stick_posy = cur_height-virtual_stick_maxdist-80;
                virtual_stick_buttons_alpha=64;
                virtual_stick_buttons_alpha2=128;
                break;
            default:
                virtual_stick_posx = virtual_stick_maxdist;
                virtual_stick_posy = cur_height-virtual_stick_maxdist;
                virtual_stick_buttons_alpha=64;
                virtual_stick_buttons_alpha2=128;
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
        for (int i=0;i<vpad_button_nb;i++) {            
            vertices[0][0]=(float)(virtual_stick[i].x)/cur_width;
            vertices[0][1]=(float)(virtual_stick[i].y)/cur_height;
            
            vertices[1][0]=vertices[0][0]+(float)(virtual_stick[i].w)/cur_width;
            vertices[1][1]=(float)(virtual_stick[i].y)/cur_height;
            
            vertices[2][0]=(float)(virtual_stick[i].x)/cur_width;
            vertices[2][1]=vertices[0][1]+(float)(virtual_stick[i].h)/cur_height;
            
            vertices[3][0]=vertices[0][0]+(float)(virtual_stick[i].w)/cur_width;
            vertices[3][1]=vertices[0][1]+(float)(virtual_stick[i].h)/cur_height;
            
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

int ProgressUpdateBurner(int nLen,int totalLen, const char* pszText) {
    
    pb_total+=nLen;
    if (totalLen) pb_value=(float)pb_total/(float)totalLen;
    else pb_value=1;
    strcpy(pb_msg,pszText);
    
    //printf("%f %d %d %d %s",pb_value,pb_total,nLen,totalLen,pszText);
	return 0;
}

int StopProgressBar() {
    pb_value=1;
}


- (void)doFrame {
    int width,height,rw,rh;
    //get ogl context & bind
    
    if (nShouldExit) {
        [[self navigationController] popViewControllerAnimated:YES];
        return;
    }
    
	[EAGLContext setCurrentContext:m_oglContext];
	[m_oglView bind];
    
    width=m_oglView.frame.size.width;
    height=m_oglView.frame.size.height;
    
    /*********************/
    /*Handle input*/
    /*********************/
    if (m_oglView->m_touchcount) { 
		m_oglView->currentTouchLocation.x;
        m_oglView->currentTouchLocation.y;
    }
    /**********************************/
    /* Redraw */
    /**********************************/
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, txt_vbuffer);    /* Bind The Texture */
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, TEXTURE_W, TEXTURE_H, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, vbuffer);
    
    /* Begin Drawing Quads, setup vertex and texcoord array pointers */
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    
    /* Enable Vertex Pointer */
    glEnableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glColor4ub(255,255,255,255);
    
    if (vid_rotated) {
        texcoords[1][0]=(float)0/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
        texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)0/TEXTURE_H;
        texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)(visible_area_h)/TEXTURE_H;
        texcoords[2][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
        float ios_aspect=(float)width/(float)height;
        float game_aspect=(float)vid_aspectX/(float)vid_aspectY;        
        if (ios_aspect>game_aspect) {
            rh=height;
            rw=rh*vid_aspectX/vid_aspectY;
            glViewport((width-rw)>>1, 0, rw, rh);
        } else {
            rw=width;
            rh=rw*vid_aspectY/vid_aspectX;
            glViewport(0, height-rh, rw, rh);
        }            
        
        
        vertices[0][0]=1; vertices[0][1]=-1;
        vertices[1][0]=-1; vertices[1][1]=-1;
        vertices[2][0]=1; vertices[2][1]=1;
        vertices[3][0]=-1; vertices[3][1]=1;
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    } else {
        texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)0/TEXTURE_H;
        texcoords[1][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
        texcoords[2][0]=(float)0/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
        texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)(visible_area_h)/TEXTURE_H;
        float ios_aspect=(float)width/(float)height;
        float game_aspect=(float)vid_aspectX/(float)vid_aspectY;        
        if (ios_aspect>game_aspect) {
            rh=height;
            rw=rh*vid_aspectX/vid_aspectY;
            glViewport((width-rw)>>1, 0, rw, rh);
        } else {
            rw=width;
            rh=rw*vid_aspectY/vid_aspectX;
            glViewport(0, height-rh, rw, rh);
        }            
        
        vertices[0][0]=-1; vertices[0][1]=1;
        vertices[1][0]=1; vertices[1][1]=1;
        vertices[2][0]=-1; vertices[2][1]=-1;
        vertices[3][0]=1; vertices[3][1]=-1;
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    if (virtual_stick_on) [self drawVPad];
    
    if (pb_value<1) {        
        glViewport(0,0,width,height);
        glDisable(GL_TEXTURE_2D);
        
        glColor4ub(255,255,255,255);
        vertices[0][0]=-0.5; vertices[0][1]=0.1;
        vertices[1][0]=-0.5+pb_value; vertices[1][1]=0.1;
        vertices[2][0]=-0.5; vertices[2][1]=-0.1;
        vertices[3][0]=-0.5+pb_value; vertices[3][1]=-0.1;
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glColor4ub(255/2,255/2,255/2,255);
        vertices[0][0]=-0.5+pb_value; vertices[0][1]=0.1;
        vertices[1][0]=0.5; vertices[1][1]=0.1;
        vertices[2][0]=-0.5+pb_value; vertices[2][1]=-0.1;
        vertices[3][0]=0.5; vertices[3][1]=-0.1;
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
	
    [m_oglContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

@end
