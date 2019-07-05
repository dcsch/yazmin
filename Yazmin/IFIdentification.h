//
//  IFIdentification.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IFIdentification : NSObject

- (nonnull instancetype)initWithXMLElement:(nonnull NSXMLElement *)element
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init __attribute__((unavailable));
@property(readonly, nonnull) NSArray<NSString *> *ifids;
@property(readonly, nonnull) NSString *format;
@property(readonly) int bafn;

@end
