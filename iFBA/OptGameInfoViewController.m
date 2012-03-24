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
    
}

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];    
    txtview.text=[NSString stringWithCString:gameInfo encoding:NSUTF8StringEncoding];
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

@end
