//
//  Blorb.h
//  Yazmin
//
//  Created by David Schweinsberg on 21/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BlorbResource;

@interface Blorb : NSObject

@property(readonly, nullable) NSData *zcodeData;
@property(readonly, nullable) NSData *pictureData;
@property(readonly, nullable) NSData *metaData;

+ (BOOL)isBlorbURL:(nonnull NSURL *)url;
+ (BOOL)isBlorbData:(nonnull NSData *)data;
- (nonnull instancetype)initWithData:(nonnull NSData *)data
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));

@end
