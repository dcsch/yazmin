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
{
    IFIdentification *identification;
    IFBibliographic *bibliographic;
}

- (instancetype)initWithXMLElement:(NSXMLElement *)element NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property (readonly, strong) IFIdentification *identification;
@property (readonly, strong) IFBibliographic *bibliographic;

@end
