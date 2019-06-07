/*
 *  ZMIO.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 19/12/06.
 *  Copyright 2006 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_IO_H__
#define ZM_IO_H__

#include <stdint.h>
#include <stdlib.h>

class ZMIO {
public:
  virtual ~ZMIO() {}

  virtual void setWindow(int window) = 0;

  virtual void splitWindow(int lines) = 0;

  virtual void eraseWindow(int window) = 0;

  virtual void showStatus() = 0;

  virtual void outputStream(int stream) = 0;

  virtual void setColor(int foreground, int background) = 0;

  virtual void setCursor(int line, int column) = 0;

  virtual int setFont(int font) = 0;

  virtual void setTextStyle(int style) = 0;

  virtual void print(const char *str) = 0;

  virtual void printNumber(int number) = 0;

  virtual void newLine() = 0;

  virtual void setWordWrap(bool wordWrap) = 0;

  virtual void beginInput() = 0;

  virtual size_t endInput(char *str, size_t maxLen) = 0;

  virtual void beginInputChar() = 0;

  virtual char endInputChar() = 0;

  virtual void startTimedRoutine(int time, int routine) = 0;

  virtual void stopTimedRoutine() = 0;

  virtual void beginRestore() const = 0;

  virtual uint16_t endRestore(const uint8_t **data, size_t *length) const = 0;

  virtual void save(const uint8_t *data, size_t length) const = 0;

  virtual uint16_t getRestoreOrSaveResult() = 0;
};

#endif // ZM_IO_H__
