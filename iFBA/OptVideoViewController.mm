//
//  OptVideoViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptVideoViewController.h"

#import "fbaconf.h"


@implementation OptVideoViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Video",@"");
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
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=NSLocalizedString(@"Aspect Ratio",@"");
            break;
        case 1:title=NSLocalizedString(@"Screen mode",@"");
            break;
        case 2:title=NSLocalizedString(@"Filtering",@"");
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
- (void)switchFiltering:(id)sender {
    ifba_conf.filtering =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Aspect Ratio
            if (ifba_conf.aspect_ratio) {
                footer=NSLocalizedString(@"Respect original game's aspect ratio",@"");
            } else {
                footer=NSLocalizedString(@"Don't respect original game's aspect ratio",@"");
            }
            break;
        case 1://Screen mode
            switch (ifba_conf.screen_mode) {
                case 0:
                    footer=NSLocalizedString(@"Original resolution",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Scaled resolution with vpad",@"");
                    break;
                case 2:
                    footer=NSLocalizedString(@"Fullscreen",@"");
                    break;
            }
            break;
        case 2://Filtering
            switch (ifba_conf.filtering) {
                case 0:
                    footer=NSLocalizedString(@"No filtering",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Linear filtering",@"");
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
        case 0://Aspect Ratio
            cell.textLabel.text=NSLocalizedString(@"Aspect Ratio",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchAspectRatio:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.aspect_ratio;
            break;
        case 1://Screen mode
            cell.textLabel.text=NSLocalizedString(@"Screen mode",@"");
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"1", @"2", @"3", nil]];
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionVideoMode:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            segconview.selectedSegmentIndex=ifba_conf.screen_mode;
            break;
        case 2://Filtering
            cell.textLabel.text=NSLocalizedString(@"Filtering",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchFiltering:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.filtering;
            break;
    }
    
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


@end
