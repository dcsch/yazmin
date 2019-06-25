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

  void error(const std::string &message) override;

private:
  Story *_story;
};
