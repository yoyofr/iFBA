//
//  OptROMSSetPathsViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptROMSSetPathsViewController.h"
#include "burner.h"
#import "fbaconf.h"

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
extern int szAppRomPathsSelected;
static char currentPath[MAX_PATH];
static NSMutableArray *dirlist;


@implementation OptROMSSetPathsViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Choose ROMS Path",@"");
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
    
    strcpy(currentPath,szAppRomPaths[szAppRomPathsSelected]);
    if (currentPath[strlen(currentPath)-1]=='/') currentPath[strlen(currentPath)]=0;
    [self scanDirs];
    [[self tabView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [dirlist release];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


#pragma scan dir


- (void) scanDirs {
    NSError *error;
    NSArray *dirContent;
    NSFileManager *mFileMngr = [[NSFileManager alloc] init];
    NSString *cpath;
    NSString *file;
    BOOL isDir;
    
    dirlist=[[NSMutableArray alloc] initWithCapacity:0];
    
    if (currentPath[0]==0) {
        strcpy(currentPath,"/var/mobile/Documents/iFBA");
    }
    cpath=[NSString stringWithFormat:@"%s",currentPath];
    if ([cpath compare:@"/"]!=NSOrderedSame) {//Not at root level, add ".." dir
        [dirlist addObject:@".."];
    }

    dirContent=[mFileMngr contentsOfDirectoryAtPath:cpath error:&error];
    for (file in dirContent) {
        
        [mFileMngr fileExistsAtPath:[cpath stringByAppendingFormat:@"/%@",file] isDirectory:&isDir];
        
        if (isDir) {
            [dirlist addObject:file];
        }
    }
    [mFileMngr release];    
}

- (void) dealloc {
    
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) return 1;
    if (section==1) return 1;
    if (section==2) return [dirlist count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    if (section==0) footer=NSLocalizedString(@"Tap selected dir above to validate",@"");
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    
    if (indexPath.section==0) {
        cell.accessoryView=nil;
        cell.accessoryType=UITableViewCellAccessoryNone;
        cell.textLabel.text=[NSString stringWithFormat:@"%s",currentPath];
    }  else if (indexPath.section==1) {
        cell.accessoryView=nil;
        cell.accessoryType=UITableViewCellAccessoryNone;
        cell.textLabel.text=NSLocalizedString(@"Cancel", nil);
    } else if (indexPath.section==2) {
        cell.accessoryView=nil;
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;    
        cell.textLabel.text=[dirlist objectAtIndex:indexPath.row];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) { //Validate new path
        if (currentPath[strlen(currentPath)-1]!='/') strcat(currentPath,"/");
        strcpy(szAppRomPaths[szAppRomPathsSelected],currentPath);        
        [self.navigationController popViewControllerAnimated:YES];
    } else if (indexPath.section==1) { //Cancel and go back to roms paths list
        [self.navigationController popViewControllerAnimated:YES];
    } else if (indexPath.section==2) {//Select a dir
        NSString *sel=[dirlist objectAtIndex:indexPath.row];
        if ([sel compare:@".."]==NSOrderedSame) {
            NSString *newPath=[NSString stringWithFormat:@"%s",currentPath];
            strcpy(currentPath,[[newPath stringByDeletingLastPathComponent] UTF8String]);
        } else {
            NSString *newPath;
            if (strcmp(currentPath,"/")==0) newPath=[NSString stringWithFormat:@"/%@",sel];
            else newPath=[NSString stringWithFormat:@"%s/%@",currentPath,sel];
            strcpy(currentPath,[newPath UTF8String]);
        }        
        [self scanDirs];
        [tableView reloadData];
    }
}


@end
