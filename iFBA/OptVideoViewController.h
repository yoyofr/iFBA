//
//  OptVideoViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptVideoViewController : UIViewController {
    IBOutlet UITableView *tabView;
    IBOutlet UIImageView *imageView;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@end
