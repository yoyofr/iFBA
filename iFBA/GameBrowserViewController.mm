//
//  GameBrowserViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameBrowserViewController.h"
#include "string.h"

extern char gameName[64];
extern int launchGame;

@implementation GameBrowserViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc{
    [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)scanRomsDir {
    NSError *error;
    NSArray *dirContent;
    NSFileManager *mFileMngr = [[NSFileManager alloc] init];
    NSString *cpath=[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents/"];
    NSString *file;
    NSArray *filetype_extROMFILE=[@"ZIP,FBA" componentsSeparatedByString:@","];    
    
    romlist=[[NSMutableArray alloc] init];
    
    dirContent=[mFileMngr subpathsOfDirectoryAtPath:cpath error:&error];
    for (file in dirContent) {
        NSString *extension=[[[file lastPathComponent] pathExtension] uppercaseString];
        if ([filetype_extROMFILE indexOfObject:extension]!=NSNotFound) {
            [romlist addObject:file];
        }
    }
    [mFileMngr release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scanRomsDir];
    [[self tabView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [romlist release];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UI Actions

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) return [romlist count];
	return 0;
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
    
	if (indexPath.section==0) {
        cell.textLabel.text=[romlist objectAtIndex:indexPath.row];
	}
	
	cell.accessoryType=UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        sprintf(gameName,"%s",[[(NSString *)[romlist objectAtIndex:indexPath.row] stringByDeletingPathExtension] UTF8String]);
        NSLog(@"gamename %s",gameName);
        launchGame=1;
        [[self navigationController] popViewControllerAnimated:NO];
    }
}

@end
