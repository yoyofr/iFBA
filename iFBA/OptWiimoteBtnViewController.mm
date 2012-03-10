//
//  OptWiimoteBtnViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptWiimoteBtnViewController.h"
#import "BTstack/BTstackManager.h"
#import "BTstack/BTDiscoveryViewController.h"
#import "BTstackManager.h"
#import "wiimote.h"

#import "OptConGetWiimoteBtnViewController.h"
#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

extern int wiimoteSelected;

int mOptWiimoteButtonSelected;


@implementation OptWiimoteBtnViewController
@synthesize tabView,btn_backToEmu;
@synthesize optgetButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=[NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"Wiimote",@""),wiimoteSelected];
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
    optgetButton=[[OptConGetWiimoteBtnViewController alloc] initWithNibName:@"OptConGetWiimoteBtnViewController" bundle:nil];
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
    BTstackManager *bt = [BTstackManager sharedInstance];
/*    if (ifba_conf.btstack_on&&bt) {
        UIAlertView *aboutMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:NSLocalizedString(@"Warning iCade BTStack",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
        [aboutMsg show];
    }*/
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
}
#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) return VSTICK_NB_BUTTON;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=@"";
            break;
        case 1:title=@"";
            break;
    }
    return title;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Mapping
            footer=NSLocalizedString(@"Mapping wii info",@"");
            break;
        case 1://Reset to Default
            footer=@"";
            break;
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
    switch (indexPath.section) {
        case 0://Mapping
            cell.textLabel.text=[NSString stringWithFormat:@"%s",joymap_wiimote[wiimoteSelected][indexPath.row].btn_name];
            lblview=[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,30)];
            if (joymap_wiimote[wiimoteSelected][indexPath.row].dev_btn) lblview.text=[NSString stringWithFormat:@"Button %d",joymap_wiimote[wiimoteSelected][indexPath.row].dev_btn];
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
    
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if (num_of_joys>wiimoteSelected) {
                mOptWiimoteButtonSelected=indexPath.row;
                [self presentSemiModalViewController:optgetButton];
                [tabView reloadData];
            } else {
                UIAlertView *aboutMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:NSLocalizedString(@"Warning wiimote not connected",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                [aboutMsg show];
            }
            break;
        case 1:            
            joymap_wiimote[wiimoteSelected][0].dev_btn=WII_BUTTON_START;//Start
            joymap_wiimote[wiimoteSelected][1].dev_btn=WII_BUTTON_SELECT;//Select/Coin
            joymap_wiimote[wiimoteSelected][2].dev_btn=WII_BUTTON_HOME;//Menu
            joymap_wiimote[wiimoteSelected][3].dev_btn=WII_BUTTON_G;//Turbo
            joymap_wiimote[wiimoteSelected][4].dev_btn=WII_BUTTON_G;//Service
            joymap_wiimote[wiimoteSelected][5].dev_btn=WII_BUTTON_A;//Fire 1
            joymap_wiimote[wiimoteSelected][6].dev_btn=WII_BUTTON_B;//Fire 2
            joymap_wiimote[wiimoteSelected][7].dev_btn=WII_BUTTON_C;//...
            joymap_wiimote[wiimoteSelected][8].dev_btn=WII_BUTTON_D;//
            joymap_wiimote[wiimoteSelected][9].dev_btn=WII_BUTTON_E;//
            joymap_wiimote[wiimoteSelected][10].dev_btn=WII_BUTTON_F;//Fire 6
            [tabView reloadData];            
            break;
    }
}


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
