//
//  OptGameInfoViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


@interface OptGameInfoViewController : TDSemiModalViewController {
    IBOutlet UIView *mnview;
    IBOutlet UITextView *txtview;
}

@property (nonatomic,retain) IBOutlet UIView *mnview;
@property (nonatomic,retain) IBOutlet UITextView *txtview;

@end
