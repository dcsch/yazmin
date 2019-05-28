//
//  Library.h
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Story;
@class LibraryEntry;

@interface Library : NSObject

@property(strong, readonly) NSMutableArray<LibraryEntry *> *entries;

- (BOOL)containsStory:(Story *)story;
- (void)save;

@end
