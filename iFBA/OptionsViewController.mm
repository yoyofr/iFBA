//
//  OptionsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"
#import "OptOptionsViewController.h"
#import "OptROMSPathsViewController.h"

#import "fbaconf.h"
#import "string.h"

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

@implementation OptionsViewController
@synthesize tabView,btn_backToEmu,emuvc;

extern int optionScope; //0:default, 1:current game


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
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (emuThread_running) return 3;
    else return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    const NSInteger TOP_LABEL_TAG = 1001;
	const NSInteger BOTTOM_LABEL_TAG = 1002;
    UILabel *topLabel;
	UILabel *bottomLabel;
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
//        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		//
		// Create the label for the top row of text
		//
		topLabel = [[[UILabel alloc] init] autorelease];
		[cell.contentView addSubview:topLabel];
		
		//
		// Configure the properties for the text that are the same on every row
		//
		topLabel.tag = TOP_LABEL_TAG;
		topLabel.backgroundColor = [UIColor clearColor];
		topLabel.textColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0];
		topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
		topLabel.font = [UIFont boldSystemFontOfSize:16];
        topLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        //        topLabel.numberOfLines=0;
		
		//
		// Create the label for the top row of text
		//
		bottomLabel = [[[UILabel alloc] init] autorelease];
		[cell.contentView addSubview:bottomLabel];
		//
		// Configure the properties for the text that are the same on every row
		//
		bottomLabel.tag = BOTTOM_LABEL_TAG;
		bottomLabel.backgroundColor = [UIColor clearColor];
		bottomLabel.textColor = [UIColor colorWithRed:0.0 green:0 blue:0.1 alpha:1.0];
		bottomLabel.highlightedTextColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
		bottomLabel.font = [UIFont systemFontOfSize:12];
        bottomLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        
    } else {
		topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
		bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
	}
    
    bottomLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                   24,
                                   tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                   0);
    topLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                2,
                                tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                40);

    
    cell.textLabel.backgroundColor=[UIColor clearColor];
    
    
    
    switch (indexPath.row) {
        case 0:topLabel.text=NSLocalizedString(@"ROMS Paths",@"");
            bottomLabel.text=nil;
            cell.backgroundColor=[UIColor whiteColor];
            break;
        case 1:topLabel.text=NSLocalizedString(@"Default Options",@"");
            if (!game_has_options) {
                bottomLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                               24,
                                               tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                               14);
                topLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                            2,
                                            tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                            20);

                bottomLabel.text=@"Active config";
                cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradcell.png"]];
            } else {
                bottomLabel.text=nil;
                cell.backgroundColor=[UIColor whiteColor];
            }
            break;
        case 2:
            topLabel.text=NSLocalizedString(@"Game Options",@"");
            
            if (game_has_options) {
                bottomLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                               24,
                                               tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                               14);
                topLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                            2,
                                            tableView.bounds.size.width - 32-1.0 * cell.indentationWidth-40,
                                            20);

                bottomLabel.text=@"Active config";
                cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradcell.png"]];
            } else {
                bottomLabel.text=nil;
                cell.backgroundColor=[UIColor whiteColor];
            }
            break;
        
    }
    	
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc;
    switch (indexPath.row) {
        case 0://roms paths
            vc=[[OptROMSPathsViewController alloc] initWithNibName:@"OptROMSPathsViewController" bundle:nil];
            ((OptROMSPathsViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
            
        case 1://default options
            optionScope=0;
            cur_ifba_conf=(ifba_conf_t*)&ifba_conf;
            vc=[[OptOptionsViewController alloc] initWithNibName:@"OptOptionsViewController" bundle:nil];
            ((OptOptionsViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
        case 2://game options
            optionScope=1;
            if (game_has_options==0) {
                memcpy(&ifba_game_conf,&ifba_conf,sizeof(ifba_conf_t));
                game_has_options=1;
                cur_ifba_conf=&ifba_game_conf;
            } else cur_ifba_conf=(ifba_conf_t*)&ifba_game_conf;
            vc=[[OptOptionsViewController alloc] initWithNibName:@"OptOptionsViewController" bundle:nil];
            ((OptOptionsViewController*)vc)->emuvc=emuvc;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            break;
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
