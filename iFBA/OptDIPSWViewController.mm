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

int InpDIPSWGetNb();
int InpDIPSWGetIndex(int i,char *result);
int InpDIPSWGetValueNb(int i);
char *InpDIPSWGetValueString(int dip_idx,int val_idx);
char *InpDIPSWGetCurrentValue(int dip_index,int *dip_current_value);
char *InpDIPSWGetDIPName(int dip_index);

@implementation OptDIPSWViewController
@synthesize tabView;

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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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


@end
