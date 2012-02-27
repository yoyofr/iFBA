//
//  AppDelegate.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "MenuViewController.h"

extern int device_isIpad;

@implementation AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;

- (void)dealloc
{
    [_window release];
    [_navController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    // Override point for customization after application launch.
    UIViewController *menuvc;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPhone" bundle:nil] autorelease];
        device_isIpad=0;
    } else {
        //menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPad" bundle:nil] autorelease];
        menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPhone" bundle:nil] autorelease];
        
        device_isIpad=1;
    }
    self.navController = [[[UINavigationController alloc] init] autorelease];
    [[self.navController navigationBar] setBarStyle:UIBarStyleDefault];
//    [[self.navController navigationBar] setTranslucent:YES];
    
    [self.navController pushViewController:menuvc animated:YES];
    
    self.window.rootViewController = self.navController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
