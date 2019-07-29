//
//  LibraryViewController.h
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;
@class LibraryEntry;
@class Story;

NS_ASSUME_NONNULL_BEGIN

@interface LibraryViewController : NSViewController

@property Library *library;
@property(readonly) NSPredicate *filterPredicate;
@property(readonly) NSArray<LibraryEntry *> *sortedEntries;

- (void)addStory:(Story *)story;
- (void)openStory:(LibraryEntry *)libraryEntry;

@end

NS_ASSUME_NONNULL_END
