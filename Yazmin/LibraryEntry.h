//
//  LibraryEntry.h
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LibraryEntry : NSObject
{
    NSString *ifid;
    NSURL *fileURL;
    NSString *title;
    NSString *author;
}

@property(copy, readonly) NSString *ifid;
@property(copy, readonly) NSURL *fileURL;
@property(copy) NSString *title;
@property(copy) NSString *author;

- (instancetype)initWithIfid:(NSString *)anIfid url:(NSURL *)aUrl NS_DESIGNATED_INITIALIZER;

@end
