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

@interface StoryInputTextView : NSTextView

@property(strong) id<StoryInput> storyInput;
@property(getter=isInputView) BOOL inputView;
@property InputState inputState;

@end

NS_ASSUME_NONNULL_END
