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

@implementation StoryFacet

- (instancetype)initWithStory:(Story *)aStory {
  self = [super init];
  if (self) {
    story = aStory;
    textStorage = [[NSTextStorage alloc] init];
    currentAttributes = [[NSMutableDictionary alloc] init];

    // Initialize with the user-defined font
    [self setTextStyle:0];
  }
  return self;
}

- (NSTextStorage *)textStorage {
  return textStorage;
}

- (void)setTextStorage:(NSTextStorage *)aTextStorage;
{ textStorage = aTextStorage; }

- (NSMutableDictionary *)currentAttributes {
  return currentAttributes;
}

- (int)currentStyle {
  return currentStyle;
}

- (int)numberOfLines {
  return -1;
}

- (void)setNumberOfLines:(int)lines {
  // nop
}

- (void)erase {
  NSRange range = NSMakeRange(0, textStorage.length);
  [textStorage deleteCharactersInRange:range];
}

- (void)setColorForeground:(int)fg background:(int)bg {
}

- (void)setCursorLine:(int)line column:(int)column {
  // nop
}

- (void)setTextStyle:(int)style {
  currentStyle = style;

  // Retrieve the preferred font for this style
  NSFont *font = [[Preferences sharedPreferences] fontForStyle:style];
  currentAttributes[NSFontAttributeName] = font;

  //    // Is it reverse video?
  //    NSColor *bgColor = [[Preferences sharedPreferences] backgroundColor];
  //    NSColor *fgColor = [[Preferences sharedPreferences] foregroundColor];

  NSColor *bgColor = [NSColor textBackgroundColor];
  NSColor *fgColor = [NSColor textColor];

  if (style & 1) {
    currentAttributes[NSBackgroundColorAttributeName] = fgColor;
    currentAttributes[NSForegroundColorAttributeName] = bgColor;
  } else {
    currentAttributes[NSBackgroundColorAttributeName] = bgColor;
    currentAttributes[NSForegroundColorAttributeName] = fgColor;
  }
}

- (void)print:(NSString *)text {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:text
                                      attributes:currentAttributes];
  [textStorage appendAttributedString:attrText];
}

- (void)printNumber:(int)number {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:(@(number)).stringValue
                                      attributes:currentAttributes];
  [textStorage appendAttributedString:attrText];
}

- (void)newLine {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:@"\n"
                                      attributes:currentAttributes];
  [textStorage appendAttributedString:attrText];
}

@end
