//
//  CMActionSheet.h
//
//  Created by Constantine Mureev on 09.08.12.
//  Copyright (c) 2012 Team Force LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CallbackBlock)(void);

typedef enum {
	CMActionSheetButtonTypeWhite = 0,
	CMActionSheetButtonTypeBlue,
	CMActionSheetButtonTypeRed,
	CMActionSheetButtonTypeGray
} CMActionSheetButtonType;

@interface CMActionSheet : NSObject

@property (retain) NSString *title;

- (void)addButtonWithTitle:(NSString *)title type:(CMActionSheetButtonType)type block:(CallbackBlock)block;
- (void)addSeparator;

- (void)selectButton:(NSUInteger)index;

- (void)present;
- (void)dismissWithClickedButtonIndex:(NSUInteger)index animated:(BOOL)animated;

+ (UIImage *)colorizeImage:(UIImage *)image withColor:(UIColor *)color;

@end
