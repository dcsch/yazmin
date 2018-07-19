//
//  IFBibliographic.m
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFBibliographic.h"


@implementation IFBibliographic

- (instancetype)initWithXMLElement:(NSXMLElement *)element
{
    self = [super init];
    if (self)
    {
        NSEnumerator *enumChildren = [element.children objectEnumerator];
        NSXMLNode *node;
        while ((node = [enumChildren nextObject]))
        {
            if ([node.name compare:@"title"] == 0)
            {
                title = node.stringValue;
            }
            else if ([node.name compare:@"author"] == 0)
            {
                author = node.stringValue;
            }
            else if ([node.name compare:@"language"] == 0)
            {
                language = node.stringValue;
            }
            else if ([node.name compare:@"headline"] == 0)
            {
                headline = node.stringValue;
            }
            else if ([node.name compare:@"firstpublished"] == 0)
            {
                firstPublished = node.stringValue;
            }
            else if ([node.name compare:@"genre"] == 0)
            {
                genre = node.stringValue;
            }
            else if ([node.name compare:@"group"] == 0)
            {
                group = node.stringValue;
            }
            else if ([node.name compare:@"description"] == 0)
            {
                description = node.stringValue;
            }
            else if ([node.name compare:@"series"] == 0)
            {
                series = node.stringValue;
            }
            else if ([node.name compare:@"seriesnumber"] == 0)
            {
                seriesNumber = node.stringValue.intValue;
            }
            else if ([node.name compare:@"forgiveness"] == 0)
            {
                forgiveness = node.stringValue;
            }
        }
    }
    return self;
}


- (NSString *)title
{
    return title;
}

- (NSString *)author
{
    return author;
}

- (NSString *)language
{
    return language;
}

- (NSString *)headline
{
    return headline;
}

- (NSString *)firstPublished
{
    return firstPublished;
}

- (NSString *)genre
{
    return genre;
}

- (NSString *)group
{
    return group;
}

- (NSString *)description
{
    return description;
}

- (NSString *)series
{
    return series;
}

- (int)seriesNumber
{
    return seriesNumber;
}

- (NSString *)forgiveness
{
    return forgiveness;
}

@end
