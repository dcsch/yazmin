//
//  IFBibliographic.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface IFBibliographic : NSObject

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

- (instancetype)initWithXMLElement:(NSXMLElement *)element NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end

NS_ASSUME_NONNULL_END
