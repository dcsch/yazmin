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
@class IFStory;

@interface Library : NSObject

@property(strong, readonly) NSMutableArray<LibraryEntry *> *entries;

- (IFStory *)metadataForIFID:(NSString *)ifid;
- (BOOL)containsStory:(Story *)story;
- (void)save;
- (void)syncMetadata;

@end
