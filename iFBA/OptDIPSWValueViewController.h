//
//  OptDIPSWValueViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmuViewController.h"

@interface OptDIPSWValueViewController : UIViewController {
    IBOutlet UITableView *tabView;
    IBOutlet UIBarButtonItem *btn_backToEmu;
@public
    int current_dip_idx;
    EmuViewController *emuvc;
}
@property int current_dip_idx;
@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;
@property (nonatomic, retain) EmuViewController *emuvc;

-(IBAction) backToEmu;


@end
