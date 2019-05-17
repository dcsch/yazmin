//
//  BlorbResource.h
//  Yazmin
//
//  Created by David Schweinsberg on 21/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ExecutableResource 0x45786563
#define PictureResource 0x50696374

@interface BlorbResource : NSObject {
  unsigned int usage;
  unsigned int number;
  unsigned int start;
}

- (instancetype)initWithUsage:(unsigned int)aUsage
                       number:(unsigned int)aNumber
                        start:(unsigned int)aStart NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property(readonly) unsigned int usage;
@property(readonly) unsigned int number;
@property(readonly) unsigned int start;

@end
