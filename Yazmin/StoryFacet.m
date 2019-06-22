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
  NSColor *_foregroundColor;
  NSColor *_backgroundColor;
  BOOL _justSetTextStyle;
}

- (void)updateColorAttributes;
- (NSColor *)colorFromCode:(int)colorCode
              currentColor:(NSColor *)currentColor
              defaultColor:(NSColor *)defaultColor;
- (NSColor *)colorFromTrueColor:(int)trueColor
                   currentColor:(NSColor *)currentColor
                   defaultColor:(NSColor *)defaultColor;
- (NSDictionary *)attributesForPrinting;

@end

@implementation StoryFacet

- (instancetype)initWithStory:(Story *)story {
  self = [super init];
  if (self) {
    _story = story;
    _textStorage = [[NSTextStorage alloc] init];
    _currentAttributes = [[NSMutableDictionary alloc] init];

    // Default colors
    [self setColorForeground:1 background:1];

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

- (int)closestColorCodeToColor:(NSColor *)color {
  color = [color colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  CGFloat r1, g1, b1, a1;
  [color getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  int closestCode = 0;
  CGFloat closestDistance = 2.0;
  for (int i = 2; i <= 9; ++i) {
    NSColor *paletteColor =
        [[self colorFromCode:i currentColor:nil defaultColor:nil]
            colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    CGFloat r2, g2, b2, a2;
    [paletteColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    CGFloat dr = fabs(r2 - r1);
    CGFloat dg = fabs(g2 - g1);
    CGFloat db = fabs(b2 - b1);
    CGFloat distance = sqrt(dr * dr + dg * dg + db * db);

    if (closestDistance > distance) {
      closestDistance = distance;
      closestCode = i;
    }
  }
  return closestCode;
}

- (int)foregroundColorCode {
  return [self closestColorCodeToColor:_foregroundColor];
}

- (int)backgroundColorCode {
  return [self closestColorCodeToColor:_backgroundColor];
}

// From the Z-machine standard 1.1 (8.3.1):
// 0 = current     (true -2)
// 1 = default     (true -1)
// 2 = black       (true $0000, $$0000000000000000)
// 3 = red         (true $001D, $$0000000000011101)
// 4 = green       (true $0340, $$0000001101000000)
// 5 = yellow      (true $03BD, $$0000001110111101)
// 6 = blue        (true $59A0, $$0101100110100000)
// 7 = magenta     (true $7C1F, $$0111110000011111)
// 8 = cyan        (true $77A0, $$0111011110100000)
// 9 = white       (true $7FFF, $$0111111111111111)
- (NSColor *)colorFromCode:(int)colorCode
              currentColor:(NSColor *)currentColor
              defaultColor:(NSColor *)defaultColor {
  switch (colorCode) {
  case 0:
    return currentColor;
  case 1:
    return defaultColor;
  case 2:
    return [NSColor blackColor];
  case 3:
    return [NSColor redColor];
  case 4:
    return [NSColor greenColor];
  case 5:
    return [NSColor yellowColor];
  case 6:
    return [NSColor blueColor];
  case 7:
    return [NSColor magentaColor];
  case 8:
    return [NSColor cyanColor];
  case 9:
    return [NSColor whiteColor];
  }
  return currentColor;
}

- (void)updateColorAttributes {

  // If style is reverse, assign the colors appropriately
  if (_currentStyle & 1) {
    _currentAttributes[NSForegroundColorAttributeName] = _backgroundColor;
    _currentAttributes[NSBackgroundColorAttributeName] = _foregroundColor;
    //    NSLog(@"Video reverse");
  } else {
    _currentAttributes[NSForegroundColorAttributeName] = _foregroundColor;
    _currentAttributes[NSBackgroundColorAttributeName] = _backgroundColor;
    //    NSLog(@"Video normal");
  }
}

- (void)setColorForeground:(int)fg background:(int)bg {
  _foregroundColor = [self colorFromCode:fg
                            currentColor:_foregroundColor
                            defaultColor:[NSColor textColor]];
  _backgroundColor = [self colorFromCode:bg
                            currentColor:_backgroundColor
                            defaultColor:[NSColor textBackgroundColor]];
  [self updateColorAttributes];
}

- (NSColor *)colorFromTrueColor:(int)trueColor
                   currentColor:(NSColor *)currentColor
                   defaultColor:(NSColor *)defaultColor {
  if (trueColor == -2)
    return currentColor;
  else if (trueColor == -1)
    return defaultColor;
  uint8 r = trueColor & 0x1f;
  uint8 g = (trueColor >> 5) & 0x1f;
  uint8 b = (trueColor >> 10) & 0x1f;
  return [NSColor colorWithRed:r / 31.0 green:g / 31.0 blue:b / 31.0 alpha:1.0];
}

- (void)setTrueColorForeground:(int)fg background:(int)bg {
  _foregroundColor = [self colorFromTrueColor:fg
                                 currentColor:_foregroundColor
                                 defaultColor:[NSColor textColor]];
  _backgroundColor = [self colorFromTrueColor:bg
                                 currentColor:_backgroundColor
                                 defaultColor:[NSColor textBackgroundColor]];
  [self updateColorAttributes];
}

- (void)setCursorLine:(int)line column:(int)column {
  NSLog(@"setCursorLine:%d column:%d", line, column);
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

  // If multiple style commands are sent in a sequence, we'll
  // OR together the values, otherwise we'll just use the value
  // directly.
  if (style == 0)
    _currentStyle = style;
  else if (_justSetTextStyle)
    _currentStyle |= style;
  else
    _currentStyle = style;
  _justSetTextStyle = YES;

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
  NSFont *font = [[Preferences sharedPreferences] fontForStyle:_currentStyle];
  _currentAttributes[NSFontAttributeName] = font;

  // Handle reverse video with the color selection
  [self updateColorAttributes];
}

- (NSDictionary *)attributesForPrinting {
  NSDictionary *attributes = _currentAttributes;
  if (_forceFixedPitchFont) {
    NSFont *font = _currentAttributes[NSFontAttributeName];
    if (!font.isFixedPitch) {
      NSMutableDictionary *fixedAttributes = [_currentAttributes mutableCopy];
      fixedAttributes[NSFontAttributeName] =
          [[Preferences sharedPreferences] fontForStyle:_currentStyle | 8];
      attributes = fixedAttributes;
    }
  }
  return attributes;
}

- (void)print:(NSString *)text {
  NSAttributedString *attrText =
      [[NSAttributedString alloc] initWithString:text
                                      attributes:[self attributesForPrinting]];
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
  _justSetTextStyle = NO;
}

@end
