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
#import "OptConGetiCadeViewController.h"
#import "fbaconf.h"

char iCade_langStr[MAX_LANG][32]={
    "English",
    "Français"
};
int mOptICadeButtonSelected;
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
@synthesize tabView,btn_backToEmu;
@synthesize optgetButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"iCade",@"");
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
    optgetButton=[[OptConGetiCadeViewController alloc] initWithNibName:@"OptConGetiCadeViewController" bundle:nil];
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    //ICADE & Wiimote
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [optgetButton release];
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

static int viewWA_patch=0;

- (void)viewWillAppear:(BOOL)animated {
    if (viewWA_patch) return;
    viewWA_patch++;
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
    if (!viewWA_patch) return;
    viewWA_patch--;
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (optionScope==0)	return 3;
    else return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (optionScope==0) {
    if (section==1) return VSTICK_NB_BUTTON;
    return 1;
    } else {
        if (section==0) return VSTICK_NB_BUTTON;
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
        case 1://Mapping
            footer=NSLocalizedString(@"Mapping info",@"");
            break;
        case 2://Reset to Default
            footer=@"";
            break;
    }
    } else {
        switch (section) {
            case 0://Mapping
                footer=NSLocalizedString(@"Mapping info",@"");
                break;
            case 1://Reset to Default
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
        case 1://Mapping
            cell.textLabel.text=[NSString stringWithFormat:@"%s",cur_ifba_conf->joymap_iCade[indexPath.row].btn_name];
            lblview=[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,30)];
            if (cur_ifba_conf->joymap_iCade[indexPath.row].dev_btn) lblview.text=[NSString stringWithFormat:@"Button %c",'A'-1+cur_ifba_conf->joymap_iCade[indexPath.row].dev_btn];
            else lblview.text=@"/";
            lblview.backgroundColor=[UIColor clearColor];
            cell.accessoryView=lblview;
            [lblview release];
            cell.textLabel.textAlignment=UITextAlignmentLeft;
            break;
        case 2://Reset to default
            cell.textLabel.text=NSLocalizedString(@"Reset to default",@"");
            cell.textLabel.textAlignment=UITextAlignmentCenter;
            cell.accessoryView=nil;
            break;
    }
    } else {
        switch (indexPath.section) {
            case 0://Mapping
                cell.textLabel.text=[NSString stringWithFormat:@"%s",cur_ifba_conf->joymap_iCade[indexPath.row].btn_name];
                lblview=[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,30)];
                if (cur_ifba_conf->joymap_iCade[indexPath.row].dev_btn) lblview.text=[NSString stringWithFormat:@"Button %c",'A'-1+cur_ifba_conf->joymap_iCade[indexPath.row].dev_btn];
                else lblview.text=@"/";
                lblview.backgroundColor=[UIColor clearColor];
                cell.accessoryView=lblview;
                [lblview release];
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                break;
            case 1://Reset to default
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
            mOptICadeButtonSelected=indexPath.row;
            [self presentSemiModalViewController:optgetButton];
            [tabView reloadData];            
            break;
        case 2:
            /*joymap_iCade[0].dev_btn=4;//Start
            joymap_iCade[1].dev_btn=8;//Select/Coin
            joymap_iCade[2].dev_btn=0;//Menu
            joymap_iCade[3].dev_btn=0;//Turbo
            joymap_iCade[4].dev_btn=0;//Service
            joymap_iCade[5].dev_btn=1;//Fire 1
            joymap_iCade[6].dev_btn=2;//Fire 2
            joymap_iCade[7].dev_btn=3;//...
            joymap_iCade[8].dev_btn=5;//
            joymap_iCade[9].dev_btn=6;//
            joymap_iCade[10].dev_btn=7;//Fire 6*/
            memcpy(cur_ifba_conf->joymap_iCade,default_joymap_iCade,sizeof(default_joymap_iCade));
            [tabView reloadData];            
            break;
    }
    } else {
        switch (indexPath.section) {
            case 0:
                mOptICadeButtonSelected=indexPath.row;
                [self presentSemiModalViewController:optgetButton];
                [tabView reloadData];            
                break;
            case 1:
                /*joymap_iCade[0].dev_btn=4;//Start
                joymap_iCade[1].dev_btn=8;//Select/Coin
                joymap_iCade[2].dev_btn=0;//Menu
                joymap_iCade[3].dev_btn=0;//Turbo
                joymap_iCade[4].dev_btn=0;//Service
                joymap_iCade[5].dev_btn=1;//Fire 1
                joymap_iCade[6].dev_btn=2;//Fire 2
                joymap_iCade[7].dev_btn=3;//...
                joymap_iCade[8].dev_btn=5;//
                joymap_iCade[9].dev_btn=6;//
                joymap_iCade[10].dev_btn=7;//Fire 6
                [tabView reloadData];   */
                memcpy(cur_ifba_conf->joymap_iCade,default_joymap_iCade,sizeof(default_joymap_iCade));
                break;
        }
        
    }
}


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
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
