//
//  StoryFacetView.h
//  Yazmin
//
//  Created by David Schweinsberg on 6/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kNoInputState        0
#define kCharacterInputState 1
#define kStringInputState    2

@protocol StoryInput;

@interface StoryFacetView : NSTextView
{
    unsigned int inputLocation;
    id <StoryInput> storyInput;
    BOOL inputView;
    int inputState;
}

- (unsigned int) inputLocation;
- (void) setInputLocation:(unsigned int)location;
- (id <StoryInput>)storyInput;
- (void)setStoryInput:(id <StoryInput>)input;
- (BOOL)isInputView;
- (void)setInputView:(BOOL)flag;
- (int)inputState;
- (void)setInputState:(int)state;

@end
