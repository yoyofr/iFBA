//
//  MenuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MenuViewController.h"
#import "EmuViewController.h"
#import "GameBrowserViewController.h"
#import "OptionsViewController.h"
#import "OptDIPSWViewController.h"
#import "OptSaveStateViewController.h"
#import "OptGameInfoViewController.h"
#include "DBHelper.h"
#include "fbaconf.h"

extern char gameInfo[64*1024];

extern int pendingReset;
extern unsigned int nBurnDrvCount;
extern int launchGame;
extern char gameName[64];
extern volatile int emuThread_running;
extern int nShouldExit;
extern int device_isIpad;


//iCade
#import "iCadeReaderView.h"
static int ui_currentIndex_s,ui_currentIndex_r;
static iCadeReaderView *iCaderv;

@implementation MenuViewController
@synthesize emuvc,gamebrowservc,optionsvc,dipswvc,statevc;
@synthesize tabView;
@synthesize btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title=[NSString stringWithFormat:@"iFBA v%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc{
    [emuvc dealloc];
    [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.    
    
    emuvc = [[EmuViewController alloc] initWithNibName:@"EmuViewController" bundle:nil];
    
    tabView.backgroundView=nil;
    tabView.backgroundView=[[[UIView alloc] init] autorelease];
    
    //ICADE 
    ui_currentIndex_s=-1;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
}


- (void)viewDidUnload {
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
    if (ui_currentIndex_s>=0) {
        [tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
#if BENCH_MODE
    strcpy(gameName,"sfiii3");
    launchGame=1;
    //change dir
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:@"/var/mobile/Documents/ROMS/"];    
#endif
    
    if (launchGame) {
        //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController pushViewController:emuvc animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];    
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //    [emuvc shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    //    [gamebrowservc shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    return YES;
}

#pragma mark - UI Actions
-(IBAction) backToEmu {        
    [self.navigationController pushViewController:emuvc animated:NO];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    int nbRows=0;
    switch (section) {
        case 0:
            if (emuThread_running) nbRows=7;
            else nbRows=1;
            break;
        case 1:
            nbRows=1;
            break;
        case 2:
            nbRows=1;
            break;
        case 3:
            nbRows=1;
            break;
        case 4:
            nbRows=1;
            break;
    }
	return nbRows;
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
    //cell.backgroundView.backgroundColor=[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.5f];
    //cell.contentView.backgroundColor=[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.5f];
    /*    for (int i=0;i<[cell.subviews count];i++) {
     [[cell.subviews objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.5f]];
     }*/
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
	switch (indexPath.section) {
        case 0:
            if (emuThread_running) {
                if (indexPath.row==0) {
                    cell.textLabel.text=[NSString stringWithFormat:NSLocalizedString(@"Back to %s",@""),gameName];
                    //                    cell.backgroundColor=[UIColor colorWithRed:0.95f green:1.0f blue:0.95f alpha:1.0f];
                } else if (indexPath.row==1) cell.textLabel.text=NSLocalizedString(@"Save State",@"");
                else if (indexPath.row==2) cell.textLabel.text=NSLocalizedString(@"DIPSW",@"");
                else if (indexPath.row==3) {
                    //                    if (pendingReset) cell.accessoryType=UITableViewCellAccessoryCheckmark;
                    //                    else 
                    cell.accessoryType=UITableViewCellAccessoryNone;
                    cell.textLabel.text=@"Reset";
                    //                    cell.backgroundColor=[UIColor colorWithRed:1.0f green:0.7f blue:0.7f alpha:1.0f];
                } else if (indexPath.row==4) {
                    cell.textLabel.text=NSLocalizedString(@"Information",@"");
                } else if (indexPath.row==5) cell.textLabel.text=NSLocalizedString(@"Close game",@"");
                else if (indexPath.row==6) {
                    cell.textLabel.text=NSLocalizedString(@"Load game",@"");
                    //                    cell.backgroundColor=[UIColor colorWithRed:0.8f green:1.0f blue:0.8f alpha:1.0f];
                }
            } else {
                if (indexPath.row==0) cell.textLabel.text=NSLocalizedString(@"Load game",@"");            
            }
            break;
        case 1:
            if (indexPath.row==0) cell.textLabel.text=NSLocalizedString(@"Options",@"");
            break;
        case 2:
            if (indexPath.row==0) {
                cell.textLabel.text=NSLocalizedString(@"About",@"");                
            }
            break;
        case 3:
            if (indexPath.row==0) cell.textLabel.text=NSLocalizedString(@"Donate",@"");
            break;
        case 4:
            cell.textLabel.text=NSLocalizedString(@"Exit",@"");
            break;
	}		
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {//Game browser
        if (emuThread_running) {
            switch (indexPath.row) {
                case 0:
                    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
                    [self.navigationController pushViewController:emuvc animated:NO];
                    break;
                case 1: //save state
                    statevc=[[OptSaveStateViewController alloc] initWithNibName:@"OptSaveStateViewController" bundle:nil];
                    [self.navigationController pushViewController:statevc animated:YES];
                    [statevc release];
                    break;
                case 2://DIP Switches
                    dipswvc = [[OptDIPSWViewController alloc] initWithNibName:@"OptDIPSWViewController" bundle:nil];
                    [self.navigationController pushViewController:dipswvc animated:YES];
                    [dipswvc release];
                    break;
                case 3: //reset
                    pendingReset=1;
                    //[tabView reloadData];
                    [self backToEmu];
                    break;
                case 4: //game info
                    DBHelper::getGameInfo(gameName, gameInfo);
                    if (gameInfo[0]) {
                        OptGameInfoViewController *infovc;
                        infovc = [[OptGameInfoViewController alloc] initWithNibName:@"OptGameInfoViewController" bundle:nil];
                        [self.navigationController pushViewController:infovc animated:YES];
                        [infovc release];        
                    }
                    break;
                case 5: //close current game
                    nShouldExit=1;
                    while (emuThread_running) {
                        [NSThread sleepForTimeInterval:0.01]; //10ms        
                    }
                    [NSThread sleepForTimeInterval:0.1]; //100ms
                    nShouldExit=0;
                    ui_currentIndex_s=ui_currentIndex_r= 0;
                    self.navigationItem.rightBarButtonItem = nil;
                    [tableView reloadData];
                    break;
                case 6: //game browser
                    gamebrowservc = [[GameBrowserViewController alloc] initWithNibName:@"GameBrowserViewController" bundle:nil];
                    [self.navigationController pushViewController:gamebrowservc animated:YES];
                    [gamebrowservc release];
                    break;
            }
        } else {
            switch (indexPath.row) {
                case 0: //game browser
                    gamebrowservc = [[GameBrowserViewController alloc] initWithNibName:@"GameBrowserViewController" bundle:nil];
                    [self.navigationController pushViewController:gamebrowservc animated:YES];
                    [gamebrowservc release];
                    break;
            }
        }
    } else if (indexPath.section==1) { //options
        optionsvc=[[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:nil];
        [self.navigationController pushViewController:optionsvc animated:YES];
        [optionsvc release];
    } else if (indexPath.section==2) { //about & feedback        
        if (indexPath.row==0) {//about
            NSString *msgString=[NSString stringWithFormat:NSLocalizedString(@"About_Msg",@""),[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],nBurnDrvCount];
            UIAlertView *aboutMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About",@"") message:msgString delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
            [aboutMsg show];
        } else if (indexPath.row==1) {//beta test-feedback
        }
    } else if (indexPath.section==3) { //Donate
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GR6NNLLWD62BN"]];
    } else if (indexPath.section==4) { //Exit
        nShouldExit=1;
        while (emuThread_running) {
            [NSThread sleepForTimeInterval:0.01]; //10ms        
        }
        [NSThread sleepForTimeInterval:0.1]; //100ms
        //exit(0);
        [[UIApplication sharedApplication] terminateWithSuccess];
    }
}

/*#pragma UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}
*/
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
                                    
        } else if (button&iCadeButtonB) { //back
            if (emuThread_running) {
                [self backToEmu];
            } 
        }
    }
    [tabView selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}



@end
