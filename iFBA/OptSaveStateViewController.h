//
//  OptSaveStateViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmuViewController.h"
#import "iCadeReaderView.h"
#import "BButton.h"

@interface OptSaveStateViewController : UIViewController <iCadeEventDelegate> {
    IBOutlet UITableView *tabView;
    IBOutlet UIImageView *imgview;
    IBOutlet UIBarButtonItem *btn_backToEmu;
    IBOutlet BButton *btn_save,*btn_load;
@public
    EmuViewController *emuvc;
    
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;
@property (nonatomic, retain) IBOutlet UIImageView *imgview;
@property (nonatomic, retain) IBOutlet BButton *btn_save,*btn_load;
@property (nonatomic, retain) EmuViewController *emuvc;


-(IBAction) backToEmu;
-(IBAction) saveState;
-(IBAction) loadState;


@end
