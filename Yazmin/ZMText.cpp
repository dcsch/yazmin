/*
 *  ZMText.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 18/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMText.h"
#include "ZMMemory.h"

static const char defaultA0[] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                                 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                                 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};

static const char defaultA1[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                                 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                                 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};

static const char defaultA2[] = {' ',  '^', '0', '1',  '2', '3', '4', '5', '6',
                                 '7',  '8', '9', '.',  ',', '!', '?', '_', '#',
                                 '\'', '"', '/', '\\', '-', ':', '(', ')'};

// Unicode translations from 155 to 223
static const uint8_t defaultULength = 69;
static const uint16_t defaultU[] = {
    L'ä', L'ö', L'ü', L'Ä', L'Ö', L'Ü', L'ß', L'»', L'«', L'ë', L'ï', L'ÿ',
    L'Ë', L'Ï', L'á', L'é', L'í', L'ó', L'ú', L'ý', L'Á', L'É', L'Í', L'Ó',
    L'Ú', L'Ý', L'à', L'è', L'ì', L'ò', L'ù', L'À', L'È', L'Ì', L'Ò', L'Ù',
    L'â', L'ê', L'î', L'ô', L'û', L'Â', L'Ê', L'Î', L'Ô', L'Û', L'å', L'Å',
    L'ø', L'Ø', L'ã', L'ñ', L'õ', L'Ã', L'Ñ', L'Õ', L'æ', L'Æ', L'ç', L'Ç',
    L'þ', L'ð', L'Þ', L'Ð', L'£', L'œ', L'Œ', L'¡', L'¿'};

ZMText::ZMText(uint8_t *memoryBase)
    : _memoryBase(memoryBase), _a0(defaultA0), _a1(defaultA1), _a2(defaultA2),
      _uTable(&defaultULength, defaultU, true), _charset(_a0), _abbreviation(0),
      _10bit(0), _highBits(0) {
  // Are we to use an alphabet table from memory?
  ZMHeader header(_memoryBase);
  uint16_t addr = header.getAlphabetTableAddress();
  if (addr) {
    _a0 = reinterpret_cast<char *>(_memoryBase + addr);
    _a1 = _a0 + 26;
    _a2 = _a1 + 26;
    _charset = _a0;
  }
  addr = header.getUnicodeTranslationTableAddress();
  if (addr)
    _uTable = ZMWordTable(_memoryBase + addr, _memoryBase + addr + 1);
}

std::string ZMText::decode(const uint8_t *data, size_t &encodedLen) {
  std::string str;
  const uint8_t *ptr = data;
  char zchars[3];
  bool eol = false;
  while (!eol) {
    eol = unpackWord(ZMMemory::readWordFromData(ptr), zchars);
    ptr += 2;
    for (int i = 0; i < 3; ++i) {
      zCharToUTF8(zchars[i], str);
    }
  }
  encodedLen = ptr - data;
  return str;
}

void ZMText::encode(uint8_t *data, const char *zscii, size_t zsciiLen,
                    size_t encodedLen) {
  uint8_t zchars[256];
  uint8_t *zcharsPtr = zchars;
  int zcharLen;
  const char *zsciiPtr = zscii;
  for (size_t i = 0; i < zsciiLen; ++i) {
    zcharLen = zsciiToZChar(*zsciiPtr, zcharsPtr);
    ++zsciiPtr;
    zcharsPtr += zcharLen;
  }
  zcharLen = (int)(zcharsPtr - zchars);

  //    // Pad the buffer out to a multiple of three with 5s
  //    int modLen = zcharLen % 3;
  //    if (modLen > 0)
  //        for (int i = 0; i < modLen; ++i)
  //            *zcharsPtr++ = 5;
  //    zcharLen += modLen;

  // Pad the buffer so the length will pack down to the specified
  // encoded length (this assumes that the unpacked length is divisable
  // by three)
  int paddingLen = (int)(encodedLen * 3 / 2) - zcharLen;
  for (int i = 0; i < paddingLen; ++i)
    *zcharsPtr++ = 5;
  zcharLen += paddingLen;

  uint8_t *dataPtr = data;
  for (int i = 0; i < zcharLen; i += 3) {
    uint16_t word = packWord(zchars + i);

    // Set the high bit of the last word to 1, thus terminating the string
    if (i == zcharLen - 3)
      word |= 0x8000;

    ZMMemory::writeWordToData(dataPtr, word);
    dataPtr += 2;
  }
}

std::string ZMText::abbreviation(int index) {
  ZMHeader header(_memoryBase);
  uint16_t addr = header.getAbbreviationsTableLocation() + 2 * index;

  // The abbreviations table uses word addresses, so we must multiply the
  // address by 2
  uint16_t ptr = 2 * ZMMemory::readWordFromData(_memoryBase + addr);
  size_t encLen;
  auto str = decode(_memoryBase + ptr, encLen);

  // 0x05s padding out the end of an abbreviation can leave the charset
  // set incorrectly
  _charset = _a0;

  return str;
}

std::string ZMText::getString(uint32_t addr, size_t &encLen) {
  return decode(_memoryBase + addr, encLen);
}

std::string ZMText::getString(uint32_t addr) {
  size_t encLen;
  return decode(_memoryBase + addr, encLen);
}

bool ZMText::unpackWord(uint16_t word, char *zchars) {
  zchars[0] = static_cast<char>((word >> 10) & 0x1f);
  zchars[1] = static_cast<char>((word >> 5) & 0x1f);
  zchars[2] = static_cast<char>(word & 0x1f);
  return (word & 0x8000) ? true : false;
}

uint16_t ZMText::packWord(const uint8_t *zchars) {
  return ((zchars[0] & 0x1f) << 10) | ((zchars[1] & 0x1f) << 5) |
         (zchars[2] & 0x1f);
}

void ZMText::zCharToUTF8(char z, std::string &str) {
  if (_10bit > 0) {
    if (_10bit == 2) {
      _highBits = z & 0x1f;
      _10bit = 1;
    } else {
      int index = static_cast<int>(_highBits) << 5 | z;
      wchar_t c;
      if (155 <= index && index < 155 + _uTable.getLength())
        c = _uTable.getWord(index - 155);
      else
        c = index;
      appendAsUTF8(str, c);
      _10bit = 0;
    }
  } else if (_abbreviation != 0) {
    int n = _abbreviation;
    _abbreviation = 0;
    str.append(abbreviation(((n - 1) << 5) + z));
  } else if (z > 5) {
    if (z == 6 && _charset == _a2) {
      _10bit = 2;
      _charset = _a0;
      return;
    }
    uint8_t index = _charset[static_cast<int>(z) - 6];
    wchar_t c;
    if (155 <= index && index < 155 + _uTable.getLength())
      c = _uTable.getWord(index - 155);
    else
      c = index;
    appendAsUTF8(str, c);
    _charset = _a0;
  } else if (z == 0)
    str.append(1, ' ');
  else if (z == 4) {
    _charset = _a1;
  } else if (z == 5) {
    _charset = _a2;
  } else {
    _abbreviation = z;
  }
}

bool ZMText::findInAlphabet(char zscii, int *charset, uint8_t *zchar) {
  const char *an[] = {_a0, _a1, _a2};
  for (int set = 0; set < 3; ++set) {
    // Scan for the character
    for (uint8_t i = 0; i < 26; ++i)
      if (an[set][i] == zscii) {
        *charset = set;
        *zchar = i + 6;
        return true;
      }
  }
  return false;
}

int ZMText::zsciiToZChar(char zscii, uint8_t *zchar) {
  // If the ascii char is in any of the three (A0, A1, A2) 5-bit charsets,
  // encode into 5 bits
  int set;
  uint8_t z;
  if (zscii == 32) // space
  {
    zchar[0] = 0;
    return 1;
  } else if (findInAlphabet(zscii, &set, &z)) {
    if (set == 0) {
      zchar[0] = z;
      return 1;
    } else if (set == 1) {
      zchar[0] = 4;
      zchar[1] = z;
      return 2;
    } else if (set == 2) {
      zchar[0] = 5;
      zchar[1] = z;
      return 2;
    }
    return 0;
  } else {
    // We need to encode the char as a 10-bit value
    zchar[0] = 5;
    zchar[1] = 6;
    zchar[2] = (zscii >> 5) & 0x1f;
    zchar[3] = zscii & 0x1f;
    return 4;
  }
}

uint16_t ZMText::findInExtras(wchar_t wc) {
  // Scan for the character in the unicode translation table
  for (int i = 0; i < _uTable.getLength(); ++i)
    if (_uTable.getWord(i) == wc)
      return i + 155;
  return 0;
}

bool ZMText::receivableChar(wchar_t wc) {
  int charset;
  uint8_t zchar;
  if (wc < 256 && findInAlphabet(wc, &charset, &zchar))
    return true;
  else if (findInExtras(wc))
    return true;
  return false;
}

uint16_t ZMText::wcharToZscii(wchar_t wc) {
  if (32 <= wc && wc <= 126) // (3.8.3)
    return wc;
  uint16_t zscii = findInExtras(wc); // (3.8.5)
  if (zscii)
    return zscii;
  return '?';
}

size_t ZMText::UTF8ToZscii(char *zscii, const std::string &str, size_t maxLen) {
  char *zsciiPtr = zscii;
  int len = 0;
  wchar_t wc;
  for (uint8_t c : str) {
    if ((c & 0x80) == 0) { // stand-alone char
      *zsciiPtr++ = wcharToZscii(c);
    } else if ((c & 0xc0) == 0xc0) { // first byte in sequence
      len = ((c >> 6) & 1) + ((c >> 5) & 1) + ((c >> 4) & 1);
      uint8_t mask = 0xc0 | (len >= 2 ? 0x20 : 0) | (len >= 3 ? 0x10 : 0);
      wc = static_cast<wchar_t>(c & ~mask) << (6 * len);
    } else if (((c & 0x80) == 0x80) && len > 0) { // next byte in sequence
      len--;
      wc |= static_cast<wchar_t>(c & 0x7f) << (6 * len);
      if (len == 0)
        *zsciiPtr++ = wcharToZscii(wc);
    }

    if (zsciiPtr - zscii >= maxLen)
      break;
  }
  return zsciiPtr - zscii;
}

std::string ZMText::zsciiToUTF8(uint16_t zsciiChar) {
  std::string str;
  if (32 <= zsciiChar && zsciiChar <= 126)
    appendAsUTF8(str, zsciiChar);
  else if (155 <= zsciiChar && zsciiChar < 155 + _uTable.getLength())
    appendAsUTF8(str, _uTable.getWord(zsciiChar - 155));
  return str;
}

void ZMText::appendAsUTF8(std::string &str, wchar_t c) {
  if (c < 0x80)
    str.append(1, static_cast<char>(c));
  else if (c < 0x800) {
    char enc[] = {
        static_cast<char>(0b11000000 | c >> 6),
        static_cast<char>(0b10000000 | (c & 0b00111111)),
    };
    str.append(enc, 2);
  } else if (c < 0x10000) {
    char enc[] = {
        static_cast<char>(0b11100000 | c >> 12),
        static_cast<char>(0b10000000 | ((c >> 6) & 0b00111111)),
        static_cast<char>(0b10000000 | (c & 0b00111111)),
    };
    str.append(enc, 3);
  } else if (c < 0x110000) {
    char enc[] = {
        static_cast<char>(0b11110000 | c >> 18),
        static_cast<char>(0b10000000 | ((c >> 12) & 0b00111111)),
        static_cast<char>(0b10000000 | ((c >> 6) & 0b00111111)),
        static_cast<char>(0b10000000 | (c & 0b00111111)),
    };
    str.append(enc, 4);
  }
}
