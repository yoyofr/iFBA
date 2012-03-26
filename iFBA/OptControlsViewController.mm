//
//  OptControlsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptControlsViewController.h"
#import "OptWiimoteViewController.h"
#import "OptiCadeViewController.h"
#import "OptVPadViewController.h"
#import "fbaconf.h"
#import "string.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

//iCade
#import "iCadeReaderView.h"
static iCadeReaderView *iCaderv;
static int ui_currentIndex_s,ui_currentIndex_r;


@implementation OptControlsViewController
@synthesize optWiimote,optiCade,optVPad;
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Controllers",@"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    //ICADE 
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
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
    return 3;
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

    switch (indexPath.row) {
        case 0:cell.textLabel.text=NSLocalizedString(@"Wiimote",@"");
            break;
        case 1:cell.textLabel.text=NSLocalizedString(@"iCade",@"");
            break;
        case 2:cell.textLabel.text=NSLocalizedString(@"Virtual pad",@"");
            break;
    }
    	
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *aboutMsg;
    switch (indexPath.row) {
        case 0://Wiimote
            optWiimote=[[OptWiimoteViewController alloc] initWithNibName:@"OptWiimoteViewController" bundle:nil];
            [self.navigationController pushViewController:optWiimote animated:YES];
            [optWiimote release];
            break;
        case 1://iCade
            optiCade =[[OptiCadeViewController alloc] initWithNibName:@"OptiCadeViewController" bundle:nil];
            [self.navigationController pushViewController:optiCade animated:YES];
            [optiCade release];
            break;
        case 2://Virtual pad
            optVPad =[[OptVPadViewController alloc] initWithNibName:@"OptVPadViewController" bundle:nil];
            [self.navigationController pushViewController:optVPad animated:YES];
            [optVPad release];
            break;
    }
}

-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

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
