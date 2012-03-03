//
//  OptEmuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptEmuViewController.h"

#import "fbaconf.h"


@implementation OptEmuViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Emulation",@"");
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
	return 1;//4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=NSLocalizedString(@"68000 core",@"");
            break;
        case 1:title=NSLocalizedString(@"z80 core",@"");
            break;
        case 2:title=NSLocalizedString(@"nec core",@"");
            break;
        case 3:title=NSLocalizedString(@"sh2 core",@"");
            break;
    }
    return title;
}

- (void)switch68k:(id)sender {
    ifba_conf.asm_68k =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchz80:(id)sender {
    ifba_conf.asm_z80 =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchsh2:(id)sender {
    ifba_conf.asm_sh2 =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchnec:(id)sender {
    ifba_conf.asm_nec =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://68k
            if (ifba_conf.asm_68k) {
                footer=NSLocalizedString(@"asm cpu core, faster but less compatible",@"");
            } else {
                footer=NSLocalizedString(@"C cpu core, slower but more compatible",@"");
            }
            break;
        case 1://z80
            if (ifba_conf.asm_z80) {
                footer=NSLocalizedString(@"asm cpu core, faster but less compatible",@"");
            } else {
                footer=NSLocalizedString(@"C cpu core, slower but more compatible",@"");
            }
            break;
        case 2://sh2
            if (ifba_conf.asm_sh2) {
                footer=NSLocalizedString(@"asm cpu core, faster but less compatible",@"");
            } else {
                footer=NSLocalizedString(@"C cpu core, slower but more compatible",@"");
            }
            break;
        case 3://nec
            if (ifba_conf.asm_nec) {
                footer=NSLocalizedString(@"asm cpu core, faster but less compatible",@"");
            } else {
                footer=NSLocalizedString(@"C cpu core, slower but more compatible",@"");
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
        case 0://68k
            cell.textLabel.text=NSLocalizedString(@"68k_core",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switch68k:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.asm_68k;
            break;
        case 1://z80
            cell.textLabel.text=NSLocalizedString(@"z80_core",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchz80:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.asm_z80;
            break;
        case 2://sh2
            cell.textLabel.text=NSLocalizedString(@"sh2_core",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchsh2:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.asm_sh2;
            break;
        case 3://nec
            cell.textLabel.text=NSLocalizedString(@"nec_core",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchnec:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.asm_nec;
            break;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


@end
