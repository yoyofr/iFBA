//
//  OptVideoViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptVideoViewController.h"
#import "MNEValueTrackingSlider.h"

#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;

extern int optionScope;
#define OPTION(a) (optionScope?ifba_game_conf.a:ifba_conf.a)

@implementation OptVideoViewController
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Video",@"");
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
	return 8;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==3) return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}




- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Screen mode
            switch (OPTION(screen_mode)) {
                case 0:
                    footer=NSLocalizedString(@"Original resolution",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Scaled resolution with vpad",@"");
                    break;
                case 2:
                    footer=NSLocalizedString(@"Fullscreen",@"");
                    break;
            }
            break;
        case 1://frameskip
            footer=nil;
            break;
        case 2://Aspect Ratio
            if (OPTION(aspect_ratio)) {
                footer=NSLocalizedString(@"Respect original game's aspect ratio",@"");
            } else {
                footer=NSLocalizedString(@"Don't respect original game's aspect ratio",@"");
            }
            break;
            
        case 3://Video Filter
            switch (OPTION(video_filter)) {
                case 0:
                    footer=NSLocalizedString(@"No filter",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Scanline",@"");
                    break;
                case 2:
                    footer=NSLocalizedString(@"CRT",@"");
                    break;
            }
            break;
        case 4://Filtering
            switch (OPTION(filtering)) {
                case 0:
                    footer=NSLocalizedString(@"No filtering",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Linear filtering",@"");
                    break;
            }
            break;
        case 5://60Hz
            switch (OPTION(video_60hz)) {
                case 0:
                    footer=NSLocalizedString(@"Correct timing",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Force 60Hz for smoother video",@"");
                    break;
            }
            break;
        case 6://show fps
            switch (OPTION(show_fps)) {
                case 0:
                    footer=NSLocalizedString(@"Do not display fps",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Display fps",@"");
                    break;
            }
            break;
        case 7://brightness
            footer=nil;
            break;
        
    }
    return footer;
}

- (void)segActionVideoMode:(id)sender {
    int refresh=0;
    if (OPTION(screen_mode)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(screen_mode)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionVideoFilter:(id)sender {
    int refresh=0;
    if (OPTION(video_filter)!=[sender selectedSegmentIndex]) refresh=1;
    OPTION(video_filter)=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}

- (void)switch60Hz:(id)sender {
    OPTION(video_60hz) =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (void)switchAspectRatio:(id)sender {
    OPTION(aspect_ratio) =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchFiltering:(id)sender {
    OPTION(filtering) =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchShowFPS:(id)sender {
    OPTION(show_fps) =((UISwitch*)sender).on;
    [tabView reloadData];
}
-(void)sliderBrightness:(id)sender {
    OPTION(brightness)=((MNEValueTrackingSlider*)sender).value;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) [[UIScreen mainScreen] setBrightness:OPTION(brightness)];
    //    [tabView reloadData];
}
-(void)sliderFilterStrength:(id)sender {
    OPTION(video_filter_strength)=((UISlider*)sender).value;
    //    [tabView reloadData];
}

-(void)sliderFSkip:(id)sender {
    OPTION(video_fskip)=((MNEValueTrackingSlider*)sender).value;
    if (OPTION(video_fskip)==10) [((MNEValueTrackingSlider*)sender) setValue:10 sValue:@"AUTO"];
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
        case 0://Screen mode
            cell.textLabel.text=NSLocalizedString(@"Screen mode",@"");
            
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 1 ", @" 2 ", @" 3 ", nil]];
            segconview.selectedSegmentIndex=OPTION(screen_mode);
            
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionVideoMode:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            
            break;
        case 1://Frameskipping
            cell.textLabel.text=NSLocalizedString(@"Frameskip",@"");
            sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
            sliderview.integerMode=1;
            [sliderview setMaximumValue:10.0f];
            [sliderview setMinimumValue:0];
            [sliderview setContinuous:true];
            sliderview.value=OPTION(video_fskip);
            if (OPTION(video_fskip)==10) [sliderview setValue:10 sValue:@"AUTO"];
            [sliderview addTarget:self action:@selector(sliderFSkip:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sliderview;
            [sliderview release];
            break;
        case 2://Aspect Ratio
            cell.textLabel.text=NSLocalizedString(@"Aspect Ratio",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchAspectRatio:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=OPTION(aspect_ratio);
            break;
        case 3://Video Filters
            if (indexPath.row==0) {
            cell.textLabel.text=NSLocalizedString(@"Video filter",@"");
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ", @" 2 ", nil]];
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionVideoFilter:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            segconview.selectedSegmentIndex=OPTION(video_filter);
            } else { //strength
                cell.textLabel.text=NSLocalizedString(@"Video filter strength",@"");
                sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];                
                sliderview.integerMode=1;
                [sliderview setMaximumValue:128];
                [sliderview setMinimumValue:0];
                [sliderview setContinuous:true];
                [sliderview addTarget:self action:@selector(sliderFilterStrength:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sliderview;
                [sliderview release];
                sliderview.value=OPTION(video_filter_strength);
            }
            break;
        case 4://Filtering
            cell.textLabel.text=NSLocalizedString(@"Filtering",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchFiltering:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=OPTION(filtering);
            break;
        case 5://60Hz
            cell.textLabel.text=NSLocalizedString(@"60Hz",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switch60Hz:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=OPTION(video_60hz);
            break;
        case 6://Show FPS
            cell.textLabel.text=NSLocalizedString(@"Show FPS",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchShowFPS:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=OPTION(show_fps);
            break;
        
        case 7://Brightness
            cell.textLabel.text=NSLocalizedString(@"Brightness",@"");
            sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
            //[sliderview setMaximumValue:1.0f];
            //[sliderview setMinimumValue:0.0f];
            [sliderview setContinuous:true];
            sliderview.value=OPTION(brightness);
            
            [sliderview addTarget:self action:@selector(sliderBrightness:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sliderview;
            [sliderview release];
            if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]==NO) sliderview.enabled=NO; 
            break;
        
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
