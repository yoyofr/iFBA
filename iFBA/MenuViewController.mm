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

#ifdef TESTFLIGHT
#import "TestFlight.h"
#endif

extern int pendingReset;
extern unsigned int nBurnDrvCount;
extern int launchGame;
extern char gameName[64];
extern volatile int emuThread_running;
extern int device_isIpad;

@implementation MenuViewController
@synthesize emuvc,gamebrowservc,optionsvc,dipswvc;
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
	return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    int nbRows=0;
    switch (section) {
        case 0:
            if (emuThread_running) nbRows=6;
            else nbRows=1;
            break;
        case 1:
            nbRows=1;
            break;
        case 2:
            nbRows=1;
#ifdef TESTFLIGHT
            nbRows++;
#endif
            break;
        case 3:
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
    cell.backgroundColor=[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
	switch (indexPath.section) {
        case 0:
            if (emuThread_running) {
                if (indexPath.row==0) {
                    cell.textLabel.text=[NSString stringWithFormat:NSLocalizedString(@"Back to %s",@""),gameName];
//                    cell.backgroundColor=[UIColor colorWithRed:0.95f green:1.0f blue:0.95f alpha:1.0f];
                }
                if (indexPath.row==1) cell.textLabel.text=NSLocalizedString(@"Load State",@"");
                if (indexPath.row==2) cell.textLabel.text=NSLocalizedString(@"Save State",@"");
                if (indexPath.row==3) cell.textLabel.text=NSLocalizedString(@"DIPSW",@"");
                if (indexPath.row==4) {
//                    if (pendingReset) cell.accessoryType=UITableViewCellAccessoryCheckmark;
//                    else 
                        cell.accessoryType=UITableViewCellAccessoryNone;
                    cell.textLabel.text=@"Reset";
//                    cell.backgroundColor=[UIColor colorWithRed:1.0f green:0.7f blue:0.7f alpha:1.0f];
                }
                if (indexPath.row==5) {
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
#ifdef TESTFLIGHT
            if (indexPath.row==1) cell.textLabel.text=NSLocalizedString(@"Feedback",@"");
#endif
            
            break;
        case 3:
            if (indexPath.row==0) cell.textLabel.text=NSLocalizedString(@"Donate",@"");
            break;
	}		
    
    return cell;
}

int StatedLoad(int slot);
int StatedSave(int slot);

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {//Game browser
        if (emuThread_running) {
            switch (indexPath.row) {
                case 0:
                    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
                    [self.navigationController pushViewController:emuvc animated:NO];
                    break;
                case 1: //load state
                    StatedLoad(0);
                    [self backToEmu];
                    break;
                case 2: //save state
                    StatedSave(0);
                    [self backToEmu];
                    break;
                case 3://DIP Switches
                    dipswvc = [[OptDIPSWViewController alloc] initWithNibName:@"OptDIPSWViewController" bundle:nil];
                    [self.navigationController pushViewController:dipswvc animated:YES];
                    [dipswvc release];
                    break;
                case 4: //reset
                    pendingReset=1;
                    //[tabView reloadData];
                    [self backToEmu];
                    break;
                case 5: //game browser
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
#ifdef TESTFLIGHT
            [TestFlight openFeedbackView];
#endif
        }
    } else if (indexPath.section==3) { //Donate
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GR6NNLLWD62BN"]];
    }
}


@end
