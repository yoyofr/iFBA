//
//  OptGameInfoViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptGameInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"

static NSMutableArray *genreList;
static int allnone;
static unsigned int newgenreFilter;
static unsigned int newgenreFilter_first=1;
static CAGradientLayer *gradientF,*gradientH;

static char text_link[512];

char gameInfo[64*1024];
char tmp_game_name[64];
extern char gameName[64];

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_current_pos;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;


@implementation OptGameInfoViewController
@synthesize mnview,txtview,webview,webviewVideo;

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
    
    [[mnview layer] setCornerRadius:15.0];	
	[[mnview layer] setBorderWidth:3.0];
	[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    [[txtview layer] setCornerRadius:15.0];	
	//[[txtview layer] setBorderWidth:3.0];
	//[[txtview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    [[webview layer] setCornerRadius:15.0];
    
    [[webviewVideo layer] setCornerRadius:15.0];
    
    [[toolbar layer] setCornerRadius:15.0];
    
    //ICADE & Wiimote
    ui_current_pos=0;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;                    
}

NSString *yt_template = @"<html><head><style type=\"text/css\">body { background-color: transparent;color: white;}</style></head><body style=\"margin:0\"><embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" width=\"%0.0f\" height=\"%0.0f\"></embed></body></html>";

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];    
    
    /*if (gameName[0]) {
        NSString *myStr=[NSString stringWithFormat:@"%s.png",gameName];
        UIImage *myImg=[UIImage imageNamed:myStr];
        if (myImg) txtview.backgroundColor=[UIColor colorWithPatternImage:myImg];
        else txtview.backgroundColor=[UIColor clearColor];
    } else txtview.backgroundColor=[UIColor clearColor];
    */
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    
    memset(text_link,0,512);
    char *link_start=strstr(gameInfo,"http://");
    char *link_end=strstr(gameInfo,"\n");
    if (link_start && link_end) {
        char text_len=link_end-link_start;
        strncpy(text_link,link_start,text_len);
        txtview.text=[NSString stringWithCString:(char*)(link_end+1) encoding:NSUTF8StringEncoding];
    } else {
        txtview.text=[NSString stringWithCString:gameInfo encoding:NSUTF8StringEncoding];
    }
    
    [webview loadHTMLString:[NSString stringWithFormat:@"<html><body><iframe src=""%s""></iframe></body></html>",text_link] baseURL:nil];

    
    
}

- (UIButton *)findButtonInView:(UIView *)view {
    UIButton *button = nil;
    
    if ([view isMemberOfClass:[UIButton class]]) {
        return (UIButton *)view;
    }
    
    if (view.subviews && [view.subviews count] > 0) {
        for (UIView *subview in view.subviews) {
            button = [self findButtonInView:subview];
            if (button) return button;
        }
    }
    
    return button;
}

/*- (void)webViewDidFinishLoad:(UIWebView *)_webView {
    if (_webView==webviewVideo) {
    UIButton *b = [self findButtonInView:_webView];
    [b sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}*/

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
    [self.mnview setNeedsLayout];
}

-(IBAction) showSummary {
    webview.hidden=TRUE;
    webviewVideo.hidden=TRUE;
    txtview.hidden=FALSE;
}
-(IBAction) showArcadehistory {
    webview.hidden=FALSE;
    webviewVideo.hidden=TRUE;
    txtview.hidden=TRUE;
}
-(IBAction) showVideo {
    webviewVideo.hidden=FALSE;
    webview.hidden=TRUE;
    txtview.hidden=TRUE;
//    NSURLRequest *videoReq = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.youtube.com/watch?v=9eFCK7JKfx0&rel=0&showsearch=0&modestbranding=1&showinfo=0"]];
    NSURLRequest *videoReq = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/results?search_query=mame+%s",tmp_game_name]]];
    [webviewVideo setDelegate:self];
    [webviewVideo loadRequest:videoReq];
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
        if (ui_current_pos<txtview.contentSize.height) ui_current_pos+=txtview.frame.size.height*0.9f;
        if (ui_current_pos>=txtview.contentSize.height) ui_current_pos=txtview.contentSize.height;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickUp) {
        if (ui_current_pos>0) ui_current_pos-=txtview.frame.size.height*0.9f;
        if (ui_current_pos<0) ui_current_pos=0;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickLeft) {
        ui_current_pos=0;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickRight) {
        ui_current_pos=txtview.contentSize.height-1;        
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    }else if (button&iCadeButtonA) { //validate            
        [self.navigationController popViewControllerAnimated:YES];            
    } else if (button&iCadeButtonB) { //back
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
