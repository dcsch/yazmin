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

  // Decode Z-characters into UTF-8
  std::string decode(const uint8_t *data, size_t &encodedLen);

  // Encode zscii into Z-characters
  void encode(uint8_t *data, const char *zscii, size_t zsciiLen,
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
  static bool unpackWord(uint16_t word, char *zchars);

  static uint16_t packWord(const uint8_t *zchars);

  void zCharToUTF8(char z, std::string &str);

  int zsciiToZChar(char zscii, uint8_t *zchar);

  bool findInAlphabet(char zscii, int *charset, uint8_t *zchar);

  uint16_t findInExtras(wchar_t wc);

  uint16_t wcharToZscii(wchar_t wc);

  static void appendAsUTF8(std::string &str, wchar_t c);
};

#endif // ZM_TEXT_H__
