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

- (instancetype)initWithXMLElement:(NSXMLElement *)element NS_DESIGNATED_INITIALIZER;
@property (readonly, copy) NSString *title;
@property (readonly, copy) NSString *author;
@property (readonly, copy) NSString *language;
@property (readonly, copy) NSString *headline;
@property (readonly, copy) NSString *firstPublished;
@property (readonly, copy) NSString *genre;
@property (readonly, copy) NSString *group;
@property (readonly, copy) NSString *description;
@property (readonly, copy) NSString *series;
@property (readonly) int seriesNumber;
@property (readonly, copy) NSString *forgiveness;

@end
