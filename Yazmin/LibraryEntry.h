//
//  LibraryEntry.h
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFStory;

@interface LibraryEntry : NSObject

@property(readonly, nonnull) NSString *ifid;
@property(readonly, nonnull) NSURL *fileURL;
@property(nullable) IFStory *storyMetadata;
@property(readonly, nonnull) NSString *title;
@property(readonly, nullable) NSString *author;
@property(readonly, nullable) NSString *genre;
@property(readonly, nullable) NSString *group;
@property(readonly, nullable) NSString *firstPublished;

- (nonnull instancetype)initWithIFID:(nonnull NSString *)ifid
                                 url:(nonnull NSURL *)url
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));

@end
