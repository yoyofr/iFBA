//
//  iFBA_glviewcontroller.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "iFBA_glviewcontroller.h"

@implementation iFBA_glviewcontroller
@synthesize context = _context;

static GLfloat vertices[5][2];  /* Holds Float Info For 4 Sets Of Vertices */
static GLfloat texcoords[5][2]; /* Holds Float Info For 4 Sets Of Texture coordinates. */
static GLuint txt_videobuffer;
static unsigned short *videobuffer;
static int videobuffer_w,videobuffer_h;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization                        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];        
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableColorFormat=GLKViewDrawableColorFormatRGB565;
    
    videobuffer=(unsigned short*)malloc(TXT_RES_X*TXT_RES_Y*2);
    memset(videobuffer,0,TXT_RES_X*TXT_RES_Y*2);
    videobuffer_w=512;
    videobuffer_h=256;
    
    for (int y=0;y<TXT_RES_Y/2;y++)
        for (int x=0;x<TXT_RES_X/2;x++) {
            videobuffer[y*TXT_RES_X+x]=31;
        }
            
    glViewport(0,0,160,240);
    
    glEnable(GL_TEXTURE_2D);	
    glGenTextures(1, &txt_videobuffer);    
    glDisable(GL_TEXTURE_2D);        
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

#pragma mark - GLKViewDelegate

static float f=0;
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, txt_videobuffer);    // Bind The Texture
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 512, 256, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, videobuffer);
    
    /* Begin Drawing Quads, setup vertex and texcoord array pointers */
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    
    /* Enable Vertex Pointer */
    glEnableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    texcoords[0][0]=(float)0/512.0f; texcoords[0][1]=(float)0/256.0f;
    texcoords[1][0]=(float)(videobuffer_w)/512.0f; texcoords[1][1]=(float)0/256.0f;
    texcoords[2][0]=(float)0/512.0f; texcoords[2][1]=(float)(videobuffer_h)/256.0f;
    texcoords[3][0]=(float)(videobuffer_w)/512.0f; texcoords[3][1]=(float)(videobuffer_h)/256.0f;
    
    
    //update viewport to match current neogeo video res
    glViewport(0,0,320,480);
    
    //glColor4ub(255,255,255,255);
    
    vertices[0][0]=-1; vertices[0][1]=1;
    vertices[1][0]=1; vertices[1][1]=1;
    vertices[2][0]=-1; vertices[2][1]=-1;
    vertices[3][0]=1; vertices[3][1]=-1;
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_TEXTURE_2D);
}

#pragma mark - GLKViewControllerDelegate

- (void)update {    
    f+=1 * self.timeSinceLastUpdate;
}

@end
