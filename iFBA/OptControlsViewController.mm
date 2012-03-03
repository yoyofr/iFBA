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


@implementation OptControlsViewController
@synthesize optWiimote,optiCade,optVPad;
@synthesize tabView;

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
            //optiCade =[[OptiCadeViewController alloc] initWithNibName:@"OptiCadeViewController" bundle:nil];
            //[self.navigationController pushViewController:optiCade animated:YES];
            //[optiCade release];
            aboutMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About",@"") message:@"Not developped yet" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
            [aboutMsg show];            
            break;
        case 2://Virtual pad
            optVPad =[[OptVPadViewController alloc] initWithNibName:@"OptVPadViewController" bundle:nil];
            [self.navigationController pushViewController:optVPad animated:YES];
            [optVPad release];
            break;
    }
}

@end
