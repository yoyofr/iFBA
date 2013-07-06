//
//  OptiCadeViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import "EmuViewController.h"
#import "iCadeReaderView.h"

@interface OptiCadeViewController : UIViewController <iCadeEventDelegate> {
    IBOutlet UITableView *tabView;
    TDSemiModalViewController *optgetButton;
    IBOutlet UIBarButtonItem *btn_backToEmu;
@public
    EmuViewController *emuvc;
    
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) UIViewController *optgetButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;
@property (nonatomic, retain) EmuViewController *emuvc;

-(IBAction) backToEmu;

@end
