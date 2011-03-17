//
//  IFBibliographic.m
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFBibliographic.h"


@implementation IFBibliographic

- (id)initWithXMLElement:(NSXMLElement *)element
{
    self = [super init];
    if (self)
    {
        NSEnumerator *enumChildren = [[element children] objectEnumerator];
        NSXMLNode *node;
        while ((node = [enumChildren nextObject]))
        {
            if ([[node name] compare:@"title"] == 0)
            {
                title = [node stringValue];
                [title retain];
            }
            else if ([[node name] compare:@"author"] == 0)
            {
                author = [node stringValue];
                [author retain];
            }
            else if ([[node name] compare:@"language"] == 0)
            {
                language = [node stringValue];
                [language retain];
            }
            else if ([[node name] compare:@"headline"] == 0)
            {
                headline = [node stringValue];
                [headline retain];
            }
            else if ([[node name] compare:@"firstpublished"] == 0)
            {
                firstPublished = [node stringValue];
                [firstPublished retain];
            }
            else if ([[node name] compare:@"genre"] == 0)
            {
                genre = [node stringValue];
                [genre retain];
            }
            else if ([[node name] compare:@"group"] == 0)
            {
                group = [node stringValue];
                [group retain];
            }
            else if ([[node name] compare:@"description"] == 0)
            {
                description = [node stringValue];
                [description retain];
            }
            else if ([[node name] compare:@"series"] == 0)
            {
                series = [node stringValue];
                [series retain];
            }
            else if ([[node name] compare:@"seriesnumber"] == 0)
            {
                seriesNumber = [[node stringValue] intValue];
            }
            else if ([[node name] compare:@"forgiveness"] == 0)
            {
                forgiveness = [node stringValue];
                [forgiveness retain];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
