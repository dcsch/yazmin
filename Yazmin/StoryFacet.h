//
//  StoryFacet.h
//  Yazmin
//
//  Created by David Schweinsberg on 3/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Story;

@interface StoryFacet : NSObject

@property Story *story;
@property NSTextStorage *textStorage;
@property(readonly) int line;
@property(readonly) int column;
@property int fontID;
@property int numberOfLines;
@property int widthInCharacters;
@property int heightInLines;

- (instancetype)initWithStory:(Story *)story NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

- (NSFont *)fontForStyle:(int)style;

- (void)erase;
- (void)eraseLine;
- (void)setCursorLine:(int)line column:(int)column;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)applyColorsOfStyle:(int)style
              toAttributes:(NSMutableDictionary *)attributes;
- (void)applyFontOfStyle:(int)style
            toAttributes:(NSMutableDictionary *)attributes;
- (void)applyLowerWindowAttributes:(NSMutableDictionary *)attributes;
- (void)updateFontPreferences;

@end

NS_ASSUME_NONNULL_END
