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
  int _numberOfColumns;
  int x;
  int y;
  NSDictionary *fixedFontAttributes;
}

- (NSArray<NSValue *> *)chunksOfString:(NSString *)string;
- (NSArray<NSValue *> *)rangesOfLines;
- (void)emplaceString:(NSString *)string;

@end

@implementation GridStoryFacet

- (instancetype)initWithStory:(Story *)aStory columns:(int)columns {
  self = [super initWithStory:aStory];
  if (self) {
    _numberOfLines = 0;
    _numberOfColumns = columns;
    [self setTextStyle:0];
    fixedFontAttributes = [currentAttributes copy];
  }
  return self;
}

- (int)numberOfLines {
  return _numberOfLines;
}

- (void)setNumberOfLines:(int)lines {
  _numberOfLines = lines;
  [story updateWindowLayout];
}

- (int)numberOfColumns {
  return _numberOfColumns;
}

- (void)setNumberOfColumns:(int)columns {
  _numberOfColumns = columns;
  //  [story updateWindowLayout];
  [story updateWindowWidth];
}

- (void)setCursorLine:(int)line column:(int)column {
  y = line - 1;
  x = column - 1;
}

- (void)setTextStyle:(int)style {
  // Make sure we always use a fixed-width font
  [super setTextStyle:style | 8];
}

- (void)print:(NSString *)text {
  NSArray<NSValue *> *chunks = [self chunksOfString:text];
  for (NSValue *chunk in chunks) {
    NSString *textChunk = [text substringWithRange:chunk.rangeValue];
    [self emplaceString:textChunk];
  }
}

- (void)printNumber:(int)number {
  NSString *str = (@(number)).stringValue;
  [self print:str];
}

- (void)newLine {
  // nop
}

- (NSArray<NSValue *> *)chunksOfString:(NSString *)string {
  NSMutableArray *array = [NSMutableArray array];
  NSUInteger pos = x;
  NSUInteger strLen = string.length;
  NSUInteger chunkStart = 0;
  while (strLen > _numberOfColumns - pos) {
    NSUInteger chunkLen = _numberOfColumns - pos;
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
  NSString *str = textStorage.string;
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

- (void)emplaceString:(NSString *)string {

  // Get the line ranges, extending if we need more lines
  NSArray<NSValue *> *ranges = [self rangesOfLines];
  if (ranges.count <= y) {
    NSAttributedString *attrText =
        [[NSAttributedString alloc] initWithString:@"\n"
                                        attributes:fixedFontAttributes];
    for (int i = 0; i <= y - ranges.count; i++)
      [textStorage appendAttributedString:attrText];
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
                                        attributes:fixedFontAttributes];
    [textStorage insertAttributedString:attrText atIndex:NSMaxRange(range)];

    // Append string (with full attributes)
    attrText = [[NSAttributedString alloc] initWithString:string
                                               attributes:currentAttributes];
    [textStorage insertAttributedString:attrText
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
                                        attributes:currentAttributes];
    [textStorage replaceCharactersInRange:replaceRange
                     withAttributedString:attrText];
  }

  y += (x + string.length) / _numberOfColumns;
  x = (x + string.length) % _numberOfColumns;
}

@end
