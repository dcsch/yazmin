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

#include <stdint.h>
#include <stdlib.h>

class ZMText {
public:
  ZMText(uint8_t *memoryBase);

  int decode(const uint8_t *data, char *ascii, size_t maxLen,
             size_t *encodedLen = 0);

  void encode(uint8_t *data, const char *ascii, size_t asciiLen,
              size_t encodedLen);

  int abbreviation(int index, char *ascii, size_t maxLen);

  size_t getEncodedLength(uint32_t addr);

  size_t getDecodedLength(uint32_t addr);

  size_t getString(uint32_t addr, char *ascii, size_t maxLen);

private:
  uint8_t *_memoryBase;

  const char *_a0;

  const char *_a1;

  const char *_a2;

  const char *_charset;

  int _abbreviation;

  int _10bit;

  char _highBits;

  static bool unpackWord(uint16_t word, char *bytes);

  static uint16_t packWord(const uint8_t *bytes);

  int zsciiToAscii(char z, char *ascii, size_t maxLen);

  int asciiToZscii(char ascii, uint8_t *zscii);

  bool findInAlphabet(char ascii, int *charset, uint8_t *zscii);
};

#endif // ZM_TEXT_H__
