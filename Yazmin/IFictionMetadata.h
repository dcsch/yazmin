//
//  IFictionMetadata.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFictionMetadata : NSObject
{
    NSMutableArray *stories;
}

- (instancetype)initWithData:(NSData *)data NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property (readonly, copy) NSArray *stories;

@end
