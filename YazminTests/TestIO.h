//
//  TestIO.h
//  YazminTests
//
//  Created by David Schweinsberg on 8/22/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMIO.h"

@class Story;

class TestIO : public ZMIO {
public:
  TestIO();

  int getScreenWidth() const override;

  int getScreenHeight() const override;

  int getWindow() const override;

  void setWindow(int window) override;

  void splitWindow(int lines) override;

  void eraseWindow(int window) override;

  void eraseLine() override;

  void showStatus() override;

  void inputStream(int stream) override;

  void outputStream(int stream) override;

  void getColor(int &foreground, int &background) const override;

  void setColor(int foreground, int background) override;

  void getTrueColor(int &foreground, int &background) const override;

  void setTrueColor(int foreground, int background) override;

  void getCursor(int &line, int &column) const override;

  void setCursor(int line, int column) override;

  int setFont(int font) override;

  void setTextStyle(int style) override;

  bool checkUnicode(uint16_t uc) override;

  void print(const std::string &str) override;

  void printNumber(int number) override;

  void newLine() override;

  void setWordWrap(bool wordWrap) override;

  void beginInput(uint8_t existingLen) override;

  std::string endInput() override;

  void beginInputChar() override;

  wchar_t endInputChar() override;

  void soundEffect(int number, int effect, int repeat, int volume) override;

  void startTimedRoutine(int time, int routine) override;

  void stopTimedRoutine() override;

  void beginRestore() const override;

  uint16_t endRestore(const uint8_t **data, size_t *length) const override;

  void save(const uint8_t *data, size_t length) const override;

  uint16_t getRestoreOrSaveResult() override;

  int getInterpreterNumber() const override;

  char getInterpreterVersion() const override;
};
