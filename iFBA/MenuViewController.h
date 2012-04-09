//
//  MenuViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>


@interface MenuViewController : UIViewController {
    IBOutlet UITableView *tabView;
    IBOutlet UIBarButtonItem *btn_backToEmu;
    UIViewController *gamebrowservc;
    UIViewController *optionsvc;
    UIViewController *dipswvc;
    UIViewController *statevc;
}

@property (nonatomic, retain) UIViewController *gamebrowservc,*optionsvc,*dipswvc,*statevc;
@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;

-(IBAction) backToEmu;

@end
