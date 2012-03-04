//
//  OptConGetiCadeViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptConGetiCadeViewController.h"
#import <QuartzCore/QuartzCore.h>

int iCadePress;
static int iCadeAllPress;

@implementation OptConGetiCadeViewController
@synthesize iCaderv;
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
    //ICADE
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    
    [[mnview layer] setCornerRadius:15.0];	
	[[mnview layer] setBorderWidth:3.0];
	[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    iCadePress=0;
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
/*        ICADE                                     */
/****************************************************/
/****************************************************/

- (void)setICadeState:(BOOL)state forButton:(iCadeState)button {    
    switch (button) {
        case iCadeButtonA:
            case iCadeButtonB:
            case iCadeButtonC:
            case iCadeButtonD:
            case iCadeButtonE:
            case iCadeButtonF:
            case iCadeButtonG:
            case iCadeButtonH:            
            iCadePress|=state;
            break;
/*        case iCadeJoystickUp:
            joy_state[0][GN_UP]=state;
            break;
        case iCadeJoystickRight:
            joy_state[0][GN_RIGHT]=state;
            break;
        case iCadeJoystickDown:
            joy_state[0][GN_DOWN]=state;
            break;
        case iCadeJoystickLeft:
            joy_state[0][GN_LEFT]=state;
            break;            */
        default:
            break;
    }
}

- (void)buttonDown:(iCadeState)button {
    iCadeAllPress|=button;
    [self setICadeState:YES forButton:button];
}

- (void)buttonUp:(iCadeState)button {
    iCadeAllPress&=~button;
    [self setICadeState:NO forButton:button];    
    if (iCadePress&& (iCadeAllPress==0)) {
        [self dismissSemiModalViewController:self];
    }
}


#pragma mark UI action
-(IBAction) cancelInput {
    [self dismissSemiModalViewController:self];
}

@end
