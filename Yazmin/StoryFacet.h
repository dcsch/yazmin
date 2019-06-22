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

- (instancetype)initWithStory:(Story *)story NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property Story *story;
@property NSTextStorage *textStorage;
@property(readonly) NSMutableDictionary *currentAttributes;
@property(readonly) int currentStyle;
@property BOOL forceFixedPitchFont;
@property int numberOfLines;
@property int widthInCharacters;
@property int heightInLines;
@property(readonly) NSColor *foregroundColor;
@property(readonly) NSColor *backgroundColor;
@property(readonly) int foregroundColorCode;
@property(readonly) int backgroundColorCode;

- (void)erase;
- (void)setColorForeground:(int)fg background:(int)bg;
- (void)setTrueColorForeground:(int)fg background:(int)bg;
- (void)setCursorLine:(int)line column:(int)column;
- (int)setFont:(int)fontId;
- (void)setTextStyle:(int)style;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;

@end
