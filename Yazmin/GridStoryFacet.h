//
//  GridStoryFacet.h
//  Yazmin
//
//  Created by David Schweinsberg on 5/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryFacet.h"

@interface GridStoryFacet : StoryFacet

- (instancetype)initWithStory:(Story *)aStory;

@property(readonly) int line;
@property(readonly) int column;
@property int numberOfLines;

- (void)erase;
- (void)setCursorLine:(int)line column:(int)column;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)eraseFromLine:(int)line;

@end
