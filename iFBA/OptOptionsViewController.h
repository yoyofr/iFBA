//
//  OptOptionsViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmuViewController.h"

@interface OptOptionsViewController : UIViewController {
    IBOutlet UITableView *tabView;
    IBOutlet UIBarButtonItem *btn_backToEmu;
@public
    EmuViewController *emuvc;    
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;
@property (nonatomic, retain) EmuViewController *emuvc;

-(IBAction) backToEmu;


@end