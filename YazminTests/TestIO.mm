//
//  TestIO.m
//  YazminTests
//
//  Created by David Schweinsberg on 8/22/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "TestIO.h"

TestIO::TestIO() {}

int TestIO::getScreenWidth() const { return 80; }

int TestIO::getScreenHeight() const { return 25; }

void TestIO::setWindow(int window) {}

void TestIO::splitWindow(int lines) {}

void TestIO::eraseWindow(int window) {}

void TestIO::eraseLine() {}

void TestIO::showStatus() {}

void TestIO::inputStream(int stream) {}

void TestIO::outputStream(int stream) {}

void TestIO::getColor(int &foreground, int &background) const {
  foreground = 0;
  background = 0;
}

void TestIO::setColor(int foreground, int background) {}

void TestIO::getTrueColor(int &foreground, int &background) const {
  foreground = 0;
  background = 0;
}

void TestIO::setTrueColor(int foreground, int background) {}

void TestIO::getCursor(int &line, int &column) const {
  line = 0;
  column = 0;
}

void TestIO::setCursor(int line, int column) {}

int TestIO::setFont(int font) { return 0; }

void TestIO::setTextStyle(int style) {}

bool TestIO::checkUnicode(uint16_t uc) { return true; }

void TestIO::print(const std::string &str) {}

void TestIO::printNumber(int number) {}

void TestIO::newLine() {}

void TestIO::setWordWrap(bool wordWrap) {}

void TestIO::beginInput(uint8_t existingLen) {}

std::string TestIO::endInput() { return ""; }

void TestIO::beginInputChar() {}

wchar_t TestIO::endInputChar() { return 0; }

void TestIO::soundEffect(int number, int effect, int repeat, int volume) {}

void TestIO::startTimedRoutine(int time, int routine) {}

void TestIO::stopTimedRoutine() {}

void TestIO::beginRestore() const {}

uint16_t TestIO::endRestore(const uint8_t **data, size_t *length) const {

  return 0;
}

void TestIO::save(const uint8_t *data, size_t length) const {}

uint16_t TestIO::getRestoreOrSaveResult() { return 0; }

int TestIO::getInterpreterNumber() const { return 3; }

char TestIO::getInterpreterVersion() const { return 'Z'; }
