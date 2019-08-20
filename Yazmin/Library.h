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

- (nullable IFStory *)metadataForIFID:(NSString *)ifid;
- (nullable IFStory *)defaultMetadataForIFID:(NSString *)ifid;
- (nullable NSImage *)imageForIFID:(NSString *)ifid;
- (void)fetchImageForIFID:(NSString *)ifid URL:(NSURL *)url;
- (BOOL)containsStory:(Story *)story;
- (void)save;

@end

NS_ASSUME_NONNULL_END
