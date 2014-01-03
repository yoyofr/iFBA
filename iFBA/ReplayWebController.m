//
//  ReplayWebController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReplayWebController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"
#import "ASIHTTPRequest.h"

extern char gameName[64];
extern char debug_root_path[512];
extern int device_isIpad;

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_current_pos;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;

static int download_ok;

static NSString *replayURL;
static ASIHTTPRequest *request=nil;

@implementation ReplayWebController
@synthesize webview;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    //[[mnview layer] setCornerRadius:15.0];
	//[[mnview layer] setBorderWidth:3.0];
	//[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    //[[txtview layer] setCornerRadius:15.0];	
	//[[txtview layer] setBorderWidth:3.0];
	//[[txtview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    //[[webview layer] setCornerRadius:15.0];
    
    //[[webviewVideo layer] setCornerRadius:15.0];
    
    //[[toolbar layer] setCornerRadius:15.0];
    
    //ICADE & Wiimote
    ui_current_pos=0;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    [iCaderv changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;                    
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];    
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    NSURLRequest *replayReq = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%sgetreplay?game=%s&Device=%s",IFBAONLINE,gameName,(device_isIpad?"iPad":"iPhone")]]];
    [webview setDelegate:self];
    [webview loadRequest:replayReq];
   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
    if (request) {
        //[request cancel];
        request=nil;
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {    
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    [self.mnview setNeedsLayout];
}



static NSString *suggestedFilename;
static long long expectedContentLength;
static int replay_slot[10];
static UIActionSheet *replaySlotMenu;
static UIAlertView *alertYesNo;
static int cancelIndex=0;

extern int glob_replay_currentslot;

int GetReplayInfo(int slot,char *info) {
    FILE *f;
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,slot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,slot);
#endif
    
    NSError *err;
    NSDictionary *finfo;
    finfo=[[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%s",szName] error:&err];
    if (finfo==nil) return -1;
    NSDate *fdate=finfo.fileModificationDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *dateStr=[dateFormatter stringFromDate:fdate];
    
    f=fopen(szName,"rb");
    if (!f) {
        //        NSLog(@"cannot read replay");
        return -1;
    } else {
        char szHeader[7];
        signed int tmpFPS;
        int framecpt,index_max;
        fread(szHeader,6,1,f);
        szHeader[6]=0;
        fread((void*)&framecpt,sizeof(framecpt),1,f);
        fread((void*)&index_max,sizeof(index_max),1,f);
        fread((void*)&tmpFPS,sizeof(tmpFPS),1,f);
        if (index_max>MAX_REPLAY_DATA_BYTES) {
            NSLog(@"Replay file corrupted: wrong max value for replay_index_max");
            fclose(f);
            return -2;
        } else {
            sprintf(info,"%s - %d:%02d",[dateStr UTF8String],framecpt*100/tmpFPS/60,(framecpt*100/tmpFPS)%60,(index_max+18)/1024);
        }
        fclose(f);
    }
    return 0;
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    NSString *returnString=[request responseString];
    //    NSLog(@"%@", returnString);
    download_ok=1;
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Information" message:[NSString stringWithFormat:@"Download successful.",[[request error] localizedDescription]] delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	UIAlertView *alert;
    alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Upload error:\n%@",[[request error] localizedDescription]] delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}


-(void) downloadReplay {
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,glob_replay_currentslot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,glob_replay_currentslot);
#endif
//    NSLog(@"yo %@",replayURL);
    if (request) {
        [request cancel];
        request=nil;
    }
    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:replayURL]];
    [request setDownloadDestinationPath:[NSString stringWithFormat:@"%s",szName]];
    
    download_ok=0;
    [request setDelegate:self];
    [request startAsynchronous];
/*    NSError *error = [request error];
    if (!error) {
        NSLog(@"ok");
    } else NSLog(@"ko: %@",[error localizedDescription]);
    
  */
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView==alertYesNo) {
        if (buttonIndex == 0) {
            // Yes, do something
            [self downloadReplay];
        }
    } else {
        if (download_ok) [self.navigationController popViewControllerAnimated:TRUE];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet==replaySlotMenu) {
        if (buttonIndex<cancelIndex) {
                    glob_replay_currentslot=buttonIndex;
                    if (replay_slot[glob_replay_currentslot]) {
                        alertYesNo=[[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Slot already used, existing replay will be lost. Do you confirm ?"delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil] autorelease];
                        [alertYesNo show];
                    } else {
                        //download
                        [self downloadReplay];
                    }
        }
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSRange r;
	NSString *MIME = response.MIMEType;
	NSString *appDirectory = [[NSBundle mainBundle] bundlePath];
	NSString *pathMIMETYPESplist = [appDirectory stringByAppendingPathComponent:@"MIMETYPES.plist"];
	NSArray *downloadMIMETypes = [NSArray arrayWithContentsOfFile: pathMIMETYPESplist];
	BOOL asdf = [downloadMIMETypes containsObject:MIME];
    
    
    char szTmp[64];
    
//    NSLog(@"Connection : %@",MIME);
	if (asdf==NO) {
        r.location=NSNotFound;
		r=[MIME rangeOfString:@"application/"];
		if (r.location!=NSNotFound) {
            //			NSLog(@"unknown binary content, attempt to download");
            //			NSLog(@"%@",MIME);
			asdf=YES;
		}
	}
	replayURL=[[NSString alloc] initWithString:[[response URL] absoluteString]];
    
	[connection cancel];
    
    if (asdf == YES) {
        
        
        replaySlotMenu=[[UIActionSheet alloc] initWithTitle:@"Select slot" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        
        //check current replay slots
        cancelIndex=0;
        for (int i=0;i<10;i++) {
            if (GetReplayInfo(i,szTmp)==0) {
                replay_slot[i]=1;
                [replaySlotMenu addButtonWithTitle:[NSString stringWithFormat:@"#%d. %s",i,szTmp]];
            }
            else {
                replay_slot[i]=0;
                [replaySlotMenu addButtonWithTitle:[NSString stringWithFormat:@"#%d. Free",i]];
            }
            cancelIndex++;
        }
        [replaySlotMenu addButtonWithTitle:@"Cancel"];
        replaySlotMenu.cancelButtonIndex=cancelIndex;
        [replaySlotMenu showInView:self.view];
        [replaySlotMenu autorelease];
        
        
    }
}

- (BOOL)webView:(UIWebView *)webV shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSRange r;
	NSString *endUrl=[[[request URL] absoluteString] lastPathComponent];
	
    //	NSLog(@"url : %d %@",navigationType,[[request URL] absoluteString]);
	if (endUrl==nil) return FALSE;
	NSURL *url=[request URL];
    
	NSURLConnection *theConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (theConnection==nil) {
    	NSLog(@"Connection failed");
    }
	return YES;
}

#pragma Icade support
/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/
- (void)buttonDown:(iCadeState)button {
    
    
}
- (void)buttonUp:(iCadeState)button {
    if (button&iCadeJoystickDown) {
    } else if (button&iCadeJoystickUp) {
    } else if (button&iCadeJoystickLeft) {
    } else if (button&iCadeJoystickRight) {
    }else if (button&iCadeButtonA) { //validate
        [self.navigationController popViewControllerAnimated:YES];
    } else if (button&iCadeButtonB) { //back
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma Wiimote/iCP support
#define WII_BUTTON_UP(A) (wiimoteBtnState&A)&& !(pressedBtn&A)
-(void) checkWiimote {
    if (num_of_joys==0) return;
    int pressedBtn=iOS_wiimote_check(&(joys[0]));
    
    if (WII_BUTTON_UP(WII_JOY_DOWN)) {
        [self buttonUp:iCadeJoystickDown];
    } else if (WII_BUTTON_UP(WII_JOY_UP)) {
        [self buttonUp:iCadeJoystickUp];
    } else if (WII_BUTTON_UP(WII_JOY_LEFT)) {
        [self buttonUp:iCadeJoystickLeft];
    } else if (WII_BUTTON_UP(WII_JOY_RIGHT)) {
        [self buttonUp:iCadeJoystickRight];
    } else if (WII_BUTTON_UP(WII_JOY_A)) {
        [self buttonUp:iCadeButtonA];
    } else if (WII_BUTTON_UP(WII_JOY_B)) {
        [self buttonUp:iCadeButtonB];
    } else if (WII_BUTTON_UP(WII_JOY_C)) {
        [self buttonUp:iCadeButtonC];
    } else if (WII_BUTTON_UP(WII_JOY_D)) {
        [self buttonUp:iCadeButtonD];
    } else if (WII_BUTTON_UP(WII_JOY_E)) {
        [self buttonUp:iCadeButtonE];
    } else if (WII_BUTTON_UP(WII_JOY_F)) {
        [self buttonUp:iCadeButtonF];
    } else if (WII_BUTTON_UP(WII_JOY_G)) {
        [self buttonUp:iCadeButtonG];
    } else if (WII_BUTTON_UP(WII_JOY_H)) {
        [self buttonUp:iCadeButtonH];
    }
    
    
    wiimoteBtnState=pressedBtn;
}




@end
