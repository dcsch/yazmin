/*
 *  ZMErrorAdapter.h
 *  Yazmin
 *
 *  Created by David Schweinsberg on 29/11/07.
 *  Copyright 2007 David Schweinsberg. All rights reserved.
 *
 */
#include "ZMError.h"

@class Story;

class ZMErrorAdapter : public ZMError {
public:
  ZMErrorAdapter(Story *story);

  virtual ~ZMErrorAdapter();

  virtual void error(char *message);

private:
  Story *_story;
};
