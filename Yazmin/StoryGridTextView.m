//
//  StoryInputTextView.m
//  Yazmin
//
//  Created by David Schweinsberg on 1/9/20.
//  Copyright © 2020 David Schweinsberg. All rights reserved.
//

#import "StoryGridTextView.h"
#import "StoryInput.h"
#include <Carbon/Carbon.h>

@interface StoryGridTextView () {
  NSUInteger inputLocation;
  InputState _inputState;
  NSMutableArray<NSEvent *> *keyEvents;
}

@end

@implementation StoryGridTextView

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    inputLocation = 0;
    _storyInput = nil;
    _inputView = NO;
    self.inputState = kNoInputState;
    keyEvents = [NSMutableArray array];
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

- (NSUInteger)inputLocation {
  return inputLocation;
}

- (void)setInputLocation:(NSUInteger)location {
  inputLocation = location;
}

- (InputState)inputState {
  return _inputState;
}

- (void)setInputState:(InputState)state {
  _inputState = state;
  if (_showCursorForInput && _inputState == kCharacterInputState)
    [self setEditable:YES];
  else
    [self setEditable:NO];
}

// If we have a touch bar, it flashes on and off during timed input for
// something like Tetris, as the 'editable' state changes with the input state
// above
- (NSTouchBar *)makeTouchBar {
  return nil;
}

- (void)insertText:(NSString *)string
    replacementRange:(NSRange)replacementRange {
  if (_inputState == kCharacterInputState && string.length > 0) {
    [_storyInput characterInput:[string characterAtIndex:0]];
  }
}

- (void)mouseDown:(NSEvent *)event {
  if (_inputState == kCharacterInputState) {
    [_storyInput characterInput:254];
  } else
    [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {

  if (_inputState == kCharacterInputState) {
    unichar code;
    switch (event.keyCode) {
    case kVK_Delete:
    case kVK_ForwardDelete:
      code = 8;
      break;
    case kVK_Return:
      code = 13;
      break;
    case kVK_Escape:
      code = 27;
      break;
    case kVK_UpArrow:
      code = 129;
      break;
    case kVK_DownArrow:
      code = 130;
      break;
    case kVK_LeftArrow:
      code = 131;
      break;
    case kVK_RightArrow:
      code = 132;
      break;
    case kVK_F1:
      code = 133;
      break;
    case kVK_F2:
      code = 134;
      break;
    case kVK_F3:
      code = 135;
      break;
    case kVK_F4:
      code = 136;
      break;
    case kVK_F5:
      code = 137;
      break;
    case kVK_F6:
      code = 138;
      break;
    case kVK_F7:
      code = 139;
      break;
    case kVK_F8:
      code = 140;
      break;
    case kVK_F9:
      code = 141;
      break;
    case kVK_F10:
      code = 142;
      break;
    case kVK_F11:
      code = 143;
      break;
    case kVK_F12:
      code = 144;
      break;
    case kVK_ANSI_Keypad0:
      code = 145;
      break;
    case kVK_ANSI_Keypad1:
      code = 146;
      break;
    case kVK_ANSI_Keypad2:
      code = 147;
      break;
    case kVK_ANSI_Keypad3:
      code = 148;
      break;
    case kVK_ANSI_Keypad4:
      code = 149;
      break;
    case kVK_ANSI_Keypad5:
      code = 150;
      break;
    case kVK_ANSI_Keypad6:
      code = 151;
      break;
    case kVK_ANSI_Keypad7:
      code = 152;
      break;
    case kVK_ANSI_Keypad8:
      code = 153;
      break;
    case kVK_ANSI_Keypad9:
      code = 154;
      break;
    case kVK_ANSI_KeypadEnter:
      code = 13;
      break;
    default:
      code = 0;
      [keyEvents addObject:event];
      if (event.characters.length > 0) {
        [self interpretKeyEvents:keyEvents];
        [keyEvents removeAllObjects];
      }
    }
    if (code) {
      [_storyInput characterInput:code];
      [keyEvents removeAllObjects];
    }
  }
}

@end
