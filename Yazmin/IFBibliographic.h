//
//  IFBibliographic.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFBibliographic : NSObject
{
    NSString *title;
    NSString *author;
    NSString *language;
    NSString *headline;
    NSString *firstPublished;
    NSString *genre;
    NSString *group;
    NSString *description;
    NSString *series;
    int seriesNumber;
    NSString *forgiveness;
}

- (id)initWithXMLElement:(NSXMLElement *)element;
- (NSString *)title;
- (NSString *)author;
- (NSString *)language;
- (NSString *)headline;
- (NSString *)firstPublished;
- (NSString *)genre;
- (NSString *)group;
- (NSString *)description;
- (NSString *)series;
- (int)seriesNumber;
- (NSString *)forgiveness;

@end
