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

#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

@implementation OptVPadViewController
@synthesize tabView,btn_backToEmu;

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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:return 2;
        case 1:return 2;
        case 2:return 5;
        case 3:return 1;
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
    }
    return title;
}

- (void)segActionOpacity:(id)sender {
    int refresh=0;
    if (ifba_conf.vpad_alpha!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.vpad_alpha=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}

- (void)switchDisplaySpecial:(id)sender {
    ifba_conf.vpad_showSpecial =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (void)segActionBtnSize:(id)sender {
    int refresh=0;
    if (ifba_conf.vpad_btnsize!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.vpad_btnsize=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionPadSize:(id)sender {
    int refresh=0;
    if (ifba_conf.vpad_padsize!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.vpad_padsize=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionSkin:(id)sender {
    int refresh=0;
    if (ifba_conf.vpad_style!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.vpad_style=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)sldActionPadX:(id)sender {
    ifba_conf.vpad_pad_x=((UISlider *)sender).value;
}
- (void)sldActionPadY:(id)sender {
    ifba_conf.vpad_pad_y=((UISlider *)sender).value;
}
- (void)sldActionButtonX:(id)sender {
    ifba_conf.vpad_button_x=((UISlider *)sender).value;
}
- (void)sldActionButtonY:(id)sender {
    ifba_conf.vpad_button_y=((UISlider *)sender).value;
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
            segconview.selectedSegmentIndex=ifba_conf.vpad_alpha;
            } else if (indexPath.row==1) {//Display specials
                cell.textLabel.text=NSLocalizedString(@"Display specials",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
                [switchview addTarget:self action:@selector(switchDisplaySpecial:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchview;
                [switchview release];
                switchview.on=ifba_conf.vpad_showSpecial;

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
                segconview.selectedSegmentIndex=ifba_conf.vpad_btnsize;
            } else if (indexPath.row==1) {//Pad
                cell.textLabel.text=NSLocalizedString(@"Pad",@"");
                cell.textLabel.textAlignment=UITextAlignmentLeft;
                segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ",@" 2 ",nil]];
                segconview.segmentedControlStyle = UISegmentedControlStylePlain;
                [segconview addTarget:self action:@selector(segActionPadSize:) forControlEvents:UIControlEventValueChanged];            
                cell.accessoryView = segconview;
                [segconview release];
                segconview.selectedSegmentIndex=ifba_conf.vpad_padsize;                
            }
            break;
        case 2://position
            switch (indexPath.row) {
                case 0://Pad X
                    cell.textLabel.text=NSLocalizedString(@"Pad X",@"");
                    cell.textLabel.textAlignment=UITextAlignmentLeft;
                    sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
                    sliderview.integerMode=1;
                    [sliderview setMaximumValue:MAX_PAD_OFS_X];
                    [sliderview setMinimumValue:-MAX_PAD_OFS_X];
                    [sliderview setContinuous:true];
                    sliderview.value=ifba_conf.vpad_pad_x;                    
                    [sliderview addTarget:self action:@selector(sldActionPadX:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sliderview;
                    [sliderview release];
                    break;
                case 1://Pad Y
                    cell.textLabel.text=NSLocalizedString(@"Pad Y",@"");
                    cell.textLabel.textAlignment=UITextAlignmentLeft;
                    sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
                    sliderview.integerMode=1;
                    [sliderview setMaximumValue:MAX_PAD_OFS_Y];
                    [sliderview setMinimumValue:-MAX_PAD_OFS_Y];
                    [sliderview setContinuous:true];
                    sliderview.value=ifba_conf.vpad_pad_y;                    
                    [sliderview addTarget:self action:@selector(sldActionPadY:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sliderview;
                    [sliderview release];
                    break;
                case 2://Button X
                    cell.textLabel.text=NSLocalizedString(@"Buttons X",@"");
                    cell.textLabel.textAlignment=UITextAlignmentLeft;
                    sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
                    sliderview.integerMode=1;
                    [sliderview setMaximumValue:MAX_BUTTON_OFS_X];
                    [sliderview setMinimumValue:-MAX_BUTTON_OFS_X];
                    [sliderview setContinuous:true];
                    sliderview.value=ifba_conf.vpad_button_x;                    
                    [sliderview addTarget:self action:@selector(sldActionButtonX:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sliderview;
                    [sliderview release];
                    break;
                case 3://Button Y
                    cell.textLabel.text=NSLocalizedString(@"Buttons Y",@"");
                    cell.textLabel.textAlignment=UITextAlignmentLeft;
                    sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
                    sliderview.integerMode=1;
                    [sliderview setMaximumValue:MAX_BUTTON_OFS_Y];
                    [sliderview setMinimumValue:-MAX_BUTTON_OFS_Y];
                    [sliderview setContinuous:true];
                    sliderview.value=ifba_conf.vpad_button_y;                    
                    [sliderview addTarget:self action:@selector(sldActionButtonY:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sliderview;
                    [sliderview release];
                    break;
                case 4://Default
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
                segconview.selectedSegmentIndex=ifba_conf.vpad_style;
            break;
    }
    
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==2) {//Position
        if (indexPath.row==4) {//Reset x,y ofs to default
            ifba_conf.vpad_button_x=0;
            ifba_conf.vpad_button_y=0;
            ifba_conf.vpad_pad_x=0;
            ifba_conf.vpad_pad_y=0;
            [tableView reloadData];
        }
    }
}


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
