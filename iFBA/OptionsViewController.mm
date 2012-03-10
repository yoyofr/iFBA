//
//  OptionsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"
#import "OptVideoViewController.h"
#import "OptControlsViewController.h"
#import "OptEmuViewController.h"
#import "OptAudioViewController.h"
#import "OptROMSPathsViewController.h"

#import "fbaconf.h"
#import "string.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

@implementation OptionsViewController
@synthesize optVideo,optAudio,optControl,optEmulation,optROMSpaths;
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Options",@"");
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
    return 5;
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
        case 0:cell.textLabel.text=NSLocalizedString(@"Video",@"");
            break;
        case 1:cell.textLabel.text=NSLocalizedString(@"Audio",@"");
            break;
        case 2:cell.textLabel.text=NSLocalizedString(@"Controllers",@"");
            break;
        case 3:cell.textLabel.text=NSLocalizedString(@"Emulation",@"");
            break;
        case 4:cell.textLabel.text=NSLocalizedString(@"ROMS Paths",@"");
            break;
    }
    	
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0://video
            optVideo=[[OptVideoViewController alloc] initWithNibName:@"OptVideoViewController" bundle:nil];
            [self.navigationController pushViewController:optVideo animated:YES];
            [optVideo release];
            break;
        case 1://audio
            optAudio=[[OptAudioViewController alloc] initWithNibName:@"OptAudioViewController" bundle:nil];
            [self.navigationController pushViewController:optAudio animated:YES];
            [optAudio release];
            break;
        case 2://controllers
            optControl=[[OptControlsViewController alloc] initWithNibName:@"OptControlsViewController" bundle:nil];
            [self.navigationController pushViewController:optControl animated:YES];
            [optControl release];
            break;
        case 3://emulation
            optEmulation=[[OptEmuViewController alloc] initWithNibName:@"OptEmuViewController" bundle:nil];
            [self.navigationController pushViewController:optEmulation animated:YES];
            [optEmulation release];
            break;
        case 4://roms paths
            optROMSpaths=[[OptROMSPathsViewController alloc] initWithNibName:@"OptROMSPathsViewController" bundle:nil];
            [self.navigationController pushViewController:optROMSpaths animated:YES];
            [optROMSpaths release];
            break;
    }
}

-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
