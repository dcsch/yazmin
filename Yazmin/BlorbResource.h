//
//  BlorbResource.h
//  Yazmin
//
//  Created by David Schweinsberg on 21/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ExecutableResource 0x45786563
#define PictureResource    0x50696374

@interface BlorbResource : NSObject
{
    unsigned int usage;
    unsigned int number;
    unsigned int start;
}

- (id)initWithUsage:(unsigned int)aUsage
             number:(unsigned int)aNumber
              start:(unsigned int)aStart;
- (unsigned int)usage;
- (unsigned int)number;
- (unsigned int)start;

@end
