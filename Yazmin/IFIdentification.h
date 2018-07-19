//
//  IFIdentification.h
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFIdentification : NSObject
{
    NSMutableArray *ifids;
    NSString *format;
    int bafn;
}

- (instancetype)initWithXMLElement:(NSXMLElement *)element NS_DESIGNATED_INITIALIZER;
@property (readonly, copy) NSArray *ifids;
@property (readonly, copy) NSString *format;
@property (readonly) int bafn;

@end
