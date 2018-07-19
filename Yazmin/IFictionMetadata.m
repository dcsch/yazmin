//
//  IFictionMetadata.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFictionMetadata.h"
#import "IFStory.h"

@implementation IFictionMetadata

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        stories = [[NSMutableArray alloc] init];

        NSError *error;
        NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:data
                                                         options:0
                                                           error:&error];
        NSEnumerator *enumerator = [[[xml rootElement] elementsForName:@"story"] objectEnumerator];
        NSXMLElement *child;
        while ((child = [enumerator nextObject]))
        {
            IFStory *story = [[IFStory alloc] initWithXMLElement:child];
            [stories addObject:story];
        }
    }
    return self;
}


- (NSArray *)stories
{
    return stories;
}

@end
