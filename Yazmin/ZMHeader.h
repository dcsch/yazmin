/*
 *  ZMHeader.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 10/12/06.
 *  Copyright 2006 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_HEADER_H__
#define ZM_HEADER_H__

#include <stdint.h>
#include <string>

class ZMHeader
{
public:
    ZMHeader(uint8_t *headerData);
    
    uint8_t getVersion() const;
    
    uint8_t getFlags1() const;

    uint16_t getRelease() const;
    
    uint16_t getBaseHighMemory() const;
    
    uint16_t getInitialProgramCounter() const;
    
    uint16_t getDictionaryLocation() const;
    
    uint16_t getObjectTableLocation() const;
    
    uint16_t getGlobalVariableTableLocation() const;
    
    uint16_t getBaseStaticMemory() const;
    
    uint16_t getAbbreviationsTableLocation() const;
    
    uint32_t getFileLength() const;
    
    uint16_t getFileChecksum() const;

    uint8_t getScreenHeight() const;
    
    void setScreenHeight(uint8_t height);
    
    uint8_t getScreenWidth() const;
    
    void setScreenWidth(uint8_t width);
    
    std::string getSerialCode() const;
    
    uint16_t getAlphabetTableAddress() const;

    void dump() const;

private:
    uint8_t *_headerData;
    uint8_t _preV4ScreenHeight;
    uint8_t _preV4ScreenWidth;
};

inline uint8_t ZMHeader::getVersion() const
{
    return _headerData[0];
}

inline uint8_t ZMHeader::getFlags1() const
{
    return _headerData[1];
}

inline uint16_t ZMHeader::getRelease() const
{
    return ((uint16_t) _headerData[2] << 8) | _headerData[3];
}

inline uint16_t ZMHeader::getBaseHighMemory() const
{
    return ((uint16_t) _headerData[4] << 8) | _headerData[5];
}

inline uint16_t ZMHeader::getInitialProgramCounter() const
{
    return ((uint16_t) _headerData[6] << 8) | _headerData[7];
}

inline uint16_t ZMHeader::getDictionaryLocation() const
{
    return ((uint16_t) _headerData[8] << 8) | _headerData[9];
}

inline uint16_t ZMHeader::getObjectTableLocation() const
{
    return ((uint16_t) _headerData[0x0a] << 8) | _headerData[0x0b];
}

inline uint16_t ZMHeader::getGlobalVariableTableLocation() const
{
    return ((uint16_t) _headerData[0x0c] << 8) | _headerData[0x0d];
}

inline uint16_t ZMHeader::getBaseStaticMemory() const
{
    return ((uint16_t) _headerData[0x0e] << 8) | _headerData[0x0f];
}

inline uint16_t ZMHeader::getAbbreviationsTableLocation() const
{
    return ((uint16_t) _headerData[0x18] << 8) | _headerData[0x19];
}

inline uint32_t ZMHeader::getFileLength() const
{
    uint16_t len = ((uint16_t) _headerData[0x1a] << 8) | _headerData[0x1b];
    if (getVersion() <= 3)
        return 2 * len;
    else if (getVersion() <= 5)
        return 4 * len;
    else
        return 8 * len;
}

inline uint16_t ZMHeader::getFileChecksum() const
{
    return ((uint16_t) _headerData[0x1c] << 8) | _headerData[0x1d];
}

inline uint8_t ZMHeader::getScreenHeight() const
{
    if (getVersion() < 4)
        return _preV4ScreenHeight;
    else
        return _headerData[0x20];
}

inline void ZMHeader::setScreenHeight(uint8_t height)
{
    if (getVersion() < 4)
        _preV4ScreenHeight = height;
    else
        _headerData[0x20] = height;
}

inline uint8_t ZMHeader::getScreenWidth() const
{
    if (getVersion() < 4)
        return _preV4ScreenWidth;
    else
        return _headerData[0x21];
}

inline void ZMHeader::setScreenWidth(uint8_t width)
{
    if (getVersion() < 4)
        _preV4ScreenWidth = width;
    else
        _headerData[0x21] = width;
}

inline uint16_t ZMHeader::getAlphabetTableAddress() const
{
    if (getVersion() < 5)
        return 0;
    else
        return ((uint16_t) _headerData[0x34] << 8) | _headerData[0x35];
}

#endif //ZM_HEADER_H__
