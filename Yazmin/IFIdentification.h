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

- (id)initWithXMLElement:(NSXMLElement *)element;
- (NSArray *)ifids;
- (NSString *)format;
- (int)bafn;

@end
