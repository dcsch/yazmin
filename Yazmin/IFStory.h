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

NS_ASSUME_NONNULL_BEGIN

@interface IFStory : NSObject

@property(readonly) IFIdentification *identification;
@property(readonly) IFBibliographic *bibliographic;

- (instancetype)initWithXMLElement:(NSXMLElement *)element
    NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end

NS_ASSUME_NONNULL_END
