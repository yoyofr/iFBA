//
//  OptSaveStateViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
extern char debug_root_path[512];
#import <QuartzCore/QuartzCore.h>
#import "OptSaveStateViewController.h"
#import "OptROMSSetPathsViewController.h"
#include "burner.h"
#import "fbaconf.h"
extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];
static int slot[10];
static int current_slot,pad_action,cur_action;

int MakeScreenShot(int index);
int StatedLoad(int slot);
int StatedSave(int slot);

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;
static int selectedSlot;


@implementation OptSaveStateViewController
@synthesize tabView,btn_backToEmu,imgview;
@synthesize btn_load,btn_save;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"ROMS Paths",@"");
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
    [[imgview layer] setCornerRadius:15.0];	
	[[imgview layer] setBorderWidth:3.0];
	[[imgview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    
    //ICADE & Wiimote
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
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

- (void)scanFiles {
    char tmp_str[512];
    FILE *f;
    for (int i=0;i<10;i++) {
#ifdef RELEASE_DEBUG    
        sprintf(tmp_str,"%s/%s_%02x.fs", debug_root_path, gameName,i);
#else        
        sprintf(tmp_str,"/var/mobile/Documents/iFBA/%s_%02x.fs",gameName,i);
#endif        
        f=fopen(tmp_str,"rb");
        if (f) {
            slot[i]=1;
            fclose(f);
        } else slot[i]=0;
    }    
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
    current_slot=-1;
    pad_action=0;
    cur_action=0;
    btn_load.hidden=YES;
    btn_save.hidden=YES;
    
    [self scanFiles];
    [tabView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
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
    return 10;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    if (slot[indexPath.row]) {
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
    cell.textLabel.text=[NSString stringWithFormat:@"Slot %d",indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    current_slot=indexPath.row;
    if (slot[indexPath.row]) {
        char tmp_str[512];
#ifdef RELEASE_DEBUG    
        sprintf(tmp_str,"%s/%s_%02x.png", debug_root_path, gameName,indexPath.row);
#else        
        sprintf(tmp_str,"/var/mobile/Documents/iFBA/%s_%02x.png",gameName,indexPath.row);
#endif        
        [imgview setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%s",tmp_str]]];        
        
        btn_load.hidden=NO;
        
        if (pad_action) {
            pad_action=2;
            cur_action=2;
            [btn_load setHighlighted:YES];
            [btn_save setHighlighted:NO];
        }
    } else {
        [imgview setImage:nil];
        btn_load.hidden=YES;
        if (pad_action) {
            pad_action=1;
            cur_action=1;
            [btn_load setHighlighted:NO];
            [btn_save setHighlighted:YES];
        }
    }
    btn_save.hidden=NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
    if (slot[indexPath.row]) return YES;
    return NO;
}

#pragma Actions


-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(IBAction) saveState {
    if (current_slot==-1) return;
    StatedSave(current_slot);
    MakeScreenShot(current_slot);
/*    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];    */
    
    [self scanFiles];
    [tabView reloadData];
    
    char tmp_str[512];
    FILE *f;
#ifdef RELEASE_DEBUG    
    sprintf(tmp_str,"%s/%s_%02x.png", debug_root_path, gameName,current_slot);
#else        
    sprintf(tmp_str,"/var/mobile/Documents/iFBA/%s_%02x.png",gameName,current_slot);
#endif            
    [imgview setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%s",tmp_str]]];
    
    if (slot[current_slot]) btn_load.hidden=NO;     
}
-(IBAction) loadState {
    if (current_slot==-1) return;    
    StatedLoad(current_slot);
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
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
            if (pad_action) {
            } else {
            if (ui_currentIndex_r<[tabView numberOfRowsInSection:ui_currentIndex_s]-1) ui_currentIndex_r++; //next row
            else { //next section
                if (ui_currentIndex_s<[tabView numberOfSections]-1) {
                    ui_currentIndex_s++;ui_currentIndex_r=0; //next section
                } else {
                    ui_currentIndex_s=ui_currentIndex_r=0; //loop to 1st section
                }
            }
            }
        } else if (button&iCadeJoystickUp) {
            if (pad_action) {                
            } else {
            if (ui_currentIndex_r>0) ui_currentIndex_r--; //prev row            
            else { //prev section
                if (ui_currentIndex_s>0) {
                    ui_currentIndex_s--;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //next section
                } else {
                    ui_currentIndex_s=[tabView numberOfSections]-1;ui_currentIndex_r=[tabView numberOfRowsInSection:ui_currentIndex_s]-1; //loop to 1st section
                }
            }
            }
        } else if (button&iCadeButtonA) { //validate
            if (pad_action) {
                if (cur_action==2) {//load
                    [self loadState];
                } else if (cur_action==1) {//save
                    [self saveState];
                }
            } else {
            pad_action=1;            
            [self tableView:tabView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s]];            
            }
        } else if (button&iCadeButtonB) { //back
            if (pad_action) {
                pad_action=cur_action=0;
                [btn_load setHighlighted:NO];
                [btn_save setHighlighted:NO];
            } else [[self navigationController] popViewControllerAnimated:YES];
        } else if (button&iCadeJoystickLeft) {
            if (pad_action==2) {
                if (cur_action==2) cur_action=1;
                else cur_action=2;
            }
            if (cur_action==1) [btn_save setHighlighted:YES];
            else [btn_save setHighlighted:NO];
            if (cur_action==2) [btn_load setHighlighted:YES];
            else [btn_load setHighlighted:NO];
        } else if (button&iCadeJoystickRight) {
            if (pad_action==2) {
                if (cur_action==2) cur_action=1;
                else cur_action=2;
            }
            if (cur_action==1) [btn_save setHighlighted:YES];
            else [btn_save setHighlighted:NO];
            if (cur_action==2) [btn_load setHighlighted:YES];
            else [btn_load setHighlighted:NO];
        }
    }    
    if (pad_action==0) [tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}


@end
