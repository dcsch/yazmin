//
//  StoryFacetView.m
//  Yazmin
//
//  Created by David Schweinsberg on 6/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryFacetView.h"
#import "LayoutView.h"
#import "StoryInput.h"

@implementation StoryFacetView

- (instancetype)initWithFrame:(NSRect)frame
                textContainer:(NSTextContainer *)container {
  self = [super initWithFrame:frame textContainer:container];
  if (self) {
    inputLocation = 0;
    storyInput = nil;
    inputView = NO;
    [self setInputState:kNoInputState];
  }
  return self;
}

- (BOOL)acceptsFirstResponder {
  return inputView;
}

- (BOOL)resignFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  return inputView;
}

- (unsigned int)inputLocation {
  return inputLocation;
}

- (void)setInputLocation:(unsigned int)location {
  inputLocation = location;
}

- (id<StoryInput>)storyInput {
  return storyInput;
}

- (void)setStoryInput:(id<StoryInput>)input {
  storyInput = input;
}

- (BOOL)isInputView {
  return inputView;
}

- (void)setInputView:(BOOL)flag {
  inputView = flag;
}

- (int)inputState {
  return inputState;
}

- (void)setInputState:(int)state {
  inputState = state;
  if (inputState == kStringInputState)
    [self setEditable:YES];
  else
    [self setEditable:NO];
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange
              replacementString:(NSString *)replacementString {
  // Is the text being input at the end of the story text?  If not, reject it.
  if (inputLocation > affectedCharRange.location)
    return NO;
  else
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
  if (inputState == kCharacterInputState) {
    // We'll simulate pressing the space bar if the user clicks in the
    // view in this state
    [self setInputState:kNoInputState];
    [storyInput characterInput:' '];
  } else
    [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {
  //    [self interpretKeyEvents:[NSArray arrayWithObject:event]];

  if (inputState == kStringInputState)
    [super keyDown:event];
  else if (inputState == kCharacterInputState) {
    // Reset the input state
    [self setInputState:kNoInputState];
    [storyInput characterInput:[event.characters characterAtIndex:0]];
  }
}

- (void)insertNewline:(id)sender {
  NSLog(@"[New Line]");
  [super insertNewline:sender];

  // Reset the input state
  [self setInputState:kNoInputState];

  NSRange range =
      NSMakeRange(inputLocation, self.textStorage.length - inputLocation - 1);
  NSAttributedString *input =
      [self.textStorage attributedSubstringFromRange:range];

  NSString *input2 = [NSString stringWithString:input.string];
  [storyInput stringInput:input2];
}

@end
