//
//  EmuViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>


#import <mach/mach.h>
#import <mach/mach_host.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <assert.h>
#include <stdint.h>
#import "OGLView.h"

#import "iCadeReaderView.h"
#import "BTstack/BTstackManager.h"
#import "BTstack/BTDiscoveryViewController.h"
@class BTstackManager;
@class BTDiscoveryViewController;


@class OGLView;
@class EAGLContext;
@class CADisplayLink;

#define TEXTURE_W 512
#define TEXTURE_H 512

@interface EmuViewController : UIViewController <iCadeEventDelegate, BTstackManagerDelegate, BTstackManagerListener,BTDiscoveryDelegate> {
    OGLView* m_oglView;
	EAGLContext* m_oglContext;	
	CADisplayLink* m_displayLink;
	
    iCadeReaderView *control;
    BTDiscoveryViewController* discoveryView;
    
    
    float mScaleFactor;
    int mDeviceType,mDevice_ww,mDevice_hh;        
    
    
}

@property (readwrite) iCadeReaderView *control;

- (void)doFrame;
//@property (nonatomic, retain) IBOutlet OGLView* m_oglView;

@end
