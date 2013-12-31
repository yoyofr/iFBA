//
//  AppDelegate.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyNavigationController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UINavigationBarDelegate> {
    
}

@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) UINavigationController *navController;

- (int)loadSettings;
- (int)loadSettings:(NSString*)gameStr;
- (void)saveSettings;
- (void)saveSettings:(NSString *)gameStr;

@end
