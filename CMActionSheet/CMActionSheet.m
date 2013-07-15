//
//  CMActionSheet.m
//
//  Created by Constantine Mureev on 09.08.12.
//  Copyright (c) 2012 Team Force LLC. All rights reserved.
//

#import "CMActionSheet.h"
#import "CMRotatableModalViewController.h"

@interface CMUIScrollView: UIScrollView {
    
}
@end

@implementation CMUIScrollView
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}
@end


@interface CMActionSheet ()

@property (retain) UIImageView *backgroundActionView;
@property (retain) UIWindow *overlayWindow;
@property (retain) UIWindow *mainWindow;
@property (retain) NSMutableArray *items,*btnType;
@property (retain) NSMutableArray *callbacks;
@property (retain) UIView *actionSheet;
@property (retain) CMUIScrollView *scrollView;

@end

@implementation CMActionSheet

@synthesize title, backgroundActionView, overlayWindow, mainWindow, items, btnType, callbacks, actionSheet, scrollView;

+ (UIImage *)colorizeImage:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContext(image.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -area.size.height);
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, area, image.CGImage);
    
    [color set];
    CGContextFillRect(context, area);
    
    CGContextRestoreGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    
    CGContextDrawImage(context, area, image.CGImage);
    
    UIImage *colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return colorizedImage;
}


- (id)init {
    self = [super init];
    if (self) {
        UIImage *backgroundImage = [UIImage imageNamed:@"action-sheet-panel.png"];
        backgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:30];
        
        self.backgroundActionView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
        self.backgroundActionView.alpha = 0.8;
        self.backgroundActionView.contentMode = UIViewContentModeScaleToFill;
        self.backgroundActionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.overlayWindow = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
        self.overlayWindow.windowLevel = UIWindowLevelStatusBar;
        self.overlayWindow.userInteractionEnabled = YES;
        self.overlayWindow.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5f];
        self.overlayWindow.hidden = YES;
    }
    return self;
}

- (void)dealloc {
    self.backgroundActionView = nil;
    self.overlayWindow = nil;
    self.mainWindow = nil;
    self.items = nil;
    self.btnType = nil;
    self.callbacks = nil;
    
    [super dealloc];
}



- (void)initButtonImage:(UIButton *)button type:(CMActionSheetButtonType)type highlighted:(BOOL)highlighted {
    NSString* color = nil;
    
        if (CMActionSheetButtonTypeBlue == type) {
            color = @"blue";
        } else if (CMActionSheetButtonTypeRed == type) {
            color = @"red";
        } else if (CMActionSheetButtonTypeWhite == type) {
            color = @"white";
        } else if (CMActionSheetButtonTypeGray == type) {
            color = @"gray";
        } else {
            color = @"white";
        }
    
    
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"action-%@-button.png", color]];
    if (highlighted) {//darken image
        image=[CMActionSheet colorizeImage:image withColor:[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.8f]];
    }
    image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width)>>1 topCapHeight:0];
    
    [button setBackgroundImage:image forState:UIControlStateNormal];
    
    if (CMActionSheetButtonTypeWhite == type) {
        if (highlighted) {
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
            [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            
        } else {
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        }
    } else if (CMActionSheetButtonTypeGray == type) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else if (CMActionSheetButtonTypeBlue == type) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:40 / 255.0 green:170 / 255.0 blue:255 / 255.0 alpha:1] forState:UIControlStateHighlighted];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    } else {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:255 / 255.0 green:40 / 255.0 blue:60 / 255.0 alpha:1] forState:UIControlStateHighlighted];
        [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    }
}

- (void)addButtonWithTitle:(NSString *)buttonTitle type:(CMActionSheetButtonType)type block:(CallbackBlock)block {
	NSAssert(buttonTitle, @"Button title must not be nil!");
    
    NSUInteger index = 0;
    
    if (!self.items) {
        self.items = [NSMutableArray array];
    }
    if (!self.btnType) {
        self.btnType = [NSMutableArray array];
    }
    if (!self.callbacks) {
        self.callbacks = [NSMutableArray array];
    }
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.titleLabel.adjustsFontSizeToFitWidth = NO;
    
    //button.titleLabel.adjustsFontSizeToFitWidth = YES;
    //button.titleLabel.minimumFontSize = 10;
    
    // Add 6px padding
    [button setTitleEdgeInsets:UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0)];
    
    button.titleLabel.textAlignment = UITextAlignmentCenter;
    button.titleLabel.shadowOffset = CGSizeMake(0, -1);
    button.backgroundColor = [UIColor clearColor];
    
    [self initButtonImage:button type:type highlighted:NO];
    
    
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    button.accessibilityLabel = buttonTitle;
    
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.items addObject:button];
    [self.btnType addObject:[NSNumber numberWithInt:type]];
    
    if (block) {
        [self.callbacks addObject:[[block copy] autorelease]];
    } else {
        [self.callbacks addObject:[NSNull null]];
    }
    
    index++;
}

- (void)addSeparator {
    UIImage *separatorImage = [UIImage imageNamed:@"action-separator.png"];
    separatorImage = [separatorImage stretchableImageWithLeftCapWidth:0 topCapHeight:2];
    
    UIImageView *separator = [[[UIImageView alloc] initWithImage:separatorImage] autorelease];
    separator.contentMode = UIViewContentModeScaleToFill;
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.items addObject:separator];
}

- (void)selectButton:(NSUInteger)index {
    int idx=0;
    if (self.items && self.items.count > 0) {
        for (UIView *item in self.items) {
            if ([item isKindOfClass:[UIButton class]]) {
                NSNumber *num=[self.btnType objectAtIndex:idx];
                if (idx==index) {
                    [self initButtonImage:((UIButton *)item) type:[num intValue] highlighted:YES];
                    [self.scrollView scrollRectToVisible:((UIButton *)item).frame animated:YES];
                } else {
                    [self initButtonImage:((UIButton *)item) type:[num intValue] highlighted:NO];
                }
                idx++;
            }
        }
    }
}

- (void)present {
    if (self.items && self.items.count > 0) {
        self.mainWindow = [UIApplication sharedApplication].keyWindow;
        CMRotatableModalViewController *viewController = [[CMRotatableModalViewController new] autorelease];
        viewController.rootViewController = mainWindow.rootViewController;
        
        // Build action sheet view
        //UIView *
         actionSheet = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, viewController.view.frame.size.height)] autorelease];
        actionSheet.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
        
        scrollView = [[[CMUIScrollView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, viewController.view.frame.size.height*3/4)] autorelease];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        scrollView.pagingEnabled = YES;
        scrollView.canCancelContentTouches = YES;
        
        //[viewController.view addSubview:actionSheet];
        [viewController.view addSubview:scrollView];
        [scrollView addSubview:actionSheet];
        
        // Add background
        self.backgroundActionView.frame = CGRectMake(0, 0, actionSheet.frame.size.width, actionSheet.frame.size.height);
        [actionSheet addSubview:self.backgroundActionView];
        
        CGFloat offset = 15;
        
        // Add Title
        if (self.title) {
            CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:18]
                            constrainedToSize:CGSizeMake(actionSheet.frame.size.width-10*2, 1000)
                                lineBreakMode:UILineBreakModeWordWrap];
            
            UILabel *labelView = [[[UILabel alloc] initWithFrame:CGRectMake(10, offset, actionSheet.frame.size.width-10*2, size.height)] autorelease];
            labelView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            labelView.font = [UIFont systemFontOfSize:18];
            labelView.numberOfLines = 0;
            labelView.lineBreakMode = UILineBreakModeWordWrap;
            labelView.textColor = [UIColor whiteColor];
            labelView.backgroundColor = [UIColor clearColor];
            labelView.textAlignment = UITextAlignmentCenter;
            labelView.shadowColor = [UIColor blackColor];
            labelView.shadowOffset = CGSizeMake(0, -1);
            labelView.text = title;
            [actionSheet addSubview:labelView];
            
            offset += size.height + 10;
        }
        
        
        
        // Add action sheet items
        NSUInteger tag = 100;
        
        for (UIView *item in self.items) {
            if ([item isKindOfClass:[UIImageView class]]) {
                item.frame = CGRectMake(0, offset, actionSheet.frame.size.width, 2);
                [actionSheet addSubview:item];
                
                offset += item.frame.size.height + 10;
            } else {
                item.frame = CGRectMake(20, offset, actionSheet.frame.size.width - 20*2, 45);
                item.tag = tag++;
                [actionSheet addSubview:item];
                
                offset += item.frame.size.height + 10;
            }
        }
        
        actionSheet.frame=CGRectMake(0, 0, viewController.view.frame.size.width, offset);
        self.backgroundActionView.frame = CGRectMake(0, 0, viewController.view.frame.size.width, offset);
        
        
        scrollView.contentSize = CGSizeMake(viewController.view.frame.size.width, offset);
        scrollView.frame = CGRectMake(0, viewController.view.frame.size.height, viewController.view.frame.size.width, viewController.view.frame.size.height*3/4);
        
        // Present window and action sheet
        self.overlayWindow.rootViewController = viewController;
        self.overlayWindow.alpha = 0.0f;
        self.overlayWindow.hidden = NO;
        [self.overlayWindow makeKeyWindow];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
            self.overlayWindow.alpha = 1;
            CGPoint center = scrollView.center;
            center.y -= scrollView.frame.size.height;
            scrollView.center = center;
        } completion:^(BOOL finished) {
            // we retain self until with dismiss action sheet
            [self retain];
        }];
    }
}

- (void)dismissWithClickedButtonIndex:(NSUInteger)index animated:(BOOL)animated {
    // Hide window and action sheet
    //UIView *actionSheet = self.overlayWindow.rootViewController.view.subviews.lastObject;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
        self.overlayWindow.alpha = 0;
        CGPoint center = scrollView.center;
        center.y += scrollView.frame.size.height;
        scrollView.center = center;
    } completion:^(BOOL finished) {
        self.overlayWindow.hidden = YES;
        [self.mainWindow makeKeyWindow];
        
        // now we can release self
        [self release];
    }];
    
    // Call callback
    CallbackBlock callback = [self.callbacks objectAtIndex:index];
    if ([callbacks isKindOfClass:[NSNull class]]) {
        // Do nothing... It's just placeholder
    } else {
        callback();
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark - Private


- (void)buttonClicked:(id)sender {
    NSUInteger buttonIndex = ((UIView *)sender).tag - 100;
    [self dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

@end
