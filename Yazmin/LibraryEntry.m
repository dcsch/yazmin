//
//  LibraryEntry.m
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryEntry.h"

@implementation LibraryEntry

- (instancetype)initWithIfid:(NSString *)anIfid url:(NSURL *)aUrl
{
    self = [super init];
    if (self)
    {
        _ifid = [anIfid copy];
        _fileURL = [aUrl copy];
        
        // Create a default title of the file name
        self.title = _fileURL.path.lastPathComponent;
    }
    return self;
}

@end
