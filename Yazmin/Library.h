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

NS_ASSUME_NONNULL_BEGIN

@interface Library : NSObject

@property(strong, readonly) NSMutableArray<LibraryEntry *> *entries;

- (IFStory *)metadataForIFID:(NSString *)ifid;
- (nullable NSImage *)imageForIFID:(NSString *)ifid;
- (BOOL)containsStory:(Story *)story;
- (void)save;
- (void)syncMetadata;

@end

NS_ASSUME_NONNULL_END
