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
@property(readonly) int line;
@property(readonly) int column;
@property int numberOfLines;
@property int widthInCharacters;
@property int heightInLines;

- (void)erase;
- (void)setCursorLine:(int)line column:(int)column;
- (int)setFontId:(int)fontId;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)updateStyleState;
- (void)applyColorsOfStyle:(int)style
              toAttributes:(NSMutableDictionary *)attributes;
- (void)applyFontOfStyle:(int)style
            toAttributes:(NSMutableDictionary *)attributes;
- (void)applyLowerWindowAttributes:(NSMutableDictionary *)attributes;

@end
