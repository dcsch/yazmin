//
//  StoryInputTextView.h
//  Yazmin
//
//  Created by David Schweinsberg on 1/9/20.
//  Copyright © 2020 David Schweinsberg. All rights reserved.
//

#import "InputState.h"
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol StoryInput;

@interface StoryGridTextView : NSTextView

@property(strong) id<StoryInput> storyInput;
@property(getter=isInputView) BOOL inputView;
@property InputState inputState;
@property(getter=isShowCursorForInput) BOOL showCursorForInput;

@end

NS_ASSUME_NONNULL_END
