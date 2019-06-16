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

class ZMWordTable {
public:
  ZMWordTable(const uint8_t *lengthByte, const uint8_t *bytes,
              bool nativeByteOrder = false)
      : _lengthByte(lengthByte), _bytes(bytes),
        _nativeByteOrder(nativeByteOrder) {}

  ZMWordTable(const uint8_t *lengthByte, const uint16_t *words,
              bool nativeByteOrder = false)
      : _lengthByte(lengthByte),
        _bytes(reinterpret_cast<const uint8_t *>(words)),
        _nativeByteOrder(nativeByteOrder) {}

  uint8_t getLength() const { return *_lengthByte; }

  uint16_t getWord(int index) const {
    if (_nativeByteOrder)
      return reinterpret_cast<const uint16_t *>(_bytes)[index];
    else
      return static_cast<uint16_t>(_bytes[2 * index]) << 8 |
             _bytes[2 * index + 1];
  }

private:
  const uint8_t *_lengthByte;
  const uint8_t *_bytes;
  bool _nativeByteOrder;
};

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

  ZMWordTable _uTable;

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

  bool receivableChar(wchar_t wc);

  uint16_t wcharToZscii(wchar_t wc);

  size_t UTF8ToZscii(char *zscii, const std::string &str, size_t maxLen);

  static void appendAsUTF8(std::string &str, wchar_t c);
};

#endif // ZM_TEXT_H__
