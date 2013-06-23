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


@interface OptGameInfoViewController : TDSemiModalViewController <UIWebViewDelegate> {
    IBOutlet UIView *mnview;
    IBOutlet UITextView *txtview;
    IBOutlet UIWebView *webview;
    IBOutlet UIWebView *webviewVideo;
    IBOutlet UIBarButtonItem *btn_summary,*btn_arcadehistory;
    IBOutlet UIToolbar *toolbar;
}

@property (nonatomic,retain) IBOutlet UIView *mnview;
@property (nonatomic,retain) IBOutlet UITextView *txtview;
@property (nonatomic,retain) IBOutlet UIWebView *webview;
@property (nonatomic,retain) IBOutlet UIWebView *webviewVideo;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *btn_summary,*btn_arcadehistory;
@property (nonatomic,retain) IBOutlet UIToolbar *toolbar;

-(IBAction) showSummary;
-(IBAction) showArcadehistory;
-(IBAction) showVideo;


@end
