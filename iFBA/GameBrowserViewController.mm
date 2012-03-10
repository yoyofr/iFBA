//
//  GameBrowserViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameBrowserViewController.h"
#include "string.h"
#include "burner.h"

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];


extern char gameName[64];
extern int launchGame;
static int cur_game_section,cur_game_row;

@implementation GameBrowserViewController
@synthesize tabView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title=NSLocalizedString(@"Select a game",@"");
        //        self.tabView.sectionHeaderHeight = 0;
        self.tabView.sectionFooterHeight = 0;
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
    [indexTitles release];
}

- (void)buildFilters {
    char *szName,*szLname;
    burn_supportedRoms=[[NSMutableArray alloc] initWithCapacity:nBurnDrvCount];
    //burn_supportedRomsNames=[[NSMutableArray alloc] initWithCapacity:nBurnDrvCount];
    //szName=(char*)malloc(256);
    int saveActiveDrv=nBurnDrvActive;
    for (int i=0;i<nBurnDrvCount;i++) {
        nBurnDrvActive=i;
        BurnDrvGetZipName(&szName,0);
        [burn_supportedRoms addObject:[[NSString stringWithFormat:@"%s",szName] lowercaseString]];
        //[burn_supportedRomsNames addObject:[[NSString stringWithFormat:@"%s",BurnDrvGetTextA(DRV_FULLNAME)] lowercaseString]];
        //NSLog(@"%s;%s;%s",szName,BurnDrvGetTextA(DRV_FULLNAME),BurnDrvGetTextA(DRV_SYSTEM));
    }
    nBurnDrvActive=saveActiveDrv;
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
/*
 int qsort_ComparePlEntries(const void *entryA, const void *entryB) {
 NSString *strA,*strB;
 NSComparisonResult res;
 strA=((t_plPlaylist_entry*)entryA)->mPlaylistFilename;
 strB=((t_plPlaylist_entry*)entryB)->mPlaylistFilename;
 res=[strA localizedCaseInsensitiveCompare:strB];
 if (res==NSOrderedAscending) return -1;
 if (res==NSOrderedSame) return 0;
 return 1; //NSOrderedDescending
 }
 qsort(mPlaylist,mPlaylist_size,sizeof(t_plPlaylist_entry),qsort_ComparePlEntries);
 */
- (void)scanRomsDirs {
    NSError *error;
    NSArray *dirContent;
    NSFileManager *mFileMngr = [[NSFileManager alloc] init];
    NSString *cpath;
    NSString *file;
    NSArray *filetype_extROMFILE=[@"ZIP" componentsSeparatedByString:@","];    //,FBA ?
    
    [self buildFilters];    
    
    //Master unsorted list in [27]
    for (int i=0;i<28;i++) {
        romlist[i]=[[NSMutableArray alloc] initWithCapacity:0];
        romlistLbl[i]=[[NSMutableArray alloc] initWithCapacity:0];
        rompath[i]=[[NSMutableArray alloc] initWithCapacity:0];
    }
    
    cur_game_section=cur_game_row=-1;
    
    int saveActiveDrv=nBurnDrvActive;
    
    for (int i=0;i<DIRS_MAX;i++) {
        if (szAppRomPaths[i][0]) cpath=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
        else cpath=nil;
        if (cpath) {
            dirContent=[mFileMngr contentsOfDirectoryAtPath:cpath error:&error];
            for (file in dirContent) {
                NSString *extension=[[[file lastPathComponent] pathExtension] uppercaseString];
                if ([filetype_extROMFILE indexOfObject:extension]!=NSNotFound) {
                    NSUInteger ind;
                    //NSLog(@"file; %@",[file lastPathComponent]);
                    ind=[burn_supportedRoms indexOfObject:[[file lastPathComponent] lowercaseString]];
                    if (ind!=NSNotFound) {
                        [romlist[27] addObject:file];
                        [rompath[27] addObject:cpath];
                        nBurnDrvActive=ind;
                        [romlistLbl[27] addObject:[NSString stringWithFormat:@"%s",BurnDrvGetTextA(DRV_FULLNAME)] ];
                    }
                }
            }
        }
    }
    [mFileMngr release];
    
    //Did we find games? if so, sort them
    if ([romlist[27] count]) {
        int total=[romlist[27] count];
        for (int i=0;i<total;i++) {
            NSString *tmpStr=[romlistLbl[27] objectAtIndex:i];
            char j;
            j=[tmpStr UTF8String][0];
            if ((j>='a')&&(j<='z')) j+=1-'a';
            else if ((j>='A')&&(j<='Z')) j+=1-'A';
            else j=0;
            [romlistLbl[j] addObject:tmpStr];
            tmpStr=[romlist[27] objectAtIndex:i];
            [romlist[j] addObject:tmpStr];
            [rompath[j] addObject:[rompath[27] objectAtIndex:i]];
            if (gameName[0]&&(cur_game_section<0)) {
                if (strcmp(gameName,[[[tmpStr lastPathComponent] stringByDeletingPathExtension] UTF8String])==0) {
                    cur_game_section=j;
                    cur_game_row=[romlist[j] count]-1;
                }
            }
            
        }
    }
    
    [burn_supportedRoms release];   
    //[burn_supportedRomsNames release];
    
    nBurnDrvActive=saveActiveDrv;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scanRomsDirs];
    [[self tabView] reloadData];
    if (cur_game_section>=0) [self.tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:cur_game_row inSection:cur_game_section] animated:FALSE scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    for (int i=0;i<28;i++) {
        [romlist[i] release];
        [romlistLbl[i] release];
        [rompath[i] release];
    }
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
    return [romlistLbl[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([romlistLbl[section] count]) return [indexTitles objectAtIndex:section];
    else return nil;
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
    
    cell.textLabel.text=[romlistLbl[indexPath.section] objectAtIndex:indexPath.row];	
	cell.accessoryType=UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    sprintf(gameName,"%s",[[(NSString *)[romlist[indexPath.section] objectAtIndex:indexPath.row] stringByDeletingPathExtension] UTF8String]);
    NSLog(@"gamename %s",gameName);
    launchGame=1;
    //change dir
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:[rompath[indexPath.section] objectAtIndex:indexPath.row]];
    
    [[self navigationController] popViewControllerAnimated:NO];
}

@end
