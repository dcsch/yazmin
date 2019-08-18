//
//  IFStory.h
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFIdentification;
@class IFBibliographic;
@class IFColophon;

NS_ASSUME_NONNULL_BEGIN

@interface IFStory : NSObject

@property(readonly) IFIdentification *identification;
@property(readonly) IFBibliographic *bibliographic;
@property(readonly, nullable) IFColophon *colophon;
@property(readonly) NSString *xmlString;

- (instancetype)initWithXMLElement:(NSXMLElement *)element;
- (instancetype)initWithIFID:(NSString *)ifid;
- (void)updateFromStory:(IFStory *)story;

@end

NS_ASSUME_NONNULL_END
