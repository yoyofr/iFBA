//
//  OptDIPSWValueViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptDIPSWValueViewController : UIViewController {
    IBOutlet UITableView *tabView;
@public
    int current_dip_idx;
}
@property int current_dip_idx;
@property (nonatomic, retain) IBOutlet UITableView *tabView;

@end
