//
//  OptConGetiCadeViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import "iCadeReaderView.h"

@interface OptConGetiCadeViewController : TDSemiModalViewController <iCadeEventDelegate> {
    iCadeReaderView *iCaderv;
    IBOutlet UIView *mnview;
}

@property (readwrite) iCadeReaderView *iCaderv;
@property (nonatomic,retain) IBOutlet UIView *mnview;

-(IBAction) cancelInput;
-(IBAction) clearInput;

@end
