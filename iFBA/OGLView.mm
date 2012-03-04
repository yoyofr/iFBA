#include "OGLView.h"
#include "GlErrors.h"
#include <QuartzCore/QuartzCore.h>

#include <OpenGLES/EAGL.h>
#include <OpenGLES/EAGLDrawable.h>
#include <OpenGLES/ES1/glext.h>

@implementation OGLView

+ (Class)layerClass 
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder 
{
    if ((self = [super initWithCoder:coder])) 
	{
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        //self.opaque=NO;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithBool:NO], 
											kEAGLDrawablePropertyRetainedBacking, 
											kEAGLColorFormatRGBA8, 
											kEAGLDrawablePropertyColorFormat, 
											nil];  
		
		
    }
	m_touchcount=0;
	m_poptrigger=FALSE;
    return self;
}

- (void)initialize:(EAGLContext*)oglContext scaleFactor:(float)scaleFactor {
	if ([self respondsToSelector:@selector(contentScaleFactor)]) {
		self.contentScaleFactor=scaleFactor;
	}
	m_oglContext=oglContext;
	FrameBufferUtils::Create(m_frameBuffer, oglContext, (CAEAGLLayer*)self.layer);
}

- (void)layoutSubviews {
    //NSLog(@"layout");
    //[EAGLContext setCurrentContext:m_oglContext];
    FrameBufferUtils::Destroy(m_frameBuffer);
	FrameBufferUtils::Create(m_frameBuffer, m_oglContext, (CAEAGLLayer*)self.layer);
}

- (void)dealloc {
	FrameBufferUtils::Destroy(m_frameBuffer);
    [super dealloc];
}

- (void)bind {
	FrameBufferUtils::Set(m_frameBuffer);
}


void ios_fingerEvent(long touch_id, int evt_type, float x, float y);

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch = (UITouch*)[enumerator nextObject];
    
    while(touch) {
        //CGPoint locationInView = [self touchLocation:touch];
        CGPoint point = [touch locationInView: touch.view];
        
        //FIXME: TODO: Using touch as the fingerId is potentially dangerous
        //It is also much more efficient than storing the UITouch pointer
        //and comparing it to the incoming event.
        ios_fingerEvent((long)touch, 1, point.x, point.y);
        
        touch = (UITouch*)[enumerator nextObject];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch = (UITouch*)[enumerator nextObject];
    
    while(touch) {
        //CGPoint locationInView = [self touchLocation:touch];
        CGPoint point = [touch locationInView: touch.view];
        
        //FIXME: TODO: Using touch as the fingerId is potentially dangerous
        //It is also much more efficient than storing the UITouch pointer
        //and comparing it to the incoming event.
        ios_fingerEvent((long)touch, 0, point.x, point.y);
        
        touch = (UITouch*)[enumerator nextObject];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch = (UITouch*)[enumerator nextObject];
    
    while(touch) {
        //CGPoint locationInView = [self touchLocation:touch];
        CGPoint point = [touch locationInView: touch.view];
        
        //FIXME: TODO: Using touch as the fingerId is potentially dangerous
        //It is also much more efficient than storing the UITouch pointer
        //and comparing it to the incoming event.
        ios_fingerEvent((long)touch, 2, point.x, point.y);
        
        touch = (UITouch*)[enumerator nextObject];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    /*
     this can happen if the user puts more than 5 touches on the screen
     at once, or perhaps in other circumstances.  Usually (it seems)
     all active touches are canceled.
     */
    [self touchesEnded: touches withEvent: event];
}



@end
