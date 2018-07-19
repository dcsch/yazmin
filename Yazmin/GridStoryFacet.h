//
//  GridStoryFacet.h
//  Yazmin
//
//  Created by David Schweinsberg on 5/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryFacet.h"

@interface GridStoryFacet : StoryFacet
{
    int numberOfLines;
    int numberOfColumns;
    int resizeToNumberOfColumns;
    int x;
    int y;
}

- (instancetype)initWithStory:(Story *)aStory columns:(int)columns NS_DESIGNATED_INITIALIZER;
@property  int numberOfLines;
@property  int numberOfColumns;
- (void)setCursorLine:(int)line column:(int)column;
- (void)setTextStyle:(int)style;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;

@end
