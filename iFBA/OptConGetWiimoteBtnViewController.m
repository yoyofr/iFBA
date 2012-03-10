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
}

-(void) checkWiimote {
    int pressedBtn=iOS_wiimote_check(&(joys[wiimoteSelected]));
    if (pressedBtn) {
        if (pressedBtn&WII_JOY_A) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_A;
        else if (pressedBtn&WII_JOY_B) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_B;
        else if (pressedBtn&WII_JOY_C) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_C;
        else if (pressedBtn&WII_JOY_D) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_D;
        else if (pressedBtn&WII_JOY_E) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_E;
        else if (pressedBtn&WII_JOY_F) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_F;
        else if (pressedBtn&WII_JOY_G) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_G;
        else if (pressedBtn&WII_JOY_H) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_H;
        else if (pressedBtn&WII_JOY_START) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_SELECT;
        else if (pressedBtn&WII_JOY_SELECT) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_START;
        else if (pressedBtn&WII_JOY_HOME) joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=WII_BUTTON_HOME;
        
        //remove older assignment (if exist)
        for (int i=0;i<VSTICK_NB_BUTTON;i++) {
            if ((i!=mOptWiimoteButtonSelected)&&(joymap_wiimote[wiimoteSelected][i].dev_btn==joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn)) joymap_wiimote[wiimoteSelected][i].dev_btn=0;
        }
        [self dismissSemiModalViewController:self];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    wiimoteBtnPress=0;
    wiimoteBtnAllPress=0;

    
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 1; //60fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
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
    joymap_wiimote[wiimoteSelected][mOptWiimoteButtonSelected].dev_btn=0;
    wiimoteBtnPress=0;
    [self dismissSemiModalViewController:self];
}

@end
