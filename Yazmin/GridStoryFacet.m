//
//  GridStoryFacet.m
//  Yazmin
//
//  Created by David Schweinsberg on 5/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "GridStoryFacet.h"
#import "Story.h"

@interface GridStoryFacet (Private)
- (void)configureBuffer;
- (void)printString:(NSString *)string;
@end

@implementation GridStoryFacet

- (id)initWithStory:(Story *)aStory columns:(int)columns
{
    self = [super initWithStory:aStory];
    if (self)
    {
        numberOfLines = 0;
        numberOfColumns = columns;
        resizeToNumberOfColumns = columns;
        [self setTextStyle:0];
    }
    return self;
}

- (int)numberOfLines
{
    return numberOfLines;
}

- (void)setNumberOfLines:(int)lines
{
    numberOfLines = lines;
    [self configureBuffer];
    [story updateWindowLayout];
}

- (int)numberOfColumns
{
    // We'll defer the configuration of the buffer, so that the update
    // occurs during the next print operation
    return resizeToNumberOfColumns;
}

- (void)setNumberOfColumns:(int)columns
{
    resizeToNumberOfColumns = columns;
}

- (void)setCursorLine:(int)line column:(int)column
{
    y = line - 1;
    x = column - 1;
}

- (void)setTextStyle:(int)style
{
    // Make sure we always use a fixed-width font
    [super setTextStyle:style | 8];
}

- (void)print:(NSString *)text
{
    if (numberOfColumns != resizeToNumberOfColumns)
    {
        [self configureBuffer];
        [story updateWindowWidth];
    }
    
    [self printString:text];
}

- (void)printNumber:(int)number
{
    if (numberOfColumns != resizeToNumberOfColumns)
    {
        [self configureBuffer];
        [story updateWindowWidth];
    }

    NSString *str = [[NSNumber numberWithInt:number] stringValue];
    [self printString:str];
}

- (void)newLine
{
    // nop
}

- (void)configureBuffer
{
    numberOfColumns = resizeToNumberOfColumns;

    // Ensure that the text storage has characters in the full range
    [self erase];
    [self setTextStyle:0];
    unsigned int len = numberOfLines * numberOfColumns;
    NSMutableString *fill = [[NSMutableString alloc] initWithCapacity:len];
    int i;
    for (i = 0; i < len; ++i)
        [fill appendString:@" "];
    
    // We use the superclass as this appends rather than replaces
    [super print:fill];
    [fill release];
}

- (void)printString:(NSString *)string
{
    NSRange range = NSMakeRange(numberOfColumns * y + x, [string length]);
    NSAttributedString *attrText =
        [[[NSAttributedString alloc] initWithString:string
                                         attributes:currentAttributes] autorelease];
    [textStorage replaceCharactersInRange:range withAttributedString:attrText];
    x += [string length];
}

@end
