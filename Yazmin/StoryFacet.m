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
    _currentAttributes = [[NSMutableDictionary alloc] init];

    // Initialize with the user-defined font
    [self setFont:1];
    [self setTextStyle:0];
  }
  return self;
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
}

- (void)setColorForeground:(int)fg background:(int)bg {
}

- (void)setCursorLine:(int)line column:(int)column {
  // nop
}

- (int)setFont:(int)fontId {
  NSFont *font = nil;
  if (fontId == 0)
    return _fontId;
  else if (fontId == 1)
    font = [[Preferences sharedPreferences] fontForStyle:0];
  else if (fontId == 4)
    font = [[Preferences sharedPreferences] fontForStyle:8];
  if (font) {
    _currentAttributes[NSFontAttributeName] = font;
    int prevFontId = _fontId;
    _fontId = fontId;
    return prevFontId;
  }
  return 0;
}

- (void)setTextStyle:(int)style {
  _currentStyle = style;

  NSMutableParagraphStyle *paragraphStyle =
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  if (self.numberOfLines > -1) {
    // Upper window
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
  } else {
    // Lower window
    paragraphStyle.alignment = NSTextAlignmentJustified;
    paragraphStyle.hyphenationFactor = 1.0;
  }
  _currentAttributes[NSParagraphStyleAttributeName] = paragraphStyle;

  // Retrieve the preferred font for this style
  NSFont *font = [[Preferences sharedPreferences] fontForStyle:style];
  _currentAttributes[NSFontAttributeName] = font;

  //    // Is it reverse video?
  //    NSColor *bgColor = [[Preferences sharedPreferences] backgroundColor];
  //    NSColor *fgColor = [[Preferences sharedPreferences] foregroundColor];

  NSColor *bgColor = [NSColor textBackgroundColor];
  NSColor *fgColor = [NSColor textColor];

  if (style & 1) {
    _currentAttributes[NSBackgroundColorAttributeName] = fgColor;
    _currentAttributes[NSForegroundColorAttributeName] = bgColor;
  } else {
    _currentAttributes[NSBackgroundColorAttributeName] = bgColor;
    _currentAttributes[NSForegroundColorAttributeName] = fgColor;
  }
}

- (void)print:(NSString *)text {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:text
                                      attributes:_currentAttributes];
  [_textStorage appendAttributedString:attrText];
}

- (void)printNumber:(int)number {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:(@(number)).stringValue
                                      attributes:_currentAttributes];
  [_textStorage appendAttributedString:attrText];
}

- (void)newLine {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:@"\n"
                                      attributes:_currentAttributes];
  [_textStorage appendAttributedString:attrText];
}

@end
