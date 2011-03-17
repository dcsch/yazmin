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

- (id)initWithData:(NSData *)data;
- (NSArray *)stories;

@end
