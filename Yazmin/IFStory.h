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

@interface IFStory : NSObject

- (nonnull instancetype)initWithXMLElement:(nonnull NSXMLElement *)element
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));
@property(readonly, nonnull) IFIdentification *identification;
@property(readonly, nonnull) IFBibliographic *bibliographic;

@end
