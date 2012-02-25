//
//  EmuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmuViewController.h"
#include "string.h"

void updateVbuffer(unsigned short *buff,int w,int h,int pitch);

static unsigned short *vbuffer;
static int visible_area_w,visible_area_h;
static int vid_rotated,vid_aspectX,vid_aspectY;
int nShouldExit;
static GLuint txt_vbuffer;  

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
    
    vbuffer=(unsigned short*)malloc(TEXTURE_W*TEXTURE_H*2);
    visible_area_w=480;
    visible_area_h=320;
    vid_rotated=0;
    vid_aspectX=4;
    vid_aspectY=3;
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

void ios_fingerEvent(long touch_id, int evt_type, float x, float y) {
    switch (evt_type) {
        case 1: //Pressed
            NSLog(@"te: pressed at %f x %f / %08X",x,y,touch_id);
            if ((x<32)&&(y<32)) {
                nShouldExit=2; //pause
            }
            break;
        case 2: //Moved
            NSLog(@"te: moved at %f x %f / %08X",x,y,touch_id);
            break;
        case 0: //Release
            NSLog(@"te: released at %f x %f / %08X",x,y,touch_id);
            break;
    }
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
	
    [m_oglContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

@end
