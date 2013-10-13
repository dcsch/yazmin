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

static const char _defaultA0[] =
{
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
};

static const char _defaultA1[] =
{
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
};

static const char _defaultA2[] =
{
    ' ', '^', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.',
    ',', '!', '?', '_', '#', '\'', '"', '/', '\\', '-', ':', '(', ')'
};

ZMText::ZMText(uint8_t *memoryBase) :
_memoryBase(memoryBase),
_a0(_defaultA0),
_a1(_defaultA1),
_a2(_defaultA2),
_charset(_a0),
_abbreviation(0),
_10bit(0),
_highBits(0)
{
    // Are we to use an alphabet table from memory?
    ZMHeader header(_memoryBase);
    uint16_t addr = header.getAlphabetTableAddress();
    if (addr)
    {
        _a0 = reinterpret_cast<char *>(_memoryBase + addr);
        _a1 = _a0 + 26;
        _a2 = _a1 + 26;
        _charset = _a0;
    }
}

int ZMText::decode(const uint8_t *data,
                   char *ascii,
                   size_t maxLen,
                   size_t *encodedLen)
{
    const uint8_t *ptr = data;
    char *asciiPtr = ascii;
    char bytes[3];
    bool eol = false;
    while (!eol && (static_cast<size_t>(asciiPtr - ascii) < maxLen))
    {
        eol = unpackWord(ZMMemory::readWordFromData(ptr), bytes);
        ptr += 2;
        for (int i = 0; i < 3; ++i)
        {
            int len = zsciiToAscii(bytes[i],
                                   asciiPtr,
                                   maxLen - (asciiPtr - ascii));
            asciiPtr += len;
        }
    }
    
    // Null-terminate the string
    *asciiPtr = 0;
    
    if (encodedLen != 0)
        *encodedLen = ptr - data;
    
    // Return the length
    return (int)(asciiPtr - ascii);
}

void ZMText::encode(uint8_t *data,
                    const char *ascii,
                    size_t asciiLen,
                    size_t encodedLen)
{
//    char bytes[3];
    uint8_t zscii[256];
    uint8_t *zsciiPtr = zscii;
    int zsciiLen;
    const char *asciiPtr = ascii;
    for (size_t i = 0; i < asciiLen; ++i)
    {
        zsciiLen = asciiToZscii(*asciiPtr, zsciiPtr);
        ++asciiPtr;
        zsciiPtr += zsciiLen;
    }
    zsciiLen = (int)(zsciiPtr - zscii);
    
//    // Pad the buffer out to a multiple of three with 5s
//    int modLen = zsciiLen % 3;
//    if (modLen > 0)
//        for (int i = 0; i < modLen; ++i)
//            *zsciiPtr++ = 5;
//    zsciiLen += modLen;
    
    // Pad the buffer so the length will pack down to the specified
    // encoded length (this assumes that the unpacked length is divisable
    // by three)
    int paddingLen = (int)(encodedLen * 3 / 2) - zsciiLen;
    for (int i = 0; i < paddingLen; ++i)
        *zsciiPtr++ = 5;
    zsciiLen += paddingLen;
    
    uint8_t *dataPtr = data;
    for (int i = 0; i < zsciiLen; i += 3)
    {
        uint16_t word = packWord(zscii + i);
        
        // Set the high bit of the last word to 1, thus terminating the string
        if (i == zsciiLen - 3)
            word |= 0x8000;

        ZMMemory::writeWordToData(dataPtr, word);
        dataPtr += 2;
    }
}

int ZMText::abbreviation(int index, char *ascii, size_t maxLen)
{
    ZMHeader header(_memoryBase);
    uint16_t addr = header.getAbbreviationsTableLocation() + 2 * index;
    
    // The abbreviations table uses word addresses, so we must multiply the
    // address by 2
    uint16_t ptr = 2 * ZMMemory::readWordFromData(_memoryBase + addr);
    int len = decode(_memoryBase + ptr, ascii, maxLen);
    
    // 0x05s padding out the end of an abbreviation can leave the charset
    // set incorrectly
    _charset = _a0;
    
    return len;
}

size_t ZMText::getEncodedLength(uint32_t addr)
{
    const uint8_t *p = _memoryBase + addr;
    while ((*p & 0x80) != 0x80)
    {
        p += 2;
    }
    return (p - (_memoryBase + addr));
}

size_t ZMText::getDecodedLength(uint32_t addr)
{
    // This is simple at the moment, in that the length it returns can be a
    // little longer that the string actually is
    // NOTE: This doesn't work properly because it isn't taking abbreviations
    // into account.  It will have to be reworked so that it does.
    return getEncodedLength(addr) * 3 / 2 + 100;
}

size_t ZMText::getString(uint32_t addr, char *ascii, size_t maxLen)
{
    size_t encLen;
    decode(_memoryBase + addr, ascii, maxLen, &encLen);
    return encLen;
}

bool ZMText::unpackWord(uint16_t word, char *bytes)
{
    bytes[0] = static_cast<char>((word >> 10) & 0x1f);
    bytes[1] = static_cast<char>((word >> 5) & 0x1f);
    bytes[2] = static_cast<char>(word & 0x1f);
    return (word & 0x8000) ? true : false;
}

uint16_t ZMText::packWord(const uint8_t *bytes)
{
    return ((bytes[0] & 0x1f) << 10)
        | ((bytes[1] & 0x1f) << 5)
        | (bytes[2] & 0x1f);
}

int ZMText::zsciiToAscii(char z, char *ascii, size_t maxLen)
{
    if (_10bit > 0)
    {
        if (_10bit == 2)
        {
            _highBits = z & 0x1f;
            _10bit = 1;
            return 0;
        }
        else
        {
            *ascii = _highBits << 5 | z;
            _10bit = 0;
        }
    }
    else if (_abbreviation != 0)
    {
        int n = _abbreviation;
        _abbreviation = 0;
        return abbreviation(((n - 1) << 5) + z, ascii, maxLen);
    }
    else if (z > 5)
    {
        if (z == 6 && _charset == _a2)
        {
            _10bit = 2;
            _charset = _a0;
            return 0;
        }

        *ascii = _charset[static_cast<int>(z) - 6];
        _charset = _a0;
    }
    else if (z == 0)
        *ascii = ' ';
    else if (z == 4)
    {
        _charset = _a1;
        return 0;
    }
    else if (z == 5)
    {
        _charset = _a2;
        return 0;
    }
    else
    {
        _abbreviation = z;
        return 0;
    }

    return 1;
}

bool ZMText::findInAlphabet(char ascii, int *charset, uint8_t *zscii)
{
    const char *an[] = { _a0, _a1, _a2 };
    for (int set = 0; set < 3; ++set)
    {
        // Scan for the character
        for (uint8_t i = 0; i < 26; ++i)
            if (an[set][i] == ascii)
            {
                *charset = set;
                *zscii = i + 6;
                return true;
            }
    }
    return false;
}

int ZMText::asciiToZscii(char ascii, uint8_t *zscii)
{
    // If the ascii char is in any of the three (A0, A1, A2) 5-bit charsets,
    // encode into 5 bits
    int set;
    uint8_t z;
    if (ascii == 32)  // space
    {
        zscii[0] = 0;
        return 1;
    }
    else if (findInAlphabet(ascii, &set, &z))
    {
        if (set == 0)
        {
            zscii[0] = z;
            return 1;
        }
        else if (set == 1)
        {
            zscii[0] = 4;
            zscii[1] = z;
            return 2;
        }
        else if (set == 2)
        {
            zscii[0] = 5;
            zscii[1] = z;
            return 2;
        }
        return 0;
    }
    else
    {
        // We need to encode the char as a 10-bit value
        zscii[0] = 5;
        zscii[1] = 6;
        zscii[2] = (ascii >> 5) & 0x1f;
        zscii[3] = ascii & 0x1f;
        return 4;
    }
}
