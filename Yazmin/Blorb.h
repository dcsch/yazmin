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
- (id)initWithData:(NSData *)aData;
- (BlorbResource *)findResourceOfUsage:(unsigned int)usage;
- (NSData *)zcodeData;
- (NSData *)pictureData;
- (NSData *)metaData;

@end
