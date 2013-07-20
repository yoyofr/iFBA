//
//  OptVPadViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define MAX_PAD_OFS_X 64
#define MAX_PAD_OFS_Y 64

#define MAX_BUTTON_OFS_X 64
#define MAX_BUTTON_OFS_Y 64

#import "OptVPadViewController.h"
#import "MNEValueTrackingSlider.h"
#import "EmuViewController.h"

#import "fbaconf.h"

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;

extern EmuViewController *emuvc;
extern int vpad_button_nb;

extern int optionScope;
#define OPTION(a) (optionScope?ifba_game_conf.a:ifba_conf.a)

extern volatile int renderVPADonly;

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

@implementation OptVPadViewController
@synthesize tabView,btn_backToEmu,emuvc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Virtual pad",@"");
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
    
    [[[UIApplication sharedApplication] delegate] saveSettings];
    if (game_has_options) { //settings already loaded, ensure any modification are saved
        [[[UIApplication sharedApplication] delegate] saveSettings:[NSString stringWithFormat:@"%s",gameName]];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 6;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:return 2;
        case 1:return 2;
        case 2:return 2;
        case 3:return 1;
        case 4:return 2;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=NSLocalizedString(@"Display",@"");
            break;
        case 1:title=NSLocalizedString(@"Size",@"");
            break;
        case 2:title=NSLocalizedString(@"Position",@"");
            break;
        case 3:title=@"";
            break;
        case 4:title=NSLocalizedString(@"Follow-finger",@"");
            break;
    }
    return title;
}

- (void)segActionOpacity:(id)sender {
    int refresh=0;
    if (OPTION(vpad_alpha)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(vpad_alpha)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}

- (void)switchDisplaySpecial:(id)sender {
    OPTION(vpad_showSpecial) =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (void)segActionBtnSize:(id)sender {
    int refresh=0;
    if (OPTION(vpad_btnsize)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(vpad_btnsize)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionPadSize:(id)sender {
    int refresh=0;
    if (OPTION(vpad_padsize)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(vpad_padsize)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionSkin:(id)sender {
    int refresh=0;
    if (OPTION(vpad_style)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(vpad_style)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionFFingerMode:(id)sender {
    int refresh=0;
    if (OPTION(vpad_followfinger_firemode)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(vpad_followfinger_firemode)=[sender selectedSegmentIndex];
    if (refresh) {
        //force recompute of nb_buttons
        vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;
        [tabView reloadData];
    }
}
-(void)sliderFFingerSensibility:(id)sender {
    OPTION(vpad_followfinger_sensibility)=((MNEValueTrackingSlider*)sender).value;
    //    if ([cur_screen respondsToSelector:@selector(setBrightness:)]) [cur_screen setBrightness:OPTION(brightness)];
    //    [tabView reloadData];
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Display
            footer=NSLocalizedString(@"Display vpad",@"");
            break;
        case 1://Size
            footer=NSLocalizedString(@"Change size",@"");
            break;
        case 2://Position
            footer=NSLocalizedString(@"Change position",@"");
            break;
        case 4://Follow-finger mode
            footer=NSLocalizedString(@"Change follow-finger settings",@"");
            break;
    }
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchview;
    UISegmentedControl *segconview;
    MNEValueTrackingSlider *sliderview;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.accessoryType=UITableViewCellAccessoryNone;
    switch (indexPath.section) {
        case 0://Display
            if (indexPath.row==0) {//Opacity
                cell.textLabel.text=NSLocalizedString(@"Opacity",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ",@" 2 ",@" 3 ",nil]];
                segconview.segmentedControlStyle = UISegmentedControlStylePlain;
                [segconview addTarget:self action:@selector(segActionOpacity:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = segconview;
                [segconview release];
                segconview.selectedSegmentIndex=OPTION(vpad_alpha);
            } else if (indexPath.row==1) {//Display specials
                cell.textLabel.text=NSLocalizedString(@"Display specials",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
                [switchview addTarget:self action:@selector(switchDisplaySpecial:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchview;
                [switchview release];
                switchview.on=OPTION(vpad_showSpecial);
                
            }
            break;
        case 1://Size
            if (indexPath.row==0) {//Buttons
                cell.textLabel.text=NSLocalizedString(@"Buttons",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ",@" 2 ",nil]];
                segconview.segmentedControlStyle = UISegmentedControlStylePlain;
                [segconview addTarget:self action:@selector(segActionBtnSize:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = segconview;
                [segconview release];
                segconview.selectedSegmentIndex=OPTION(vpad_btnsize);
            } else if (indexPath.row==1) {//Pad
                cell.textLabel.text=NSLocalizedString(@"Pad",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ",@" 2 ",nil]];
                segconview.segmentedControlStyle = UISegmentedControlStylePlain;
                [segconview addTarget:self action:@selector(segActionPadSize:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = segconview;
                [segconview release];
                segconview.selectedSegmentIndex=OPTION(vpad_padsize);
            }
            break;
        case 2://position
            switch (indexPath.row) {
                case 0://dynamic setup
                    cell.textLabel.text=NSLocalizedString(@"Change layout",@"");
                    cell.textLabel.textAlignment=UITextAlignmentCenter;
                    cell.accessoryView = nil;
                    break;
                case 1://Default
                    cell.textLabel.text=NSLocalizedString(@"Reset to default",@"");
                    cell.textLabel.textAlignment=UITextAlignmentCenter;
                    cell.accessoryView=nil;
                    break;
            }
            break;
        case 3://skin
            cell.textLabel.text=NSLocalizedString(@"Skin",@"");
            cell.textLabel.textAlignment=UITextAlignmentLeft;
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ",@" 2 ",nil]];
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionSkin:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = segconview;
            [segconview release];
            segconview.selectedSegmentIndex=OPTION(vpad_style);
            break;
        case 4://follow_finger
            if (indexPath.row==0) { //mode (autofire/normal)
                cell.textLabel.text=NSLocalizedString(@"Buttons mode",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Autofire", @" Normal",nil]];
                segconview.segmentedControlStyle = UISegmentedControlStylePlain;
                [segconview addTarget:self action:@selector(segActionFFingerMode:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = segconview;
                [segconview release];
                segconview.selectedSegmentIndex=OPTION(vpad_followfinger_firemode);
            } else { //sensibility
                cell.textLabel.text=NSLocalizedString(@"Sensibility",@"");
                sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
                sliderview.integerMode=0;
                [sliderview setMaximumValue:2.0f];
                [sliderview setMinimumValue:1.0f];
                [sliderview setContinuous:true];
                sliderview.value=OPTION(vpad_followfinger_sensibility);
                [sliderview addTarget:self action:@selector(sliderFFingerSensibility:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sliderview;
                [sliderview release];
            }
            break;
    }
    
	
    
    return cell;
}

extern void resetPadLayouts();

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==2) {//Position
        if (indexPath.row==0) {//change layout
            renderVPADonly=1;
            //EmuViewController *vc = [[EmuViewController alloc] initWithNibName:@"EmuViewController" bundle:nil];
            [self.navigationController pushViewController:emuvc animated:NO];
            //            [vc release];
        } else if (indexPath.row==1) {//Reset x,y ofs to default
            //TODO
            resetPadLayouts();
            [tableView reloadData];
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
