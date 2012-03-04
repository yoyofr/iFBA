#ifndef st_oglview_h_
#define st_oglview_h_


#include "FrameBuffer.h"
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>

@class EAGLContext;

@interface OGLView : UIView {
	FrameBuffer m_frameBuffer;
	EAGLContext* m_oglContext;

}

- (void)initialize:(EAGLContext*)oglContext scaleFactor:(float)scaleFactor;
- (void)bind;

@end


#endif
