//
//  GridStoryFacet.m
//  Yazmin
//
//  Created by David Schweinsberg on 5/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "GridStoryFacet.h"
#import "Story.h"

@interface GridStoryFacet () {
  int _numberOfLines;
  int x;
  int y;
}

- (NSArray<NSValue *> *)chunksOfString:(NSString *)string;
- (NSArray<NSValue *> *)rangesOfLines;
- (void)emplaceString:(NSString *)string;

@end

@implementation GridStoryFacet

- (instancetype)initWithStory:(Story *)aStory {
  self = [super initWithStory:aStory];
  if (self) {
    _numberOfLines = 0;
  }
  return self;
}

- (int)line {
  return y + 1;
}

- (int)column {
  return x + 1;
}

- (int)numberOfLines {
  return _numberOfLines;
}

- (void)setNumberOfLines:(int)lines {
  _numberOfLines = lines;
  [self.story updateWindowLayout];
}

- (void)erase {
  [super erase];
  x = 0;
  y = 0;
}

- (void)setCursorLine:(int)line column:(int)column {
  if (0 < line && line <= self.heightInLines)
    y = line - 1;
  if (0 < column && column <= self.widthInCharacters)
    x = column - 1;

  if (line > _numberOfLines) {
    static BOOL quitGriping = NO;
    if (!quitGriping) {
      NSLog(@"Setting cursor to line %d in a window of height %d", line,
            _numberOfLines);
      quitGriping = YES;
    }
    self.numberOfLines = line;
  }
}

- (void)print:(NSString *)text {

  // Break into individual lines
  NSArray<NSString *> *components =
      [text componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                     newlineCharacterSet]];
  NSUInteger count = components.count;
  for (NSString *component in components) {

    // Break into chunks that wrap at line ends
    NSArray<NSValue *> *chunks = [self chunksOfString:component];
    for (NSValue *chunk in chunks) {
      NSString *textChunk = [component substringWithRange:chunk.rangeValue];
      [self emplaceString:textChunk];
    }

    if (--count > 0) {
      // Explicit new line
      y++;
      x = 0;
    }
  }
  [self updateStyleState];
}

- (void)printNumber:(int)number {
  NSString *str = (@(number)).stringValue;
  [self print:str];
}

- (void)newLine {
  y++;
  x = 0;
  [self updateStyleState];
}

- (NSArray<NSValue *> *)chunksOfString:(NSString *)string {
  NSMutableArray *array = [NSMutableArray array];
  NSUInteger pos = x;
  NSUInteger strLen = string.length;
  NSUInteger chunkStart = 0;
  while (strLen > self.widthInCharacters - pos) {
    NSUInteger chunkLen = self.widthInCharacters - pos;
    [array
        addObject:[NSValue valueWithRange:NSMakeRange(chunkStart, chunkLen)]];
    chunkStart += chunkLen;
    strLen -= chunkLen;
    pos = 0;
  }
  [array addObject:[NSValue valueWithRange:NSMakeRange(chunkStart, strLen)]];
  return array;
}

- (NSArray<NSValue *> *)rangesOfLines {
  NSMutableArray *array = [NSMutableArray array];
  NSString *str = self.textStorage.string;
  NSUInteger start = 0;
  for (NSUInteger i = 0; i < str.length; i++) {
    if ([str characterAtIndex:i] == '\n') {
      [array addObject:[NSValue valueWithRange:NSMakeRange(start, i - start)]];
      start = i + 1;
    }
  }
  [array addObject:[NSValue
                       valueWithRange:NSMakeRange(start, str.length - start)]];
  return array;
}

- (void)applyUpperWindowAttributes:(NSMutableDictionary *)attributes {
  NSMutableParagraphStyle *paragraphStyle =
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  paragraphStyle.lineBreakMode = NSLineBreakByClipping;
  attributes[NSParagraphStyleAttributeName] = paragraphStyle;
}

- (void)emplaceString:(NSString *)string {

  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  [self applyFontOfStyle:self.story.currentStyle | 8 toAttributes:attributes];
  [self applyUpperWindowAttributes:attributes];

  // We need attributes for padding without reverse video
  NSMutableDictionary *paddingAttributes = [attributes mutableCopy];
  [self applyColorsOfStyle:self.story.currentStyle & ~1
              toAttributes:paddingAttributes];

  [self applyColorsOfStyle:self.story.currentStyle toAttributes:attributes];

  // Get the line ranges, extending if we need more lines
  NSArray<NSValue *> *ranges = [self rangesOfLines];
  if (ranges.count <= y) {
    NSAttributedString *attrText =
        [[NSAttributedString alloc] initWithString:@"\n"
                                        attributes:paddingAttributes];
    for (int i = 0; i <= y - ranges.count; i++)
      [self.textStorage appendAttributedString:attrText];
    ranges = [self rangesOfLines];
  }

  NSRange range = ranges[y].rangeValue;

  if (x >= range.length) {

    // Insert padding (with fixed-font attributes)
    NSMutableString *padding = [NSMutableString string];
    if (x > range.length)
      for (NSUInteger i = range.length; i < x; i++)
        [padding appendString:@" "];

    NSAttributedString *attrText =
        [[NSAttributedString alloc] initWithString:padding
                                        attributes:paddingAttributes];
    [self.textStorage insertAttributedString:attrText
                                     atIndex:NSMaxRange(range)];

    // Append string (with full attributes)
    attrText = [[NSAttributedString alloc] initWithString:string
                                               attributes:attributes];
    [self.textStorage
        insertAttributedString:attrText
                       atIndex:NSMaxRange(range) + padding.length];

  } else {

    NSRange replaceRange;
    if (string.length > range.length - x) {

      // replace from x to the end of the line
      replaceRange = NSMakeRange(range.location + x, range.length - x);
    } else {

      // replace within the matching range
      replaceRange = NSMakeRange(range.location + x, string.length);
    }

    NSAttributedString *attrText =
        [[NSAttributedString alloc] initWithString:string
                                        attributes:attributes];
    [self.textStorage replaceCharactersInRange:replaceRange
                          withAttributedString:attrText];
  }

  y += (x + string.length) / self.widthInCharacters;
  x = (x + string.length) % self.widthInCharacters;
}

- (void)eraseFromLine:(int)line {

  // How many lines are already in the window?
  NSArray<NSValue *> *ranges = [self rangesOfLines];
  if (ranges.count > line) {
    NSRange range = ranges[line - 1].rangeValue;
    NSRange rangeToEnd =
        NSMakeRange(range.location, self.textStorage.length - range.location);
    [self.textStorage deleteCharactersInRange:rangeToEnd];
  }
}

@end
