//
//  IFBibliographic.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IFBibliographic : NSObject

- (nonnull instancetype)initWithXMLElement:(nonnull NSXMLElement *)element
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));
@property(readonly, nullable) NSString *title;
@property(readonly, nullable) NSString *author;
@property(readonly, nullable) NSString *language;
@property(readonly, nullable) NSString *headline;
@property(readonly, nullable) NSString *firstPublished;
@property(readonly, nullable) NSString *genre;
@property(readonly, nullable) NSString *group;
@property(readonly, nullable) NSString *storyDescription;
@property(readonly, nullable) NSString *series;
@property(readonly) int seriesNumber;
@property(readonly, nullable) NSString *forgiveness;

@end
