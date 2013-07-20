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

extern char debug_root_path[512];

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
extern int szAppRomPathsSelected;
static char currentPath[MAX_PATH];
static NSMutableArray *dirlist;

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;


@implementation OptROMSSetPathsViewController
@synthesize tabView,btn_backToEmu,emuvc;

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
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    //ICADE & Wiimote
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    [iCaderv changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;
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
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }
    
    strcpy(currentPath,szAppRomPaths[szAppRomPathsSelected]);
    if (currentPath[strlen(currentPath)-1]=='/') currentPath[strlen(currentPath)]=0;
    [self scanDirs];
    [[self tabView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
    [dirlist release];

    [[[UIApplication sharedApplication] delegate] saveSettings];
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
#ifdef RELEASE_DEBUG
        strcpy(currentPath,debug_root_path);
#else
        strcpy(currentPath,"/var/mobile/Documents/iFBA");
#endif
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
        cell.textLabel.lineBreakMode=NSLineBreakByTruncatingMiddle;
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


-(IBAction) backToEmu {
//    launchGame=2;
//    [self.navigationController popToRootViewControllerAnimated:NO];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
    
    [self.navigationController pushViewController:emuvc animated:NO];

}

#pragma Wiimote/iCP support
#define WII_BUTTON_UP(A) (wiimoteBtnState&A)&& !(pressedBtn&A)
-(void) checkWiimote {
    if (num_of_joys==0) return;
    int pressedBtn=iOS_wiimote_check(&(joys[0]));
    
    if (WII_BUTTON_UP(WII_JOY_DOWN)) {
        [self buttonUp:iCadeJoystickDown];
    } else if (WII_BUTTON_UP(WII_JOY_UP)) {
        [self buttonUp:iCadeJoystickUp];
    } else if (WII_BUTTON_UP(WII_JOY_LEFT)) {
        [self buttonUp:iCadeJoystickLeft];
    } else if (WII_BUTTON_UP(WII_JOY_RIGHT)) {
        [self buttonUp:iCadeJoystickRight];
    } else if (WII_BUTTON_UP(WII_JOY_A)) {
        [self buttonUp:iCadeButtonA];
    } else if (WII_BUTTON_UP(WII_JOY_B)) {
        [self buttonUp:iCadeButtonB];
    } else if (WII_BUTTON_UP(WII_JOY_C)) {
        [self buttonUp:iCadeButtonC];
    } else if (WII_BUTTON_UP(WII_JOY_D)) {
        [self buttonUp:iCadeButtonD];
    } else if (WII_BUTTON_UP(WII_JOY_E)) {
        [self buttonUp:iCadeButtonE];
    } else if (WII_BUTTON_UP(WII_JOY_F)) {
        [self buttonUp:iCadeButtonF];
    } else if (WII_BUTTON_UP(WII_JOY_G)) {
        [self buttonUp:iCadeButtonG];
    } else if (WII_BUTTON_UP(WII_JOY_H)) {
        [self buttonUp:iCadeButtonH];
    }
    
    
    wiimoteBtnState=pressedBtn;
}


#pragma Icade support
/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/
- (void)buttonDown:(iCadeState)button {
}
- (void)buttonUp:(iCadeState)button {
    if (ui_currentIndex_s==-1) {
        ui_currentIndex_s=ui_currentIndex_r=0;
    }
    else {
        if (button&iCadeJoystickDown) {            
            if (ui_currentIndex_r<[tabView numberOfRowsInSection:ui_currentIndex_s]-1) ui_currentIndex_r++; //next row
            else { //next section
                if (ui_currentIndex_s<[tabView numberOfSections]-1) {
                    ui_currentIndex_s++;ui_currentIndex_r=0; //next section
                } else {
                    ui_currentIndex_s=ui_currentIndex_r=0; //loop to 1st section
                }
            }             
        } else if (button&iCadeJoystickUp) {
            if (ui_currentIndex_r>0) ui_currentIndex_r--; //prev row            
            else { //prev section
                if (ui_currentIndex_s>0) {
                    ui_currentIndex_s--;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //next section
                } else {
                    ui_currentIndex_s=[tabView numberOfSections]-1;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //loop to 1st section
                }
            }
        } else if (button&iCadeButtonA) { //validate                        
            [self tableView:tabView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s]];
            ui_currentIndex_r=0;
            
        } else if (button&iCadeButtonB) { //back
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    [tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}


@end
