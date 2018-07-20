//
//  StoryFacet.h
//  Yazmin
//
//  Created by David Schweinsberg on 3/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Story;

@interface StoryFacet : NSObject
{
    Story *story;
    NSTextStorage *textStorage;
    NSMutableDictionary *currentAttributes;
    int currentStyle;
}

- (instancetype)initWithStory:(Story *)aStory NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property (copy) NSTextStorage *textStorage;
@property (readonly, copy) NSMutableDictionary *currentAttributes;
@property (readonly) int currentStyle;
@property  int numberOfLines;
- (void)erase;
- (void)setColourForeground:(int)fg background:(int)bg;
- (void)setCursorLine:(int)line column:(int)column;
- (void)setTextStyle:(int)style;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;

@end
