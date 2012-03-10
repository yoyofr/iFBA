//
//  OptDIPSWValueViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptDIPSWValueViewController.h"

#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

extern int InpDIPSWListMake();
extern int InpDIPSWGetNb();
int InpDIPSWGetIndex(int i,char *result);
int InpDIPSWGetValueNb(int i);
char *InpDIPSWGetValueString(int dip_idx,int val_idx);
char *InpDIPSWGetDIPName(int dip_index);
char *InpDIPSWGetCurrentValue(int dip_index,int *dip_current_value);
unsigned char InpDIPSWGetDIPValue(int dip_idx, int val_idx);
int InpDIPSWSetCurrentValue(int dip_index,unsigned char dip_new_value);

@implementation OptDIPSWValueViewController
@synthesize tabView,btn_backToEmu;
@synthesize current_dip_idx;

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
#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return InpDIPSWGetValueNb(current_dip_idx);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%s",InpDIPSWGetDIPName(current_dip_idx)];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int current_dip_val;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
        
    InpDIPSWGetCurrentValue(current_dip_idx,&current_dip_val);
    cell.textLabel.text=[NSString stringWithFormat:@"%s",InpDIPSWGetValueString(current_dip_idx,indexPath.row)];
    if (current_dip_val==indexPath.row) cell.accessoryType=UITableViewCellAccessoryCheckmark;
    else cell.accessoryType=UITableViewCellAccessoryNone;
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    unsigned char tmp;
    tmp=InpDIPSWGetDIPValue(current_dip_idx,indexPath.row);
//    NSLog(@"should change %d to %02X",current_dip_idx,tmp);
    InpDIPSWSetCurrentValue(current_dip_idx,tmp);
    [tabView reloadData];
}


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
