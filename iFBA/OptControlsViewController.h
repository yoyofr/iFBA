//
//  OptControlsViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptControlsViewController : UIViewController {
    IBOutlet UITableView *tabView;
    UIViewController *optWiimote,*optiCade,*optVPad;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) UIViewController *optWiimote,*optiCade,*optVPad;

@end
