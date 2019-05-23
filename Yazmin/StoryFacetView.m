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
#include <Carbon/Carbon.h>

@interface StoryFacetView () {
  unsigned int inputLocation;
  InputState _inputState;
  NSMutableArray<NSString *> *inputHistory;
  NSUInteger historyIndex;
}

- (void)useInputHistoryIndex:(NSUInteger)index;

@end

@implementation StoryFacetView

- (instancetype)initWithFrame:(NSRect)frame
                textContainer:(NSTextContainer *)container {
  self = [super initWithFrame:frame textContainer:container];
  if (self) {
    inputLocation = 0;
    _storyInput = nil;
    _inputView = NO;
    self.inputState = kNoInputState;
    inputHistory = [NSMutableArray array];
    historyIndex = 0;
  }
  return self;
}

- (BOOL)acceptsFirstResponder {
  return _inputView;
}

- (BOOL)resignFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  return _inputView;
}

- (unsigned int)inputLocation {
  return inputLocation;
}

- (void)setInputLocation:(unsigned int)location {
  inputLocation = location;
}

- (InputState)inputState {
  return _inputState;
}

- (void)setInputState:(InputState)state {
  _inputState = state;
  if (_inputState == kStringInputState)
    [self setEditable:YES];
  else
    [self setEditable:NO];
}

- (void)useInputHistoryIndex:(NSUInteger)index {
  NSRange range = NSMakeRange(inputLocation,
                              self.textStorage.length - inputLocation);
  if (index > 0) {
    NSString *input = inputHistory[inputHistory.count - index];
    [self.textStorage replaceCharactersInRange:range withString:input];
  } else {
    [self.textStorage deleteCharactersInRange:range];
  }
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
  if (_inputState == kCharacterInputState) {
    // We'll simulate pressing the space bar if the user clicks in the
    // view in this state
    self.inputState = kNoInputState;
    [_storyInput characterInput:' '];
  } else
    [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {
  if (_inputState == kStringInputState) {

    switch (event.keyCode) {
      case kVK_LeftArrow:
      {
        NSRange selection = self.selectedRange;
        if (selection.location > inputLocation)
          [super keyDown:event];
        break;
      }

      case kVK_UpArrow:
        if (inputHistory.count > historyIndex) {
          historyIndex++;
          [self useInputHistoryIndex:historyIndex];
        }
        break;

      case kVK_DownArrow:
        if (historyIndex > 0) {
          historyIndex--;
          [self useInputHistoryIndex:historyIndex];
        }
        break;

      default:
      {
        NSRange selection = self.selectedRange;
        if (selection.location < inputLocation)
          self.selectedRange = NSMakeRange(self.textStorage.length, 0);
        [super keyDown:event];
      }
    }

  } else if (_inputState == kCharacterInputState) {
    // Reset the input state
    self.inputState = kNoInputState;
    [_storyInput characterInput:[event.characters characterAtIndex:0]];
  }
}

- (void)insertNewline:(id)sender {
  [super insertNewline:sender];

  // Reset the input state
  self.inputState = kNoInputState;

  NSRange range =
      NSMakeRange(inputLocation, self.textStorage.length - inputLocation - 1);
  NSAttributedString *input =
      [self.textStorage attributedSubstringFromRange:range];

  NSString *rawInput = [NSString stringWithString:input.string];
  [_storyInput stringInput:rawInput];

  [inputHistory addObject:rawInput];
  historyIndex = 0;
}

@end
