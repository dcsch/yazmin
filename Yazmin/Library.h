//
//  Library.h
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Story;

@interface Library : NSObject
{
    NSMutableArray *entries;
}

@property(retain, readonly) NSMutableArray *entries;

- (void)addStory:(Story *)story;
- (void)save;

@end
