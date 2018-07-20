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
{
    NSData *data;
    NSMutableArray *resources;
    NSData *metaData;
}

+ (BOOL)isBlorbData:(NSData *)data;
- (instancetype)initWithData:(NSData *)aData NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
- (BlorbResource *)findResourceOfUsage:(unsigned int)usage;
@property (readonly, copy) NSData *zcodeData;
@property (readonly, copy) NSData *pictureData;
@property (readonly, copy) NSData *metaData;

@end
