//
//  UIViewController+TDSemiModalExtension.m
//  TDSemiModal
//
//  Created by Nathan  Reed on 18/10/10.
//  Copyright 2010 Nathan Reed. All rights reserved.
//

#import "UIViewController+TDSemiModalExtension.h"

extern UIScreen *cur_screen;

static void* org_vc;

@implementation UIViewController (TDSemiModalExtension)

// Use this to show the modal view (pops-up from the bottom)
- (void) presentSemiModalViewController:(TDSemiModalViewController*)vc {
#define DEGREES_TO_RADIANS(x) (M_PI * (x)/180.0)

	UIView* modalView = vc.view;
	UIView* coverView = vc.coverView;
    
    [vc viewWillAppear:NO]; //iOS 4.3 patch
    
    org_vc=self;

	//UIWindow* mainWindow = [(id)[[UIApplication sharedApplication] delegate] window];

	CGPoint middleCenter = self.view.center;
	CGSize offSize = cur_screen.bounds.size;

	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

	CGPoint offScreenCenter = CGPointZero;

	if(orientation == UIInterfaceOrientationLandscapeLeft ||
	   orientation == UIInterfaceOrientationLandscapeRight) {		
		offScreenCenter = CGPointMake(offSize.height / 2.0, offSize.width *1.2);
		middleCenter = CGPointMake(offSize.height / 2.0, offSize.width / 2.0);
        [modalView setBounds:CGRectMake(0, 0,offSize.height, offSize.width*0.8f)];
        [coverView setFrame:CGRectMake(0, 0, offSize.height, offSize.width)];
	}
	else {
		offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height *1.2);
        middleCenter = CGPointMake(offSize.width / 2.0, offSize.height / 2.0);
		[modalView setBounds:CGRectMake(0, 0, offSize.width, offSize.height*0.8f)];
		[coverView setFrame:CGRectMake(0, 0, offSize.width, offSize.height)];

	}
	// we start off-screen
	modalView.center = offScreenCenter;
	 
	coverView.alpha = 0.0f;
	
	[self.view addSubview:coverView];
	[self.view addSubview:modalView];
	
	// Show it with a transition effect
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.6];
	
	modalView.center = middleCenter;
	coverView.alpha = 0.5;
	[UIView commitAnimations];

}

// Use this to slide the semi-modal view back down.
-(void) dismissSemiModalViewController:(TDSemiModalViewController*)vc {
	double animationDelay = 0.7;
	UIView* modalView = vc.view;
	UIView* coverView = vc.coverView;

	CGSize offSize = cur_screen.bounds.size;

	CGPoint offScreenCenter = CGPointZero;
	
	UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
	if(orientation == UIInterfaceOrientationLandscapeLeft || 
			orientation == UIInterfaceOrientationLandscapeRight) {
		offScreenCenter = CGPointMake(offSize.height / 2.0, offSize.width * 1.5);		
	}
	else {
		offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height * 1.5);
	}

	[UIView beginAnimations:nil context:modalView];
	[UIView setAnimationDuration:animationDelay];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dismissSemiModalViewControllerEnded:finished:context:)];
	modalView.center = offScreenCenter;
	coverView.alpha = 0.0f;
	[UIView commitAnimations];

	[coverView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:animationDelay];
    
    [vc viewWillDisappear:NO];  //iOS 4.3 patch
}

- (void) dismissSemiModalViewControllerEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	UIView* modalView = (UIView*)context;
	[modalView removeFromSuperview];
    [(UIViewController*)org_vc viewWillAppear:YES];
}

@end
