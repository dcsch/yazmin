//
//  StoryFacet.m
//  Yazmin
//
//  Created by David Schweinsberg on 3/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryFacet.h"
#import "Preferences.h"
#import "Story.h"

@interface StoryFacet () {
  int _fontId;
}

@end

@implementation StoryFacet

- (instancetype)initWithStory:(Story *)story {
  self = [super init];
  if (self) {
    _story = story;
    _textStorage = [[NSTextStorage alloc] init];

    // Initialize with the user-defined font
    BOOL upperWindow = self.numberOfLines == -1;
    if (upperWindow)
      [self setFontId:4];
    else
      [self setFontId:1];
  }
  return self;
}

- (int)line {
  return 1;
}

- (int)column {
  return 1;
}

- (int)numberOfLines {
  return -1;
}

- (void)setNumberOfLines:(int)lines {
  // nop
}

- (void)erase {
  NSRange range = NSMakeRange(0, _textStorage.length);
  [_textStorage deleteCharactersInRange:range];
  [_story updateWindowBackgroundColor];
}

- (void)setCursorLine:(int)line column:(int)column {
  NSLog(@"setCursorLine:%d column:%d", line, column);
}

- (int)setFontId:(int)fontId {
  if (fontId == 0)
    return _fontId;

  int prevFontId = _fontId;
  _fontId = fontId;
  return prevFontId;
}

- (void)applyColorsOfStyle:(int)style
              toAttributes:(NSMutableDictionary *)attributes {

  // If style is reverse, assign the colors appropriately
  if (style & 1) {
    attributes[NSForegroundColorAttributeName] = _story.backgroundColor;
    attributes[NSBackgroundColorAttributeName] = _story.foregroundColor;
  } else {
    attributes[NSForegroundColorAttributeName] = _story.foregroundColor;
    attributes[NSBackgroundColorAttributeName] = _story.backgroundColor;
  }
}

- (void)applyFontOfStyle:(int)style
            toAttributes:(NSMutableDictionary *)attributes {
  if (_story.forceFixedPitchFont)
    style |= 8;
  NSFont *font = [[Preferences sharedPreferences] fontForStyle:style];
  attributes[NSFontAttributeName] = font;
}

- (void)applyLowerWindowAttributes:(NSMutableDictionary *)attributes {
  NSMutableParagraphStyle *paragraphStyle =
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  paragraphStyle.alignment = NSTextAlignmentJustified;
  paragraphStyle.hyphenationFactor = 1.0;
  attributes[NSParagraphStyleAttributeName] = paragraphStyle;
}

- (void)print:(NSString *)text {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  [self applyColorsOfStyle:_story.currentStyle toAttributes:attributes];
  [self applyFontOfStyle:_story.currentStyle toAttributes:attributes];
  [self applyLowerWindowAttributes:attributes];
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:text attributes:attributes];
  [_textStorage appendAttributedString:attrText];
  [self updateStyleState];
}

- (void)printNumber:(int)number {
  [self print:(@(number)).stringValue];
}

- (void)newLine {
  [self print:@"\n"];
}

- (void)updateStyleState {
  //  _justSetTextStyle = NO;
}

@end
