//
//  IFictionMetadata.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFStory;

@interface IFictionMetadata : NSObject

- (nonnull instancetype)initWithData:(nonnull NSData *)data
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));
@property(readonly, nonnull) NSArray<IFStory *> *stories;

- (nullable IFStory *)storyWithIFID:(nonnull NSString *)ifid;

@end
