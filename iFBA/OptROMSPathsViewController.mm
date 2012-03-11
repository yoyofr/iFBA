//
//  OptROMSPathsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptROMSPathsViewController.h"
#import "OptROMSSetPathsViewController.h"
#include "burner.h"
#import "fbaconf.h"
extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
int szAppRomPathsSelected;

@implementation OptROMSPathsViewController
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"ROMS Paths",@"");
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
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
    return DIRS_MAX;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;    
    if (szAppRomPaths[indexPath.row][0]) {
        cell.textLabel.text=[NSString stringWithFormat:@"%d: %s",indexPath.row,szAppRomPaths[indexPath.row]];

    } else {
        cell.textLabel.text=[NSString stringWithFormat:@"%d:",indexPath.row];

    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    szAppRomPathsSelected=indexPath.row;
    OptROMSSetPathsViewController *romsetvc=[[OptROMSSetPathsViewController alloc] initWithNibName:@"OptROMSPathsViewController" bundle:nil];
    [self.navigationController pushViewController:romsetvc animated:YES];
    [romsetvc release];
}


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
