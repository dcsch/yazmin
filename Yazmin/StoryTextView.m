//
//  StoryTextView.m
//  Yazmin
//
//  Created by David Schweinsberg on 6/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryTextView.h"
#import "StoryInput.h"
#include <Carbon/Carbon.h>

@interface StoryTextView () {
  NSUInteger inputLocation;
  InputState _inputState;
  BOOL _moreToDisplay;
  NSMutableArray<NSString *> *inputHistory;
  NSUInteger historyIndex;
  NSMutableArray<NSEvent *> *keyEvents;
}

- (void)useInputHistoryIndex:(NSUInteger)index;
- (void)checkFinalPage;
- (void)handleLiveScroll:(NSNotification *)notification;

@end

@implementation StoryTextView

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    inputLocation = 0;
    _storyInput = nil;
    _inputView = NO;
    self.inputState = kNoInputState;
    inputHistory = [NSMutableArray array];
    historyIndex = 0;
    keyEvents = [NSMutableArray array];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(handleLiveScroll:)
               name:NSScrollViewDidLiveScrollNotification
             object:self.superview.superview];
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
  if (_inputState == kStringInputState)
    [self setEditable:YES];
  else
    [self setEditable:NO];
}

- (BOOL)isMoreToDisplay {
  return _moreToDisplay;
}

- (void)setMoreToDisplay:(BOOL)moreToDisplay {
  _moreToDisplay = moreToDisplay;
}

- (void)useInputHistoryIndex:(NSUInteger)index {
  NSRange range =
      NSMakeRange(inputLocation, self.textStorage.length - inputLocation);
  if (index > 0) {
    NSString *input = inputHistory[inputHistory.count - index];
    [self.textStorage replaceCharactersInRange:range withString:input];
  } else {
    [self.textStorage deleteCharactersInRange:range];
  }
}

- (void)checkFinalPage {
  // Is this more than one page yet to display?
  NSRect textRect =
      [self.layoutManager usedRectForTextContainer:self.textContainer];
  NSRect visibleRect = self.visibleRect;
  visibleRect.origin.y += visibleRect.size.height;
  if (NSMaxY(textRect) <= NSMaxY(visibleRect)) {
    _moreToDisplay = NO;
  }
}

- (void)handleLiveScroll:(NSNotification *)notification {
  // Is this the last page?
  NSRect textRect =
      [self.layoutManager usedRectForTextContainer:self.textContainer];
  NSRect visibleRect = self.visibleRect;
  if (NSMaxY(textRect) <= NSMaxY(visibleRect)) {
    _moreToDisplay = NO;
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

- (void)insertText:(NSString *)string
    replacementRange:(NSRange)replacementRange {
  [super insertText:string replacementRange:replacementRange];

  if (_inputState == kCharacterInputState && string.length > 0) {
    [_storyInput characterInput:[string characterAtIndex:0]];
  }
}

- (void)mouseDown:(NSEvent *)event {
  if (_inputState == kCharacterInputState && !_moreToDisplay)
    [_storyInput characterInput:254];
  else
    [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {

  // Are we waiting to display more text?
  if (_inputState != kNoInputState && _moreToDisplay) {
    switch (event.keyCode) {
    //      case kVK_PageDown:
    //        break;
    //      case kVK_PageUp:
    //        break;
    case kVK_Space:
      [self checkFinalPage];
      [self pageDown:self];
      break;
      //      case kVK_Return:
      //        break;
    }
    return;
  }

  if (_inputState == kStringInputState) {

    switch (event.keyCode) {
    case kVK_LeftArrow: {
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

    default: {
      NSRange selection = self.selectedRange;
      if (selection.location < inputLocation)
        self.selectedRange = NSMakeRange(self.textStorage.length, 0);
      [super keyDown:event];
    }
    }

  } else if (_inputState == kCharacterInputState) {
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

- (void)insertNewline:(id)sender {
  [super insertNewline:sender];
  NSRange range =
      NSMakeRange(inputLocation, self.textStorage.length - inputLocation - 1);
  NSString *input = [self.textStorage.string substringWithRange:range];
  [_storyInput stringInput:input];

  [inputHistory addObject:input];
  historyIndex = 0;
}

- (void)enterString:(NSString *)input {
  NSRange range =
      NSMakeRange(inputLocation, self.textStorage.length - inputLocation);
  [self.textStorage replaceCharactersInRange:range withString:input];
  [self.textStorage.mutableString appendString:@"\n"];
  [_storyInput stringInput:input];
}

@end
