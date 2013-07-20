//
//  OptOptionsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptOptionsViewController.h"
#import "OptVideoViewController.h"
#import "OptControlsViewController.h"
#import "OptEmuViewController.h"
#import "OptAudioViewController.h"

#import "fbaconf.h"
#import "string.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];
extern int optionScope; //0:default, 1:current game

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;


@implementation OptOptionsViewController
@synthesize tabView,btn_backToEmu,emuvc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Options",@"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    //ICADE & Wiimote
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    [iCaderv changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];    
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
    
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (optionScope==1) return 2;
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) return 4;
    if (section==1) return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    if (indexPath.section==0) {
    switch (indexPath.row) {
        case 0:cell.textLabel.text=NSLocalizedString(@"Video",@"");
            break;
        case 1:cell.textLabel.text=NSLocalizedString(@"Audio",@"");
            break;
        case 2:cell.textLabel.text=NSLocalizedString(@"Controllers",@"");
            break;
        case 3:cell.textLabel.text=NSLocalizedString(@"Emulation",@"");
            break;
    }
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textAlignment=UITextAlignmentLeft;
    } else if (indexPath.section==1) {
        cell.textLabel.text=NSLocalizedString(@"Reset to default settings",@"");
        cell.accessoryType=UITableViewCellAccessoryNone;
        cell.textLabel.textAlignment=UITextAlignmentCenter;
    }
    	
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc;
    if (indexPath.section==0) {
    switch (indexPath.row) {
        case 0://video
            vc=[[OptVideoViewController alloc] initWithNibName:@"OptVideoViewController" bundle:nil];
            ((OptVideoViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
        case 1://audio
            vc=[[OptAudioViewController alloc] initWithNibName:@"OptAudioViewController" bundle:nil];
            ((OptAudioViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
        case 2://controllers
            vc=[[OptControlsViewController alloc] initWithNibName:@"OptControlsViewController" bundle:nil];
            ((OptControlsViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
        case 3://emulation
            vc=[[OptEmuViewController alloc] initWithNibName:@"OptEmuViewController" bundle:nil];
            ((OptEmuViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
    }
    } else if (indexPath.section==1) {
        //reset to default value: delete specific settings
        game_has_options=0;
        cur_ifba_conf=(ifba_conf_t*)&ifba_conf;
        [[[UIApplication sharedApplication] delegate] removeSettings:[NSString stringWithFormat:@"%s",gameName]];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(IBAction) backToEmu {
//    launchGame=2;
//    [self.navigationController popToRootViewControllerAnimated:NO];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
    [self.navigationController pushViewController:emuvc animated:NO];

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
    if (ui_currentIndex_s==-1) {
        ui_currentIndex_s=ui_currentIndex_r=0;
    }
    else {
        if (button&iCadeJoystickDown) {            
            if (ui_currentIndex_r<[tabView numberOfRowsInSection:ui_currentIndex_s]-1) ui_currentIndex_r++; //next row
            else { //next section
                if (ui_currentIndex_s<[tabView numberOfSections]-1) {
                    ui_currentIndex_s++;ui_currentIndex_r=0; //next section
                } else {
                    ui_currentIndex_s=ui_currentIndex_r=0; //loop to 1st section
                }
            }             
        } else if (button&iCadeJoystickUp) {
            if (ui_currentIndex_r>0) ui_currentIndex_r--; //prev row            
            else { //prev section
                if (ui_currentIndex_s>0) {
                    ui_currentIndex_s--;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //next section
                } else {
                    ui_currentIndex_s=[tabView numberOfSections]-1;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //loop to 1st section
                }
            }
        } else if (button&iCadeButtonA) { //validate            
            [self tableView:tabView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s]];
            
        } else if (button&iCadeButtonB) { //back
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    [tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}


@end
