//
//  OptSelGenresViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptSelGenresViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"

static NSMutableArray *genreList;
static int allnone;
static unsigned int newgenreFilter;
static unsigned int newgenreFilter_first=1;
static CAGradientLayer *gradientF,*gradientH;

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_currentIndex_s,ui_currentIndex_r;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;


@implementation OptSelGenresViewController
@synthesize mnview,tabview,footer,header;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[mnview layer] setCornerRadius:15.0];	
	[[mnview layer] setBorderWidth:3.0];
	[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    genreList=[[NSMutableArray alloc] initWithCapacity:0];
    [genreList addObject:@"H-Shooter"];
    [genreList addObject:@"V-Shooter"];
    [genreList addObject:@"Beat'em all"];
    [genreList addObject:@"Versus Fighting"];
    [genreList addObject:@"BIOS"];
    [genreList addObject:@"Breakout"];
    [genreList addObject:@"Casino"];
    [genreList addObject:@"Ball Paddle"];
    [genreList addObject:@"Maze"];
    [genreList addObject:@"Minigames"];
    [genreList addObject:@"Pinball"];
    [genreList addObject:@"Platform"];
    [genreList addObject:@"Puzzle"];
    [genreList addObject:@"Quiz"];
    [genreList addObject:@"Sport"];
    [genreList addObject:@"Football"];
    [genreList addObject:@"Misc"];
    [genreList addObject:@"Mahjong"];
    [genreList addObject:@"Racing"];
    [genreList addObject:@"Shoot"];
    
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

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    allnone=0;
    newgenreFilter=(ifba_conf.filter_genre);    
    
    gradientF = [CAGradientLayer layer];
    gradientF.frame = footer.bounds;
    gradientF.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], nil];
    [footer.layer insertSublayer:gradientF atIndex:0];
    
    gradientH = [CAGradientLayer layer];
    gradientH.frame = footer.bounds;
    gradientH.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    [header.layer insertSublayer:gradientH atIndex:0];        
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [gradientF removeFromSuperlayer];
    [gradientH removeFromSuperlayer];
    //    [gradientF release];
    //   [gradientH release];
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {    
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    gradientF.frame = footer.bounds;
    gradientH.frame = footer.bounds;
    [self.mnview setNeedsLayout];
}



#pragma uitableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [genreList count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return nil;
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 return nil;    
 }*/

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		
    }
    if (newgenreFilter_first) {  //Workaround for iOS 4.3 bug (not calling viewillappear, at least in simulator)
        newgenreFilter=ifba_conf.filter_genre;
        newgenreFilter_first=0;
    }
    
    cell.textLabel.text=[genreList objectAtIndex:indexPath.row];
	cell.accessoryType=(newgenreFilter&(1<<indexPath.row)?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone);
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    newgenreFilter=newgenreFilter^(1<<indexPath.row);
    [tableView reloadData];
}

#pragma mark UI action
-(IBAction) cancelInput {
    newgenreFilter_first=1;//Workaround for iOS 4.3 bug (not calling viewillappear, at least in simulator)
    [self dismissSemiModalViewController:self];
    [tabview reloadData];
}
-(IBAction) okInput {
    newgenreFilter_first=1;//Workaround for iOS 4.3 bug (not calling viewillappear, at least in simulator)
    ifba_conf.filter_genre=newgenreFilter;
    [self dismissSemiModalViewController:self];
}

-(IBAction) allNoneInput {
    if (allnone) newgenreFilter=0xFFFFFFFF;
    else newgenreFilter=0;
    allnone^=1;    
    [tabview reloadData];
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
            if (ui_currentIndex_r<[tabview numberOfRowsInSection:ui_currentIndex_s]-1) ui_currentIndex_r++; //next row
            else { //next section
                if (ui_currentIndex_s<[tabview numberOfSections]-1) {
                    ui_currentIndex_s++;ui_currentIndex_r=0; //next section
                } else {
                    ui_currentIndex_s=ui_currentIndex_r=0; //loop to 1st section
                }
            }             
        } else if (button&iCadeJoystickUp) {
            if (ui_currentIndex_r>0) ui_currentIndex_r--; //prev row            
            else { //prev section
                if (ui_currentIndex_s>0) {
                    ui_currentIndex_s--;ui_currentIndex_r=[tabview numberOfRowsInSection:ui_currentIndex_s]-1; //next section
                } else {
                    ui_currentIndex_s=[tabview numberOfSections]-1;ui_currentIndex_r=[tabview numberOfRowsInSection:ui_currentIndex_s]-1; //loop to 1st section
                }
            }
        } else if (button&iCadeButtonA) { //validate            
            [self tableView:tabview didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s]];
            
        } else if (button&iCadeButtonB) { //back
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    [tabview selectRowAtIndexPath:[NSIndexPath indexPathForRow:ui_currentIndex_r inSection:ui_currentIndex_s] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}


@end
