//
//  OptConGetiCadeViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptConGetiCadeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"


int iCadePress;
static int iCadeAllPress;
extern int mOptICadeButtonSelected;

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
    
    [[mnview layer] setCornerRadius:15.0];	
	[[mnview layer] setBorderWidth:3.0];
	[[mnview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    iCadePress=0;
    iCadeAllPress=0;
    //ICADE
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    iCaderv.active=NO;
    [iCaderv removeFromSuperview];
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

/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/

- (void)setICadeState:(BOOL)state forButton:(iCadeState)button {    
    switch (button) {
        case iCadeButtonA:
            iCadePress=1;
            break;
        case iCadeButtonB:
            iCadePress=2;
            break;
        case iCadeButtonC:
            iCadePress=3;
            break;
        case iCadeButtonD:
            iCadePress=4;
            break;
        case iCadeButtonE:
            iCadePress=5;
            break;
        case iCadeButtonF:
            iCadePress=6;
            break;
        case iCadeButtonG:
            iCadePress=7;
            break;
        case iCadeButtonH:            
            iCadePress=8;
            break;
        default:
            break;
    }
}

- (void)buttonDown:(iCadeState)button {
    iCadeAllPress|=button;
    [self setICadeState:YES forButton:button];
}

- (void)buttonUp:(iCadeState)button {
    iCadeAllPress^=button;
    [self setICadeState:NO forButton:button];    
    if (iCadePress&& (iCadeAllPress==0)) {
        cur_ifba_conf->joymap_iCade[mOptICadeButtonSelected].dev_btn=iCadePress;
        //remove older assignment (if exist)
        for (int i=0;i<VSTICK_NB_BUTTON;i++) {
            if ((i!=mOptICadeButtonSelected)&&(cur_ifba_conf->joymap_iCade[i].dev_btn==iCadePress)) cur_ifba_conf->joymap_iCade[i].dev_btn=0;
        }
        iCadePress=0;
        [self dismissSemiModalViewController:self];
    }
}


#pragma mark UI action
-(IBAction) cancelInput {
    iCadePress=0;
    [self dismissSemiModalViewController:self];
}
-(IBAction) clearInput {
    cur_ifba_conf->joymap_iCade[mOptICadeButtonSelected].dev_btn=0;
    iCadePress=0;
    [self dismissSemiModalViewController:self];
}

@end
