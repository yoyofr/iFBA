//
//  OptOptionsViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptOptionsViewController : UIViewController {
    IBOutlet UITableView *tabView;
    IBOutlet UIBarButtonItem *btn_backToEmu;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;

-(IBAction) backToEmu;


@end
