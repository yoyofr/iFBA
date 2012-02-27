//
//  GameBrowserViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameBrowserViewController.h"
#include "string.h"

#include "burnint.h"


extern char gameName[64];
extern int launchGame;

@implementation GameBrowserViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title=NSLocalizedString(@"Select a game",@"");
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
    [burn_supportedRoms release];
}

- (void)buildFilters {
    char *szName;
    NSMutableArray *burn_supportedRoms=[[NSMutableArray alloc] initWithCapacity:nBurnDrvCount];
    //szName=(char*)malloc(256);
    for (int i=0;i<nBurnDrvCount;i++) {
        nBurnDrvActive=i;
        BurnDrvGetZipName(&szName,0);
        [burn_supportedRoms addObject:[[NSString stringWithFormat:@"%s",szName] lowercaseString]];
    }
    //free(szName);
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.    
    
    indexTitles = [[NSMutableArray alloc] init];
	[indexTitles addObject:@"#"];
	[indexTitles addObject:@"A"];
	[indexTitles addObject:@"B"];
	[indexTitles addObject:@"C"];
	[indexTitles addObject:@"D"];
	[indexTitles addObject:@"E"];
	[indexTitles addObject:@"F"];
	[indexTitles addObject:@"G"];
	[indexTitles addObject:@"H"];	
	[indexTitles addObject:@"I"];
	[indexTitles addObject:@"J"];
	[indexTitles addObject:@"K"];
	[indexTitles addObject:@"L"];
	[indexTitles addObject:@"M"];
	[indexTitles addObject:@"N"];
	[indexTitles addObject:@"O"];
	[indexTitles addObject:@"P"];
	[indexTitles addObject:@"Q"];
	[indexTitles addObject:@"R"];
	[indexTitles addObject:@"S"];
	[indexTitles addObject:@"T"];
	[indexTitles addObject:@"U"];
	[indexTitles addObject:@"V"];
	[indexTitles addObject:@"W"];
	[indexTitles addObject:@"X"];
	[indexTitles addObject:@"Y"];
	[indexTitles addObject:@"Z"];
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
    
    [self buildFilters];    
    
    for (int i=0;i<28;i++) {
        romlist[i]=[[NSMutableArray alloc] initWithCapacity:0];
    }
    
    dirContent=[mFileMngr subpathsOfDirectoryAtPath:cpath error:&error];
    for (file in dirContent) {
        NSString *extension=[[[file lastPathComponent] pathExtension] uppercaseString];
        if ([filetype_extROMFILE indexOfObject:extension]!=NSNotFound) {
            //NSLog(@"file; %@",[file lastPathComponent]);
            if ([burn_supportedRoms indexOfObject:[[file lastPathComponent] lowercaseString]]!=NSNotFound) {
                char i;
                i=[[file lastPathComponent] UTF8String][0];
                if ((i>='a')&&(i<='z')) i+=1-'a';
                else if ((i>='A')&&(i<='Z')) i+=1-'A';
                else i=0;
                [romlist[i] addObject:file];
            }
        }
    }
    [mFileMngr release];
    
    [burn_supportedRoms release];    
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
    for (int i=0;i<28;i++) [romlist[i] release];
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
	return 27;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [romlist[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([romlist[section] count]) return [indexTitles objectAtIndex:section];
    else return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return indexTitles;    
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
        cell.textLabel.text=[romlist[indexPath.section] objectAtIndex:indexPath.row];
	
	cell.accessoryType=UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        sprintf(gameName,"%s",[[(NSString *)[romlist[indexPath.section] objectAtIndex:indexPath.row] stringByDeletingPathExtension] UTF8String]);
        NSLog(@"gamename %s",gameName);
        launchGame=1;
        [[self navigationController] popViewControllerAnimated:NO];
}

@end
