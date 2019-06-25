/*
 *  ZMError.h
 *  Yazmin
 *
 *  Created by David Schweinsberg on 29/11/07.
 *  Copyright 2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_ERROR_H__
#define ZM_ERROR_H__

#include <string>

class ZMError {
public:
  virtual ~ZMError() = default;

  virtual void error(const std::string &message) = 0;
};

#endif // ZM_ERROR_H__
