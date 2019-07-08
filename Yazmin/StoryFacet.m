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
  int _fontID;
}

- (NSFont *)fontForStyle:(int)style;

@end

@implementation StoryFacet

- (instancetype)initWithStory:(Story *)story {
  self = [super init];
  if (self) {
    _story = story;
    _textStorage = [[NSTextStorage alloc] init];

    // Initialize with the user-defined font
    BOOL upperWindow = self.numberOfLines > -1;
    if (upperWindow)
      self.fontID = 4;
    else
      self.fontID = 1;
  }
  return self;
}

- (int)line {
  return 1;
}

- (int)column {
  return 1;
}

- (int)fontID {
  return _fontID;
}

- (void)setFontID:(int)fontID {
  _fontID = fontID;
}

- (NSFont *)fontForStyle:(int)style {
  // Mask-off the reverse flag bit, as the font will be the same anyhow
  style &= 0xfe;

  // Check our font cache for this style
//  NSFont *font = fonts[@(style)];
//  if (font == nil) {

  NSFontDescriptor *fontDescriptor = nil;
  BOOL upperWindow = self.numberOfLines > -1;
  NSString *name = nil;
  switch (_fontID) {
    case 1:
      if (upperWindow)
        name = Preferences.sharedPreferences.monospacedFontFamily;
      else
        name = Preferences.sharedPreferences.proportionalFontFamily;
      break;
    case 3:
      name = Preferences.sharedPreferences.characterGraphicsFontFamily;
      break;
    case 4:
      name = Preferences.sharedPreferences.monospacedFontFamily;
      break;
  }

  // Bold and italic traits?
  NSFontDescriptorSymbolicTraits traits = 0;
  if (style & 6) {
    if (style & 2)
      traits |= NSFontDescriptorTraitBold;
    if (style & 4)
      traits |= NSFontDescriptorTraitItalic;
  }

  if (name) {
    float size = Preferences.sharedPreferences.fontSize;
    NSDictionary<NSFontDescriptorAttributeName, id> *attrs =
    @{NSFontFamilyAttribute: name,
      NSFontSizeAttribute: @(size),
      NSFontTraitsAttribute: @{NSFontSymbolicTrait: @(traits)}
    };
    fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:attrs];
  }

  float size = Preferences.sharedPreferences.fontSize;
  NSFont *font = [NSFont fontWithDescriptor:fontDescriptor size:size];
//    fonts[@(style)] = font;
//  }

//  NSLog(@"Font name: %@", font.fontName);

  return font;
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

- (void)eraseLine {
  // nop
}

- (void)setCursorLine:(int)line column:(int)column {
  NSLog(@"setCursorLine:%d column:%d", line, column);
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
  NSFont *font = [self fontForStyle:style];
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
  [_textStorage beginEditing];
  [_textStorage appendAttributedString:attrText];
  [_textStorage endEditing];
}

- (void)printNumber:(int)number {
  [self print:(@(number)).stringValue];
}

- (void)newLine {
  [self print:@"\n"];
}

@end
