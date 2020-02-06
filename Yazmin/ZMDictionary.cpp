/*
 *  ZMDictionary.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 21/12/06.
 *  Copyright 2006 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMDictionary.h"
#include "ZMHeader.h"
#include "ZMMemory.h"
#include "ZMText.h"
#include <stdio.h>
#include <string.h>

ZMDictionary::ZMDictionary(const uint8_t *data, uint16_t userDict)
    : _data(data), _userDict(userDict) {}

int ZMDictionary::getWordSeparatorCount() const {
  return getDictionaryData()[0];
}

char ZMDictionary::getWordSeparator(int index) const {
  if (index < getWordSeparatorCount())
    return getDictionaryData()[index + 1];
  else
    return 0;
}

int ZMDictionary::getEntryLength() const {
  return getDictionaryData()[getWordSeparatorCount() + 1];
}

int ZMDictionary::getEntryCount() const {
  const uint8_t *dd = getDictionaryData();
  return dd[getWordSeparatorCount() + 2] << 8 | dd[getWordSeparatorCount() + 3];
}

uint16_t ZMDictionary::getEntryAddress(int index) const {
  uint16_t addr;
  if (_userDict)
    addr = _userDict;
  else {
    ZMHeader header(_data);
    addr = header.getDictionaryLocation();
  }
  return addr + getWordSeparatorCount() + index * getEntryLength() + 4;
}

void ZMDictionary::lex(uint16_t textBufferAddress, uint8_t *parseBuffer,
                       bool flag) const {
  // Break into individual words
  const int kMaxWordCount = 256;
  int wordIndex[kMaxWordCount];
  int wordLen[kMaxWordCount];
  int wordCount =
      tokenise(reinterpret_cast<const char *>(_data) + textBufferAddress,
               kMaxWordCount, wordIndex, wordLen);

  char buf[kMaxWordCount];
  for (int i = 0; i < wordCount; ++i) {
    memcpy(buf,
           reinterpret_cast<const char *>(_data) + textBufferAddress +
               wordIndex[i],
           wordLen[i]);
    buf[wordLen[i]] = 0;
  }

  // Put the number of words into the parse buffer
  uint8_t *parseBufferPtr = parseBuffer + 1;
  *parseBufferPtr = static_cast<uint8_t>(wordCount);

  // For each word...
  ZMHeader header(_data);
  const int kPackedWordLen = header.getVersion() <= 3 ? 4 : 6;
  uint8_t packedWord[6];
  for (int i = 0; i < wordCount; ++i) {
    // Encode each word into packed format
    ZMText text(_data);
    text.encode(packedWord,
                reinterpret_cast<const char *>(_data) + textBufferAddress +
                    wordIndex[i],
                wordLen[i], kPackedWordLen);

    // Find the word in the dictionary
    uint16_t addr = 0;
    for (int j = 0; j < getEntryCount(); ++j) {
      addr = getEntryAddress(j);
      const uint8_t *wordPtr = _data + addr;
      if (memcmp(packedWord, wordPtr, kPackedWordLen) == 0) {
        break;
      }
      addr = 0;
    }

    if (!flag || (flag && addr)) {

      // Put the word address into the parse buffer (or zero if not found)
      parseBufferPtr = (parseBuffer + 2) + 4 * i;
      ZMMemory::writeWordToData(parseBufferPtr, addr);
      parseBufferPtr[2] = wordLen[i];
      parseBufferPtr[3] = wordIndex[i];
    }
  }
}

void ZMDictionary::dump() const {
  for (int i = 0; i < getEntryCount(); ++i) {
    auto addr = getEntryAddress(i);
    const auto wordPtr = _data + addr;
    size_t len;
    ZMText text(_data);
    auto str = text.decode(wordPtr, len);
    printf("%s\n", str.c_str());
  }
}

const uint8_t *ZMDictionary::getDictionaryData() const {
  if (_userDict) {
    return _data + _userDict;
  } else {
    ZMHeader header(_data);
    return _data + header.getDictionaryLocation();
  }
}

int ZMDictionary::tokenise(const char *str, int maxWordCount, int *wordIndex,
                           int *wordLen) const {
  int currWordIndex = 0;
  int wordCount = 0;
  bool inWord = false;
  ZMHeader header(_data);
  int start = header.getVersion() <= 4 ? 1 : 2;
  int len = header.getVersion() <= 4 ? str[0] : str[1];
  int i;
  for (i = start; i < start + len; ++i) {
    if (str[i] == 0) {
      // We've hit a terminating character (v1 to v3)
      if (inWord) {
        inWord = false;
        wordIndex[wordCount] = currWordIndex;
        wordLen[wordCount] = i - currWordIndex;
        ++wordCount;
      }
      break;
    } else if (str[i] == ' ' && inWord) {
      // We've found a space after a word
      inWord = false;
      wordIndex[wordCount] = currWordIndex;
      wordLen[wordCount] = i - currWordIndex;
      ++wordCount;
    } else if (separator(str[i]) > -1) {
      if (inWord) {
        // End the current word
        inWord = false;
        wordIndex[wordCount] = currWordIndex;
        wordLen[wordCount] = i - currWordIndex;
        ++wordCount;
      }

      // Make a word out of this separator
      wordIndex[wordCount] = i;
      wordLen[wordCount] = 1;
      ++wordCount;
    } else if (str[i] != ' ' && !inWord) {
      currWordIndex = i;
      inWord = true;
    }
  }

  if (inWord) {
    // We've finished the buffer (v5 and later)
    wordIndex[wordCount] = currWordIndex;
    wordLen[wordCount] = i - currWordIndex;
    ++wordCount;
  }

  return wordCount;
}

int ZMDictionary::separator(char c) const {
  for (int i = 0; i < getWordSeparatorCount(); ++i)
    if (c == getWordSeparator(i))
      return i;
  return -1;
}
