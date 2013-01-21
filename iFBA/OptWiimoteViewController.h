//
//  OptWiimoteViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTstack/BTstackManager.h"
#import "BTstack/BTDiscoveryViewController.h"
#import "BTstackManager.h"
#import "EmuViewController.h"

@class BTstackManager;

@interface OptWiimoteViewController : UIViewController <BTstackManagerDelegate, BTstackManagerListener> {
    IBOutlet UITableView *tabView;
    
    BTstackManager *bt;
	UIActivityIndicatorView *deviceActivity;
	UIActivityIndicatorView *bluetoothActivity;
	UIFont * deviceNameFont;
	UIFont * macAddressFont;
	InquiryState inquiryState;
	int remoteNameIndex;
	BOOL showIcons;
	int connectingIndex;
	NSString *customActivityText;
    IBOutlet UIBarButtonItem *btn_backToEmu;
@public
    EmuViewController *emuvc;
    
}

-(void) markConnecting:(int)index; // use -1 for no connection active
@property (nonatomic, assign) BOOL showIcons;
@property (nonatomic, retain) NSString *customActivityText;


@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;
@property (nonatomic, retain) EmuViewController *emuvc;

-(IBAction) backToEmu;


@end
