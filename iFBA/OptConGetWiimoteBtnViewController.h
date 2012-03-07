//
//  OptConGetWiimoteBtnViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


@interface OptConGetWiimoteBtnViewController : TDSemiModalViewController {
    IBOutlet UIView *mnview;
    CADisplayLink* m_displayLink;
}

@property (nonatomic,retain) IBOutlet UIView *mnview;

-(IBAction) cancelInput;
-(IBAction) clearInput;

@end
