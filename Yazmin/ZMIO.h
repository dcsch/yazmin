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

#include <cstdint>
#include <cstdlib>
#include <string>

class ZMIO {
public:
  virtual ~ZMIO() = default;

  virtual int getScreenWidth() const = 0;

  virtual int getScreenHeight() const = 0;

  virtual void setWindow(int window) = 0;

  virtual void splitWindow(int lines) = 0;

  virtual void eraseWindow(int window) = 0;

  virtual void showStatus() = 0;

  virtual void outputStream(int stream) = 0;

  virtual void getColor(int &foreground, int &background) const = 0;

  virtual void setColor(int foreground, int background) = 0;

  virtual void getTrueColor(int &foreground, int &background) const = 0;

  virtual void setTrueColor(int foreground, int background) = 0;

  virtual void getCursor(int &line, int &column) const = 0;

  virtual void setCursor(int line, int column) = 0;

  virtual int setFont(int font) = 0;

  virtual void setTextStyle(int style) = 0;

  virtual bool checkUnicode(uint16_t uc) = 0;

  virtual void print(const std::string &str) = 0;

  virtual void printNumber(int number) = 0;

  virtual void newLine() = 0;

  virtual void setWordWrap(bool wordWrap) = 0;

  virtual void beginInput(uint8_t existingLen) = 0;

  virtual std::string endInput() = 0;

  virtual void beginInputChar() = 0;

  virtual wchar_t endInputChar() = 0;

  virtual void soundEffect(int number, int effect, int repeat, int volume) = 0;

  virtual void startTimedRoutine(int time, int routine) = 0;

  virtual void stopTimedRoutine() = 0;

  virtual void beginRestore() const = 0;

  virtual uint16_t endRestore(const uint8_t **data, size_t *length) const = 0;

  virtual void save(const uint8_t *data, size_t length) const = 0;

  virtual uint16_t getRestoreOrSaveResult() = 0;
};

#endif // ZM_IO_H__
