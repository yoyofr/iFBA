//
//  OptionsViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionsViewController : UIViewController {
    IBOutlet UITableView *tabView;
    UIViewController *optVideo,*optAudio,*optControl,*optEmulation,*optROMSpaths;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) UIViewController *optVideo,*optAudio,*optControl,*optEmulation,*optROMSpaths;

@end
