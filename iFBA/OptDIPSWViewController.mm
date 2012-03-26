//
//  OptDIPSWViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptDIPSWViewController.h"
#import "OptDIPSWValueViewController.h"

#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

int InpDIPSWGetNb();
int InpDIPSWGetIndex(int i,char *result);
int InpDIPSWGetValueNb(int i);
char *InpDIPSWGetValueString(int dip_idx,int val_idx);
char *InpDIPSWGetCurrentValue(int dip_index,int *dip_current_value);
char *InpDIPSWGetDIPName(int dip_index);

//iCade
#import "iCadeReaderView.h"
static iCadeReaderView *iCaderv;
static int ui_currentIndex_s,ui_currentIndex_r;


@implementation OptDIPSWViewController
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"DIPSW",@"");
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
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return InpDIPSWGetNb();
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=@"";//NSLocalizedString(@"Aspect Ratio",@"");
            break;        
    }
    return title;
}

- (void)segActionVideoMode:(id)sender {
    ifba_conf.screen_mode=[sender selectedSegmentIndex];
    [tabView reloadData];
}
- (void)switchAspectRatio:(id)sender {
    ifba_conf.aspect_ratio =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Aspect Ratio
            footer=NSLocalizedString(@"Change DIP Switches",@"");
            break;
    }
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    char tmpStr[128];
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    
    cell.accessoryType=UITableViewCellAccessoryNone;
    switch (indexPath.section) {
        case 0://DIP Switches            
            cell.textLabel.text=[NSString stringWithFormat:@"%s - %s",InpDIPSWGetDIPName(indexPath.row),InpDIPSWGetCurrentValue(indexPath.row,NULL)];
            break;
            
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OptDIPSWValueViewController *dipvaluevc=[[OptDIPSWValueViewController alloc] initWithNibName:@"OptDIPSWValueViewController" bundle:nil];
    dipvaluevc.current_dip_idx=indexPath.row;
    [self.navigationController pushViewController:dipvaluevc animated:YES];
    [dipvaluevc release];
    
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
