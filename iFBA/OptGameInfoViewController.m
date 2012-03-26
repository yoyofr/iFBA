//
//  OptGameInfoViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptGameInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "fbaconf.h"

static NSMutableArray *genreList;
static int allnone;
static unsigned int newgenreFilter;
static unsigned int newgenreFilter_first=1;
static CAGradientLayer *gradientF,*gradientH;

char gameInfo[64*1024];

//iCade
#import "iCadeReaderView.h"
static iCadeReaderView *iCaderv;
static int ui_current_pos;


@implementation OptGameInfoViewController
@synthesize mnview,txtview;

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
    
    [[txtview layer] setCornerRadius:15.0];	
	//[[txtview layer] setBorderWidth:3.0];
	//[[txtview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    //ICADE 
    ui_current_pos=0;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    
}

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];    
    
    txtview.text=[NSString stringWithCString:gameInfo encoding:NSUTF8StringEncoding];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
    
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.mnview setNeedsLayout];
}

/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/
- (void)buttonDown:(iCadeState)button {
    
    
}
- (void)buttonUp:(iCadeState)button {
    if (button&iCadeJoystickDown) {
        if (ui_current_pos<txtview.contentSize.height) ui_current_pos+=txtview.frame.size.height*0.9f;
        if (ui_current_pos>=txtview.contentSize.height) ui_current_pos=txtview.contentSize.height;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickUp) {
        if (ui_current_pos>0) ui_current_pos-=txtview.frame.size.height*0.9f;
        if (ui_current_pos<0) ui_current_pos=0;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickLeft) {
        ui_current_pos=0;
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    } else if (button&iCadeJoystickRight) {
        ui_current_pos=txtview.contentSize.height;        
        [txtview scrollRectToVisible:CGRectMake(0,ui_current_pos,txtview.frame.size.width,txtview.frame.size.height) animated:YES];
        [txtview showsVerticalScrollIndicator];
    }else if (button&iCadeButtonA) { //validate            
        [self.navigationController popViewControllerAnimated:YES];            
    } else if (button&iCadeButtonB) { //back
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
