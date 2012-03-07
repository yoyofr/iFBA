//
//  OptConGetWiimoteBtnViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptConGetWiimoteBtnViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"

int wiimoteBtnPress;
static int wiimoteBtnAllPress;
extern int mOptWiimoteButtonSelected;

@implementation OptConGetWiimoteBtnViewController
@synthesize mnview;

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
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    wiimoteBtnPress=0;
    wiimoteBtnAllPress=0;
    //Wiimote
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

/****************************************************/
/****************************************************/
/*        WIIMOTE                                   */
/****************************************************/
/****************************************************/

#pragma mark UI action
-(IBAction) cancelInput {
    wiimoteBtnPress=0;
    [self dismissSemiModalViewController:self];
}
-(IBAction) clearInput {
    //joymap_iCade[mOptICadeButtonSelected].dev_btn=0;
    wiimoteBtnPress=0;
    [self dismissSemiModalViewController:self];
}

@end
