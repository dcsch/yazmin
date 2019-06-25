/*
 *  ZMErrorAdapter.mm
 *  Yazmin
 *
 *  Created by David Schweinsberg on 29/11/07.
 *  Copyright 2007 David Schweinsberg. All rights reserved.
 *
 */

#import "ZMErrorAdapter.h"
#import "Story.h"

ZMErrorAdapter::ZMErrorAdapter(Story *story) : _story(story) {}

void ZMErrorAdapter::error(const std::string &message) {
  [_story error:[NSString stringWithCString:message.c_str()
                                   encoding:NSString.defaultCStringEncoding]];
}
