//
//  LibraryEntry.m
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryEntry.h"

@implementation LibraryEntry

- (id)initWithIfid:(NSString *)anIfid url:(NSURL *)aUrl
{
    self = [super init];
    if (self)
    {
        ifid = [anIfid copy];
        fileURL = [aUrl copy];
        
        // Create a default title of the file name
        self.title = fileURL.path.lastPathComponent;
    }
    return self;
}


@synthesize ifid;
@synthesize fileURL;
@synthesize title;
@synthesize author;

@end
