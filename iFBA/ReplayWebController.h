//
//  ReplayWebController.h
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDSemiModal.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


@interface ReplayWebController : TDSemiModalViewController <UIWebViewDelegate,UIActionSheetDelegate> {
    IBOutlet UIWebView *webview;
}

@property (nonatomic,retain) IBOutlet UIWebView *webview;


@end
