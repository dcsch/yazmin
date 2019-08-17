//
//  LibraryEntry.h
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFStory;

NS_ASSUME_NONNULL_BEGIN

@interface LibraryEntry : NSObject

@property(readonly) NSString *ifid;
@property(readonly) NSURL *fileURL;
@property(readonly) IFStory *storyMetadata;
@property(readonly) NSString *title;
@property(readonly, nullable) NSString *author;
@property(readonly, nullable) NSString *genre;
@property(readonly, nullable) NSString *group;
@property(readonly, nullable) NSString *firstPublished;

- (instancetype)initWithIFID:(NSString *)ifid
                         url:(NSURL *)url
               storyMetadata:(IFStory *)storyMetadata NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end

NS_ASSUME_NONNULL_END
