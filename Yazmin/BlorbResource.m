//
//  BlorbResource.m
//  Yazmin
//
//  Created by David Schweinsberg on 21/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "BlorbResource.h"

@implementation BlorbResource

- (id)initWithUsage:(unsigned int)aUsage
             number:(unsigned int)aNumber
              start:(unsigned int)aStart
{
    self = [super init];
    if (self)
    {
        usage = aUsage;
        number = aNumber;
        start = aStart;
    }
    return self;
}

- (unsigned int)usage
{
    return usage;
}

- (unsigned int)number
{
    return number;
}

- (unsigned int)start
{
    return start;
}

@end
