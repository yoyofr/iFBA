//
//  SendReplayController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


@interface SendReplayController : TDSemiModalViewController <UIWebViewDelegate,UIActionSheetDelegate,UITextFieldDelegate,UITextViewDelegate> {
    IBOutlet UIButton *cancelBtn,*uploadBtn;
    IBOutlet UITextField *authorTextField;
    IBOutlet UITextView *descrTextView;
    IBOutlet UIProgressView *uploadPrgView;
}

@property (nonatomic,retain) IBOutlet UIButton *cancelBtn,*uploadBtn;
@property (nonatomic,retain) IBOutlet UITextField *authorTextField;
@property (nonatomic,retain) IBOutlet UITextView *descrTextView;
@property (nonatomic,retain) IBOutlet UIProgressView *uploadPrgView;

-(IBAction) uploadClicked;
-(IBAction) cancelClicked;

@end
