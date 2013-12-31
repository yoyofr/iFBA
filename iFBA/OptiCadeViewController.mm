//
//  OptiCadeViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptiCadeViewController.h"
#import "BTstack/BTstackManager.h"
#import "BTstack/BTDiscoveryViewController.h"
#import "BTstackManager.h"
#import "OptiCadeMapViewController.h"
#import "fbaconf.h"

char iCade_langStr[MAX_LANG][32]={
    "English",
    "Français"
};
int mOptICadeButtonSelected;
int mOptICadeCurrentJoystick;
extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];
extern int optionScope;

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;


@implementation OptiCadeViewController
@synthesize tabView,btn_backToEmu,emuvc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"iCade/iMpulse",@"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //
    // Change the properties of the imageView and tableView (these could be set
    // in interface builder instead).
    //
    //self.tabView.style=UITableViewStyleGrouped;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
        iCaderv.active = YES;
        iCaderv.delegate = self;
        [iCaderv becomeFirstResponder];
    
    BTstackManager *bt = [BTstackManager sharedInstance];
    if (ifba_conf.btstack_on&&bt) {
        UIAlertView *aboutMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:NSLocalizedString(@"Warning iCade BTStack",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
        [aboutMsg show];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


//static int viewWA_patch=0;

- (void)viewWillAppear:(BOOL)animated {
//    if (viewWA_patch) return;
//    viewWA_patch++;
    [super viewWillAppear:animated];
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];


    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
}
-(void)viewWillDisappear:(BOOL)animated {
//    if (!viewWA_patch) return;
//    viewWA_patch--;
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
    
    [[[UIApplication sharedApplication] delegate] saveSettings];
    if (game_has_options) { //settings already loaded, ensure any modification are saved
        [[[UIApplication sharedApplication] delegate] saveSettings:[NSString stringWithFormat:@"%s",gameName]];
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (optionScope==0)	return 4;
    else return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (optionScope==0) {
        if (section==2) return 2;//MAX_JOYSTICKS;
    return 1;
    } else {
        if (section==1) return 2;//MAX_JOYSTICKS;
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    if (optionScope==0) {
    switch (section) {
        case 0://Language
            footer=NSLocalizedString(@"iCade Language",@"");
            break;
        case 1://iCade/iMpulse mode
            footer=NSLocalizedString(@"iCade/iMpulse switch (iMpulse mode required for 2 players)",@"");
            break;
        case 2://Mapping
            footer=NSLocalizedString(@"Mapping info",@"");
            break;
        case 3://Reset to Default
            footer=@"";
            break;
    }
    } else {
        switch (section) {
            case 0://iCade/iMpulse mode
                footer=NSLocalizedString(@"iCade/iMpulse switch (iMpulse mode required for 2 players)",@"");
                break;                
            case 1://Mapping
                footer=NSLocalizedString(@"Mapping info",@"");
                break;
            case 2://Reset to Default
                footer=@"";
                break;
        }
    }
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *lblview;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    cell.accessoryType=UITableViewCellAccessoryNone;
    if (optionScope==0) {
    switch (indexPath.section) {
        case 0://Reset to default
            cell.textLabel.text=[NSString stringWithFormat:@"%@%@",NSLocalizedString(@"System keyboard: ",@""),[NSString stringWithCString:iCade_langStr[ifba_conf.icade_lang] encoding:NSUTF8StringEncoding]];
            cell.textLabel.textAlignment=UITextAlignmentLeft;
            cell.accessoryView=nil;
            break;
        case 1://iCade/iMpulse switch
            cell.textLabel.text=[NSString stringWithFormat:@"Current mode: %s",(cur_ifba_conf->joy_iCadeIMpulse?"Impulse":"iCade")];
            cell.textLabel.textAlignment=UITextAlignmentLeft;
            cell.accessoryView=nil;
            break;
        case 2://Mapping
            cell.textLabel.text=[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"Controller ",@""),indexPath.row+1];
            cell.textLabel.textAlignment=UITextAlignmentLeft;
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 3://Reset to default
            cell.textLabel.text=NSLocalizedString(@"Reset to default",@"");
            cell.textLabel.textAlignment=UITextAlignmentCenter;
            cell.accessoryView=nil;
            break;
    }
    } else {
        switch (indexPath.section) {
            case 0://iCade/iMpulse switch
                cell.textLabel.text=[NSString stringWithFormat:@"%s mode",(cur_ifba_conf->joy_iCadeIMpulse?"Impulse"
                                                                           :"iCade")];
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                cell.accessoryView=nil;
                break;
            case 1://Mapping
                cell.textLabel.text=[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"Controller ",@""),indexPath.row];
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
                break;
            case 2://Reset to default
                cell.textLabel.text=NSLocalizedString(@"Reset to default",@"");
                cell.textLabel.textAlignment=UITextAlignmentCenter;
                cell.accessoryView=nil;
                break;
        }

    }
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (optionScope==0) {
    switch (indexPath.section) {
        case 0:
            ifba_conf.icade_lang++;
            if (ifba_conf.icade_lang==MAX_LANG) ifba_conf.icade_lang=0;
            [tableView reloadData];
            break;
        case 1:
            cur_ifba_conf->joy_iCadeIMpulse^=1;
            [iCaderv changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
            [tableView reloadData];
            break;
        case 2: {
                mOptICadeCurrentJoystick=indexPath.row;
                OptiCadeMapViewController *vc=[[OptiCadeMapViewController alloc] initWithNibName:@"OptiCadeMapViewController" bundle:nil];
                ((OptiCadeMapViewController*)vc)->emuvc=emuvc;
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
            [tabView reloadData];
            break;
        case 3:
            memcpy(cur_ifba_conf->joymap_iCade,default_joymap_iCade,sizeof(default_joymap_iCade));
            [tabView reloadData];            
            break;
    }
    } else {
        switch (indexPath.section) {
            case 0:
                cur_ifba_conf->joy_iCadeIMpulse^=1;
                [iCaderv changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
                [tableView reloadData];
                break;
            case 1:
            {
                mOptICadeCurrentJoystick=indexPath.row;
                OptiCadeMapViewController *vc=[[OptiCadeMapViewController alloc] initWithNibName:@"OptiCadeMapViewController" bundle:nil];
                ((OptiCadeMapViewController*)vc)->emuvc=emuvc;
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
                [tabView reloadData];
                break;
            case 2:
                memcpy(cur_ifba_conf->joymap_iCade,default_joymap_iCade,sizeof(default_joymap_iCade));
                break;
        }
        
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
