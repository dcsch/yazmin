//
//  IFStory.m
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFStory.h"
#import "IFIdentification.h"
#import "IFBibliographic.h"

@implementation IFStory

- (id)initWithXMLElement:(NSXMLElement *)element
{
    self = [super init];
    if (self)
    {
        NSXMLElement *idElement = [[element elementsForName:@"identification"] objectAtIndex:0];
        identification = [[IFIdentification alloc] initWithXMLElement:idElement];

        NSXMLElement *biblioElement = [[element elementsForName:@"bibliographic"] objectAtIndex:0];
        bibliographic = [[IFBibliographic alloc] initWithXMLElement:biblioElement];
    }
    return self;
}

- (void)dealloc
{
    [identification release];
    [bibliographic release];
    [super dealloc];
}

- (IFIdentification *)identification
{
    return identification;
}

- (IFBibliographic *)bibliographic
{
    return bibliographic;
}

@end
