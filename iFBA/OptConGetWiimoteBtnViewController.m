//
//  OptConGetWiimoteBtnViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptConGetWiimoteBtnViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"
#include "wiimote.h"

int wiimoteBtnPress;
static int wiimoteBtnAllPress;
extern int mOptWiimoteButtonSelected;
extern int wiimoteSelected;

@implementation OptConGetWiimoteBtnViewController
@synthesize mnview;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[mnview layer] setCornerRadius:15.0];	
	[[mnview layer] setBorderWidth:3.0];
	[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
}

-(void) checkWiimote {
    int pressedBtn=iOS_wiimote_check(&(joys[wiimoteSelected]));
    if (pressedBtn) {
        if (pressedBtn&WII_JOY_A) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_A;
        else if (pressedBtn&WII_JOY_B) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_B;
        else if (pressedBtn&WII_JOY_C) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_C;
        else if (pressedBtn&WII_JOY_D) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_D;
        else if (pressedBtn&WII_JOY_E) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_E;
        else if (pressedBtn&WII_JOY_F) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_F;
        else if (pressedBtn&WII_JOY_G) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_G;
        else if (pressedBtn&WII_JOY_H) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_H;
        else if (pressedBtn&WII_JOY_START) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_START;
        else if (pressedBtn&WII_JOY_SELECT) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_SELECT;
        else if (pressedBtn&WII_JOY_HOME) cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_HOME;
        
        //remove older assignment (if exist)
        for (int i=0;i<VSTICK_NB_BUTTON;i++) {
            if ((i!=mOptWiimoteButtonSelected)&&(cur_ifba_conf->joymap_wiimote[wiimoteSelected][i].dev_btn==cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn)) cur_ifba_conf->joymap_wiimote[wiimoteSelected][i].dev_btn=0;
        }
        [self dismissSemiModalViewController:self];
    }
}

static int viewWA_patch=0;

-(void) viewWillAppear:(BOOL)animated {
    if (viewWA_patch) return;
    viewWA_patch++;
    [super viewWillAppear:animated];
    wiimoteBtnPress=0;
    wiimoteBtnAllPress=0;
    
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
}

-(void) viewWillDisappear:(BOOL)animated {
    if (!viewWA_patch) return;
    viewWA_patch--;
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


/****************************************************/
/****************************************************/
/*        WIIMOTE                                   */
/****************************************************/
/****************************************************/

#pragma mark UI action
-(IBAction) cancelInput {
    wiimoteBtnPress=0;
    [self dismissSemiModalViewController:self];
}
-(IBAction) clearInput {
    cur_ifba_conf->joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=0;
    wiimoteBtnPress=0;
    [self dismissSemiModalViewController:self];
}

@end
