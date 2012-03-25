//
//  GameBrowserViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameBrowserViewController.h"
#import "OptGameInfoViewController.h"
#include "string.h"
#include "burner.h"
#include "fbaconf.h"
#include "DBHelper.h"

#define MAX_FILTER 3
//0: game name
//1: hardware
//2: genre

#define min(a,b) (a<b?a:b)

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
extern volatile int emuThread_running;
extern char gameInfo[64*1024];


int *listSectionIndexes;
int *listSortedList;
int *listSectionCount;
int listNbSection;

extern char gameName[64];
extern int launchGame;
static int cur_game_section,cur_game_row;
NSString *genreList[20]={
    @"H-Shooter",
    @"V-Shooter",
    @"Beat'em all",
    @"Versus Fighting",
    @"BIOS",
    @"Breakout",
    @"Casino",
    @"Ball Paddle",
    @"Maze",
    @"Minigames",
    @"Pinball",
    @"Platform",
    @"Puzzle",
    @"Quiz",
    @"Sport",
    @"Football",
    @"Misc",
    @"Mahjong",
    @"Racing",
    @"Shoot"    
};
NSMutableArray *filterEntries;


@implementation GameBrowserViewController
@synthesize tabView,btn_backToEmu,selgenrevc,btn_missing;

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

- (void)buildFilters {
    char *szName,*szLname;
    burn_supportedRoms=[[NSMutableArray alloc] initWithCapacity:nBurnDrvCount];
    int saveActiveDrv=nBurnDrvActive;
    for (int i=0;i<nBurnDrvCount;i++) {
        nBurnDrvActive=i;
        BurnDrvGetZipName(&szName,0);
        [burn_supportedRoms addObject:[[NSString stringWithFormat:@"%s",szName] lowercaseString]];
        //NSLog(@"%s;%08X;%s;%s",szName,BurnDrvGetGenreFlags(),BurnDrvGetTextA(DRV_FULLNAME),BurnDrvGetTextA(DRV_SYSTEM));
//        printf("cp %s.ico extract/\n",szName);
    }
    nBurnDrvActive=saveActiveDrv;
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.    
    
    selgenrevc=[[OptSelGenresViewController alloc] initWithNibName:@"OptSelGenresViewController" bundle:nil];
    
    sectionLbl=nil;
    sectionLblMin=nil;
    romlist=nil;
    romlistLbl=nil;
    rompath=nil;
    romavail=nil;
    romlistSystem=nil;
    romlistGenre=nil;
    listSectionIndexes=NULL;
    listSectionCount=NULL;
    listSortedList=NULL;
    listNbSection=0;
    
    if (ifba_conf.filter_type>=MAX_FILTER) ifba_conf.filter_type=0;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [selgenrevc release];
}

- (void)scanRomsDirs {
    NSError *error;
    NSArray *dirContent;
    NSFileManager *mFileMngr = [[NSFileManager alloc] init];
    NSString *cpath;
    NSString *file;
    NSArray *filetype_extROMFILE=[@"ZIP" componentsSeparatedByString:@","];    //,FBA ?
    
    if (listSortedList) free(listSortedList);
    if (listSectionIndexes) free(listSectionIndexes);
    if (listSectionCount) free(listSectionCount);
    listSortedList=NULL;
    listSectionIndexes=NULL;
    listSectionCount=NULL;
    listNbSection=0;
    if (romlist) [romlist release];
    if (romlistLbl) [romlistLbl release];
    if (rompath) [rompath release];
    if (romavail) [romavail release];
    if (romlistSystem) [romlistSystem release];
    if (romlistGenre) [romlistGenre release];
    if (sectionLbl) [sectionLbl release];
    if (sectionLblMin) [sectionLblMin release];
    
    romlist=[[NSMutableArray alloc] initWithCapacity:0];
    romlistLbl=[[NSMutableArray alloc] initWithCapacity:0];
    rompath=[[NSMutableArray alloc] initWithCapacity:0];
    romlistSystem=[[NSMutableArray alloc] initWithCapacity:0];
    romlistGenre=[[NSMutableArray alloc] initWithCapacity:0];
    romavail=[[NSMutableArray alloc] initWithCapacity:0];
    sectionLbl=[[NSMutableArray alloc] initWithCapacity:0];
    sectionLblMin=[[NSMutableArray alloc] initWithCapacity:0];
    
    cur_game_section=cur_game_row=-1;
    
    int saveActiveDrv=nBurnDrvActive;
    int currentIdx=0;
    
    if (ifba_conf.filter_missing) {
        int total_roms_nb=[burn_supportedRoms count];
        NSMutableArray *filelist,*filepath;
        
        filelist=[[NSMutableArray alloc] initWithCapacity:0];
        filepath=[[NSMutableArray alloc] initWithCapacity:0];
        
        for (int i=0;i<DIRS_MAX;i++) {
            if (szAppRomPaths[i][0]) cpath=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
            else cpath=nil;
            if (cpath) {
                dirContent=[mFileMngr contentsOfDirectoryAtPath:cpath error:&error];
                for (file in dirContent) {
                    NSString *extension=[[[file lastPathComponent] pathExtension] uppercaseString];
                    if ([filetype_extROMFILE indexOfObject:extension]!=NSNotFound) {
                        //got a file, check if it is in the list
                        [filelist addObject:[[[file lastPathComponent] stringByDeletingPathExtension] lowercaseString]];
                        [filepath addObject:cpath];
                    }
                }
            }
        }
        
        
        
        for (int i=0;i<total_roms_nb;i++) {
            nBurnDrvActive=i;
            int genre=BurnDrvGetGenreFlags();

            if (genre&(ifba_conf.filter_genre)) {
                [romlist addObject:[burn_supportedRoms objectAtIndex:i]];
                [romlistSystem addObject:[NSString stringWithFormat:@"%s",BurnDrvGetTextA(DRV_SYSTEM)] ];
                [romlistGenre addObject:[NSNumber numberWithInt:genre] ];
                //[romlistLbl addObject:[NSString stringWithFormat:@"%s/%d",BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];
                
                int tmpchar=BurnDrvGetTextA(DRV_FULLNAME)[0];
                if (tmpchar<'A') tmpchar='#';
                switch (ifba_conf.filter_type) {
                    case 2://genre
                        [romlistLbl addObject:[NSString stringWithFormat:@"%@/%s/%d",[self genreStr:genre],BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                        break;
                    case 1://system
                        [romlistLbl addObject:[NSString stringWithFormat:@"%s/%s/%d",BurnDrvGetTextA(DRV_SYSTEM),BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                        break;
                    case 0: //game name
                    default:
                        [romlistLbl addObject:[NSString stringWithFormat:@"%c/%s/%d",tmpchar,BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                        break;
                }
                
                //check if file is existing
                NSUInteger ind=[filelist indexOfObject:[burn_supportedRoms objectAtIndex:i]];
                if (ind!=NSNotFound) {                    
                    [rompath addObject:[filepath objectAtIndex:ind]];
                    [romavail addObject:[NSNumber numberWithBool:TRUE]];
                } else {
                    [rompath addObject:@""];
                    [romavail addObject:[NSNumber numberWithBool:NO]];
                }
            }
        }
        
        [filelist release];
        [filepath release];
    } else {
        
        
        for (int i=0;i<DIRS_MAX;i++) {
            if (szAppRomPaths[i][0]) cpath=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
            else cpath=nil;
            if (cpath) {
                dirContent=[mFileMngr contentsOfDirectoryAtPath:cpath error:&error];
                for (file in dirContent) {
                    NSString *extension=[[[file lastPathComponent] pathExtension] uppercaseString];
                    
                    if ([filetype_extROMFILE indexOfObject:extension]!=NSNotFound) {
                        NSUInteger ind;                                        
                        ind=[burn_supportedRoms indexOfObject:[[[file lastPathComponent] stringByDeletingPathExtension] lowercaseString]];
                        if (ind!=NSNotFound) {
                            nBurnDrvActive=ind;
                            int genre=BurnDrvGetGenreFlags();
                            if ((genre&(ifba_conf.filter_genre))!=0) {
                                int tmpchar=BurnDrvGetTextA(DRV_FULLNAME)[0];
                                if (tmpchar<'A') tmpchar='#';
                                [romlist addObject:[file stringByDeletingPathExtension] ];
                                [rompath addObject:cpath];                                                                
                                [romlistSystem addObject:[NSString stringWithFormat:@"%s",BurnDrvGetTextA(DRV_SYSTEM)] ];
                                [romlistGenre addObject:[NSNumber numberWithInt:genre] ];
                                
                                switch (ifba_conf.filter_type) {
                                    case 2://genre
                                        [romlistLbl addObject:[NSString stringWithFormat:@"%@/%s/%d",[self genreStr:genre],BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                                        break;
                                    case 1://system
                                        [romlistLbl addObject:[NSString stringWithFormat:@"%s/%s/%d",BurnDrvGetTextA(DRV_SYSTEM),BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                                        break;
                                    case 0: //game name
                                    default:
                                        [romlistLbl addObject:[NSString stringWithFormat:@"%c/%s/%d",tmpchar,BurnDrvGetTextA(DRV_FULLNAME),currentIdx++] ];                        
                                        break;
                                }
                            }
                            //NSLog(@"file: %@",file);
                        }
                    }
                }
            }
        }
    }
    [mFileMngr release];
    
    //Did we find games? if so, sort them
    if ([romlist count]) {
        int total=[romlist count];
        NSString *tmpStr1,*tmpStr2,*tmpStr;
        NSMutableArray *romlistLblSorted=[romlistLbl mutableCopy];
        [romlistLblSorted sortUsingSelector:@selector(caseInsensitiveCompare:)];
        
        tmpStr1=[romlistLblSorted objectAtIndex:0];
        tmpStr1=[tmpStr1 substringToIndex:[tmpStr1 rangeOfString:@"/"].location];
        listNbSection++;
        [sectionLbl addObject:tmpStr1];
        [sectionLblMin addObject:[tmpStr1 substringToIndex:min(2,[tmpStr1 length]) ]];
        for (int i=0;i<total-1;i++) {
            tmpStr1=[romlistLblSorted objectAtIndex:i];
            tmpStr1=[tmpStr1 substringToIndex:[tmpStr1 rangeOfString:@"/"].location];
            tmpStr2=[romlistLblSorted objectAtIndex:i+1];
            tmpStr2=[tmpStr2 substringToIndex:[tmpStr2 rangeOfString:@"/"].location];
            if ([tmpStr1 compare:tmpStr2]!=NSOrderedSame) {
                listNbSection++;
                [sectionLbl addObject:tmpStr2];
                [sectionLblMin addObject:[tmpStr2 substringToIndex:min(2,[tmpStr2 length])]];
            }            
        }
        
        listSectionIndexes=(int *)malloc(listNbSection*sizeof(int));
        listSortedList=(int *)malloc(total*sizeof(int));
        listSectionCount=(int *)malloc(listNbSection*sizeof(int));
        memset(listSectionIndexes,0,listNbSection*sizeof(int));
        memset(listSectionCount,0,listNbSection*sizeof(int));
        
        
        for (int i=0;i<total;i++) {
            tmpStr=[romlistLblSorted objectAtIndex:i];
            char j;
            int k;
            
            
            //get section nb
            /*j=[[tmpStr stringByDeletingLastPathComponent] UTF8String][0];
            if ((j>='a')&&(j<='z')) j+=1-'a';
            else if ((j>='A')&&(j<='Z')) j+=1-'A';
            else j=0;*/
            j=[sectionLbl indexOfObject:[tmpStr substringToIndex:[tmpStr rangeOfString:@"/"].location]];
            
            //get index in master list
            k=[[tmpStr lastPathComponent] intValue];
            
            //check if last game is found
       
            if ((cur_game_section==-1)&&gameName[0]) {
                if (strcasecmp(gameName,[[[romlist objectAtIndex:k] stringByDeletingPathExtension] UTF8String])==0) {
                    cur_game_section=j;
                    cur_game_row=listSectionCount[j];
                }
            }
            
            listSortedList[i]=k;
            listSectionCount[j]++;
        }
        for (int i=1;i<listNbSection;i++) {
            listSectionIndexes[i]=listSectionIndexes[i-1]+listSectionCount[i-1];
        }
        [romlistLblSorted release];
    }
    
    nBurnDrvActive=saveActiveDrv;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    cur_game_section=-1;
    
    if (ifba_conf.filter_missing) [btn_missing setStyle:UIBarButtonItemStyleDone];
    else [btn_missing setStyle:UIBarButtonItemStyleBordered];
    
    [self buildFilters];
    
    [self scanRomsDirs];
    [[self tabView] reloadData];
    if (cur_game_section>=0) [self.tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:cur_game_row inSection:cur_game_section] animated:FALSE scrollPosition:UITableViewScrollPositionMiddle];
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [burn_supportedRoms release];
    
    if (romlist) [romlist release];
    romlist=nil;
    if (romlistLbl) [romlistLbl release];
    romlistLbl=nil;
    if (rompath) [rompath release];
    rompath=nil;
    if (romavail) [romavail release];
    romavail=nil;
    if (romlistSystem) [romlistSystem release];
    romlistSystem=nil;
    if (romlistGenre) [romlistGenre release];
    romlistGenre=nil;
    if (listSectionCount) free(listSectionCount);
    listSectionCount=NULL;
    if (listSectionIndexes) free(listSectionIndexes);
    listSectionIndexes=NULL;
    if (listSortedList) free(listSortedList);
    listSortedList=NULL;
      
    if (sectionLbl) [sectionLbl release];
    sectionLbl=nil;
    if (sectionLblMin) [sectionLblMin release];
    sectionLblMin=nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {    
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [tabView reloadData];
}


#pragma mark - UI Actions

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return listNbSection;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return listSectionCount[section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {    
    if (listSectionCount[section]) {
        NSString *tmpStr=[romlistLbl objectAtIndex:listSortedList[listSectionIndexes[section]]];
        return [tmpStr substringToIndex:[tmpStr rangeOfString:@"/"].location];
    }
    return nil;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionLblMin;
}

-(NSString*) genreStr:(int)genre {
    NSString *result=[NSString stringWithFormat:@""];
    int j=0;
    for (int i=0;i<20;i++) {
        if ((1<<i)&genre) {
            
            if (j==0) result=[result stringByAppendingString:genreList[i]];
            else result=[result stringByAppendingFormat:@",%@",genreList[i]];
            j=1;
        }
    }
    return result;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    const NSInteger TOP_LABEL_TAG = 1001;
	const NSInteger BOTTOM_LABEL_TAG = 1002;
    const NSInteger ICON_TAG = 1003;
	UILabel *topLabel;
	UILabel *bottomLabel;
    UIImageView *iconview;
	
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		//
		// Create the label for the top row of text
		//
		topLabel = [[[UILabel alloc] init] autorelease];
		[cell.contentView addSubview:topLabel];
		
		//
		// Configure the properties for the text that are the same on every row
		//
		topLabel.tag = TOP_LABEL_TAG;
		topLabel.backgroundColor = [UIColor clearColor];
		topLabel.textColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0];
		topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
		topLabel.font = [UIFont boldSystemFontOfSize:16];
        topLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
		
		//
		// Create the label for the top row of text
		//
		bottomLabel = [[[UILabel alloc] init] autorelease];
		[cell.contentView addSubview:bottomLabel];
		//
		// Configure the properties for the text that are the same on every row
		//
		bottomLabel.tag = BOTTOM_LABEL_TAG;
		bottomLabel.backgroundColor = [UIColor clearColor];
		bottomLabel.textColor = [UIColor colorWithRed:0.0 green:0 blue:0.1 alpha:1.0];
		bottomLabel.highlightedTextColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
		bottomLabel.font = [UIFont systemFontOfSize:12];
        bottomLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        
        iconview=[[[UIImageView alloc] init] autorelease];
        iconview.tag=ICON_TAG;
        [cell.contentView addSubview:iconview];
    } else {
		topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
		bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
        iconview=(UIImageView*)[cell viewWithTag:ICON_TAG];
	}
    
    iconview.frame=CGRectMake(0,0,32,32);    
                                                          
    bottomLabel.frame = CGRectMake( 32/*1.0 * cell.indentationWidth*/,
								   24,
								   tableView.bounds.size.width - 32-32/*1.0 * cell.indentationWidth*/-40,
								   14);
	topLabel.frame = CGRectMake( 32/*1.0 * cell.indentationWidth*/,
								2,
								tableView.bounds.size.width - 32-32/*1.0 * cell.indentationWidth*/-40,
								20);
    
    int index=listSortedList[listSectionIndexes[indexPath.section]+indexPath.row];
    
    if (ifba_conf.filter_missing) {
        NSNumber *nb=[romavail objectAtIndex:index];
        if ([nb boolValue]==NO) {
            topLabel.textColor = [UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1.0];
            bottomLabel.textColor = [UIColor colorWithRed:.4 green:.4 blue:.5 alpha:1.0];
        } else {
            topLabel.textColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0];
            bottomLabel.textColor = [UIColor colorWithRed:0.0 green:0 blue:0.1 alpha:1.0];
        }
    } else {
        topLabel.textColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0];
        bottomLabel.textColor = [UIColor colorWithRed:0.05 green:0 blue:0.2 alpha:1.0];
    }
    UIImage *img=[UIImage imageNamed:[NSString stringWithFormat:@"%@.ico",[romlist objectAtIndex:index]]];
    if (img==nil) {
        if ([[romlist objectAtIndex:index] rangeOfString:@"md_"].location!=NSNotFound) {
            img=[UIImage imageNamed:@"md_icon.gif"];
        } else if ([[romlist objectAtIndex:index] rangeOfString:@"tg_"].location!=NSNotFound) {
            img=[UIImage imageNamed:@"tg_icon.gif"];
        } else if ([[romlist objectAtIndex:index] rangeOfString:@"pce_"].location!=NSNotFound) {
            img=[UIImage imageNamed:@"pce_icon.png"];
        } else if ([[romlist objectAtIndex:index] rangeOfString:@"sgx_"].location!=NSNotFound) {
            img=[UIImage imageNamed:@"sgx_icon.gif"];
        }
    }
    iconview.image=img;
    
    
    NSString *tmpStr=[[romlistLbl objectAtIndex:index] stringByDeletingLastPathComponent];    
    topLabel.text=[tmpStr substringFromIndex:[tmpStr rangeOfString:@"/"].location+1  ];
    bottomLabel.text=[NSString stringWithFormat:@"%@ - %@ - %@",[romlist objectAtIndex:index],[romlistSystem objectAtIndex:index],[self genreStr:[(NSNumber*)[romlistGenre objectAtIndex:index] intValue]]   ];
    
    //cell.textLabel.text=[romlistLbl[indexPath.section] objectAtIndex:indexPath.row];	
	cell.accessoryType=UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    ;
    int index=listSortedList[listSectionIndexes[indexPath.section]+indexPath.row];
    DBHelper::getGameInfo([[(NSString *)[romlist objectAtIndex:index] stringByDeletingPathExtension] UTF8String], gameInfo);
    if (gameInfo[0]) {
        OptGameInfoViewController *infovc;
        infovc = [[OptGameInfoViewController alloc] initWithNibName:@"OptGameInfoViewController" bundle:nil];
        [self.navigationController pushViewController:infovc animated:YES];
        [infovc release];        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int index=listSortedList[listSectionIndexes[indexPath.section]+indexPath.row];
    if (ifba_conf.filter_missing) {        
        NSNumber *nb=[romavail objectAtIndex:index];
        if (![nb boolValue]) return;
    }
    
    sprintf(gameName,"%s",[[(NSString *)[romlist objectAtIndex:index] stringByDeletingPathExtension] UTF8String]);
    launchGame=1;
    //change dir
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:[rompath objectAtIndex:index]];
    
//    NSLog(@"gamename: %s",gameName);
//    NSLog(@"rompath: %@",[rompath objectAtIndex:index]);
    
    [[self navigationController] popViewControllerAnimated:NO];
}

/*- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        char tmp_str[512];
#ifdef RELEASE_DEBUG    
        sprintf(tmp_str,"%s/%s_%02x", debug_root_path, gameName,indexPath.row);
#else        
        sprintf(tmp_str,"/var/mobile/Documents/iFBA/%s_%02x",gameName,indexPath.row);
#endif        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%s.fs",tmp_str] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%s.png",tmp_str] error:&error];
        
        [self scanFiles];
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.    
    return NO;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}*/

#pragma Actions

-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}
-(IBAction) showFavorites{
    UIAlertView *alertMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:NSLocalizedString(@"Not dev yet",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alertMsg show];
    
}
-(IBAction) showMostplayed{
    UIAlertView *alertMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:NSLocalizedString(@"Not dev yet",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alertMsg show];
}
-(IBAction) showGenres{
    [self presentSemiModalViewController:selgenrevc];    
    [tabView reloadData];            
}
-(IBAction) changeFilter:(id)sender {
    ifba_conf.filter_type++;
    if (ifba_conf.filter_type==MAX_FILTER) ifba_conf.filter_type=0;
    cur_game_section=-1;
    [self scanRomsDirs];
    [tabView reloadData];
    if (cur_game_section>=0) [self.tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:cur_game_row inSection:cur_game_section] animated:FALSE scrollPosition:UITableViewScrollPositionMiddle];
}
-(IBAction) showMissing:(id)sender{
    if (ifba_conf.filter_missing) ifba_conf.filter_missing=0;
    else ifba_conf.filter_missing=1;
    
    if (ifba_conf.filter_missing) [(UIBarButtonItem*)sender setStyle:UIBarButtonItemStyleDone];
    else [(UIBarButtonItem*)sender setStyle:UIBarButtonItemStyleBordered];
    cur_game_section=-1;
    [self scanRomsDirs];
    [tabView reloadData];
    if (cur_game_section>=0) [self.tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:cur_game_row inSection:cur_game_section] animated:FALSE scrollPosition:UITableViewScrollPositionMiddle];
}
@end
