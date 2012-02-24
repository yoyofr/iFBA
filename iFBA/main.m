//
//  main.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
/*    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }*/
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    /* Give over control to run loop, SDLUIKitDelegate will handle most things from here */
    int exit_status=UIApplicationMain(argc, argv, NULL, NSStringFromClass([AppDelegate class]));
    
    
    [pool release];
    return exit_status;
}
