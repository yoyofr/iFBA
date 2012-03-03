//
//  OptVPadViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptVPadViewController.h"

#import "fbaconf.h"


@implementation OptVPadViewController
@synthesize tabView;

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

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=NSLocalizedString(@"Opacity",@"");
            break;
    }
    return title;
}

- (void)segActionOpacity:(id)sender {
    ifba_conf.vpad_alpha =[sender selectedSegmentIndex];
    [tabView reloadData];
}

- (void)segActionLayout:(id)sender {
    ifba_conf.vpad_alpha =[sender selectedSegmentIndex];
    [tabView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Opacity
            switch (ifba_conf.vpad_alpha) {
                case 0:footer=NSLocalizedString(@"Invisible",@"");
                    break;
                case 1:footer=NSLocalizedString(@"Low",@"");
                    break;
                case 2:footer=NSLocalizedString(@"Med",@"");
                    break;
                case 3:footer=NSLocalizedString(@"Opaque",@"");
                    break;
            }
            break;
    }
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchview;
    UISegmentedControl *segconview;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    cell.accessoryType=UITableViewCellAccessoryNone;
    switch (indexPath.section) {
        case 0://Opacity
            cell.textLabel.text=NSLocalizedString(@"Opacity",@"");
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"0", @"1",@"2",@"3",nil]];
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionOpacity:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            segconview.selectedSegmentIndex=ifba_conf.vpad_alpha;
            break;
    }
    
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


@end
