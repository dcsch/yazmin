//
//  IFIdentification.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface IFIdentification : NSObject

- (instancetype)initWithXMLElement:(NSXMLElement *)element
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property(readonly) NSArray<NSString *> *ifids;
@property(readonly) NSString *format;
@property(readonly) int bafn;
@property(readonly) NSString *xmlString;

@end

NS_ASSUME_NONNULL_END
