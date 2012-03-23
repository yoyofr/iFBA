//
//  OptSelGenresViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


@interface OptSelGenresViewController : TDSemiModalViewController {
    IBOutlet UIView *mnview,*footer,*header;
    IBOutlet UITableView *tabview;
    CADisplayLink* m_displayLink;
}

@property (nonatomic,retain) IBOutlet UIView *mnview,*footer,*header;
@property (nonatomic,retain) IBOutlet UITableView *tabview;

-(IBAction) cancelInput;
-(IBAction) okInput;
-(IBAction) allNoneInput;

@end
