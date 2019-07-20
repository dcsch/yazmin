//
//  StoryTextView.h
//  Yazmin
//
//  Created by David Schweinsberg on 6/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, InputState) {
  kNoInputState,
  kCharacterInputState,
  kStringInputState
};

@protocol StoryInput;

@interface StoryTextView : NSTextView

@property NSUInteger inputLocation;
@property(strong) id<StoryInput> storyInput;
@property(getter=isInputView) BOOL inputView;
@property InputState inputState;

- (void)enterString:(NSString *)input;

@end
