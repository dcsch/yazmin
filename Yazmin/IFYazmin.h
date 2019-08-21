//
//  IFYazmin.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/20/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IFYazmin : NSObject

@property NSURL *story;
@property(nullable) NSURL *graphics;
@property(nullable) NSURL *sound;
@property(readonly) NSString *xmlString;

- (instancetype)initWithXMLElement:(NSXMLElement *)element;

@end

NS_ASSUME_NONNULL_END
