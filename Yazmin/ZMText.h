/*
 *  ZMText.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 18/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_TEXT_H__
#define ZM_TEXT_H__

#include <cstdint>
#include <cstdlib>
#include <string>

class ZMText {
public:
  ZMText(uint8_t *memoryBase);

  std::string decode(const uint8_t *data, size_t &encodedLen);

  void encode(uint8_t *data, const char *ascii, size_t asciiLen,
              size_t encodedLen);

  std::string abbreviation(int index);

  std::string getString(uint32_t addr, size_t &encodedLen);

  std::string getString(uint32_t addr);

private:
  uint8_t *_memoryBase;

  const char *_a0;

  const char *_a1;

  const char *_a2;

  const char *_charset;

  int _abbreviation;

  int _10bit;

  char _highBits;

public:
  static bool unpackWord(uint16_t word, char *bytes);

  static uint16_t packWord(const uint8_t *bytes);

  void zsciiToUTF8(char z, std::string &str);

  int asciiToZscii(char ascii, uint8_t *zscii);

  bool findInAlphabet(char ascii, int *charset, uint8_t *zscii);

  static void appendAsUTF8(std::string &str, wchar_t c);
};

#endif // ZM_TEXT_H__
