/* Modified by YM to handle 2 impulse controllers
 */

/*
 Copyright (C) 2011 by Stuart Carnie
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "iCadeReaderView.h"

//english
//                                  Player 1----
//                                  UDLR12345678
static const char *ON_STATES_EN  = "wdxayhujikol";
static const char *OFF_STATES_EN = "eczqtrfnmpgv";

//                                     Player 1----Player 2--
//                                     UDLR12345678udlr123456
static const char *ON_STATES_IC_EN  = "wdxayklojh..[isu3157-9";
static const char *OFF_STATES_IC_EN = "eczqtpvgnr..]mbf4268=0";

//french
static const char *ON_STATES_FR  = "zdxqyhujikol";
static const char *OFF_STATES_FR = "ecwatrfn,pgv";

//                                     Player 1----Player 2--
//                                     UDLR12345678udlr123456
// char to translate: [ ] 0 1 2 3 4 5 6 7 8 9 - =
static const char *ON_STATES_IC_FR  = "zdxqyklojh..[isu3157-9";
static const char *OFF_STATES_IC_FR = "ecwatpvgnr..],bf4268=0";


static char *ON_STATES;
static char *OFF_STATES;


@interface iCadeReaderView()

- (void)didEnterBackground;
- (void)didBecomeActive;

@end

@implementation iCadeReaderView

@synthesize iCadeState=_iCadeState, delegate=_delegate, active, type, lang;

- (void)updateSetup {
    switch (lang) {
        default:
        case 0:
            ON_STATES=(self.type?ON_STATES_IC_EN:ON_STATES_EN);
            OFF_STATES=(self.type?OFF_STATES_IC_EN:OFF_STATES_EN);
            break;
        case 1:
            ON_STATES=(self.type?ON_STATES_IC_FR:ON_STATES_FR);
            OFF_STATES=(self.type?OFF_STATES_IC_FR:OFF_STATES_FR);
            break;
    }
}

- (void)changeLang:(int)lang {
    self.lang=lang;
    [self updateSetup];
}

- (void)changeControllerType:(int)type {
    //0 is iCade
    //1 is iMPULSE Controller
    self.type=type;
    [self updateSetup];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    lang=0; //ENGLISH
    type=0; //iCADE
    [self updateSetup];
    inputView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [super dealloc];
}

- (void)didEnterBackground {
    if (self.active)
        [self resignFirstResponder];
}

- (void)didBecomeActive {
    if (self.active)
        [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setActive:(BOOL)value {
    if (active == value) return;
    
    active = value;
    if (active) {
        [self becomeFirstResponder];
    } else {
        [self resignFirstResponder];
    }
}

- (UIView*) inputView {
    return inputView;
}

- (void)setDelegate:(id<iCadeEventDelegate>)delegate {
    _delegate = delegate;
    if (!_delegate) return;
    
    _delegateFlags.stateChanged = [_delegate respondsToSelector:@selector(stateChanged:)];
    _delegateFlags.buttonDown = [_delegate respondsToSelector:@selector(buttonDown:)];
    _delegateFlags.buttonUp = [_delegate respondsToSelector:@selector(buttonUp:)];
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText {
    return NO;
}

- (void)insertText:(NSString *)text {
    //TODO: is it possible to have 2 char at same time ?
    if ([text length]>1) {
        NSLog(@"WARNING: text: %@",text);
    }
    char ch = [text characterAtIndex:0];
    char *p;
    
    p= strchr(ON_STATES, ch);
    bool stateChanged = false;
    if (p) {
        int index = p-ON_STATES;
        _iCadeState |= (1 << index);
        stateChanged = true;
        if (_delegateFlags.buttonDown) {
            [_delegate buttonDown:(1 << index)];
        }
    } else {
        p= strchr(OFF_STATES, ch);
        if (p) {
            int index = p-OFF_STATES;
            _iCadeState &= ~(1 << index);
            stateChanged = true;
            if (_delegateFlags.buttonUp) {
                [_delegate buttonUp:(1 << index)];
            }
        }
    }
    
    
    if (stateChanged && _delegateFlags.stateChanged) {
        [_delegate stateChanged:_iCadeState];
    }
    
    static int cycleResponder = 0;
    if (++cycleResponder > 20) {
        // necessary to clear a buffer that accumulates internally
        cycleResponder = 0;
        [self resignFirstResponder];
        [self becomeFirstResponder];
    }
}

- (void)deleteBackward {
    // This space intentionally left blank to complete protocol
}

@end
