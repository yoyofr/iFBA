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

@implementation OptSelGenresViewController
@synthesize mnview,tabview;

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
    
}

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];
    allnone=0;
    newgenreFilter=(ifba_conf.filter_genre);    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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

@end
