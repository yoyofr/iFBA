//
//  FirstViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>

@interface FirstViewController : UIViewController {
    IBOutlet UIButton *btn_start;
    UIViewController *emuvc;
}

@property (nonatomic, retain) IBOutlet UIButton *btn_start;
@property (nonatomic, retain) UIViewController *emuvc;

-(IBAction) btn_StartEmu;

@end
