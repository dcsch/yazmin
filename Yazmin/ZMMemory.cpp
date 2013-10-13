/*
 *  ZMMemory.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 14/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMMemory.h"
#include "ZMObject.h"
#include "ZMText.h"
#include <stdio.h>
#include <assert.h>

ZMMemory::ZMMemory(const uint8_t *data, size_t length) :
_data(new uint8_t[length]),
_originalDynamicData(0),
_size(length),
_header(_data),
_dict(_data),
_objectMap()
{
    // Copy the data into memory
    memcpy(_data, data, length);

    // Create a copy of the original dynamic memory
    _originalDynamicData = new uint8_t[_header.getBaseStaticMemory()];
    memcpy(_originalDynamicData, data, _header.getBaseStaticMemory());

    // Prepare the header bytes
    initHeader();
}

ZMMemory::~ZMMemory()
{
    std::map<int, ZMObject *>::iterator pos;
    for (pos = _objectMap.begin(); pos != _objectMap.end(); ++pos)
        delete pos->second;
    delete [] _data;
    delete [] _originalDynamicData;
}

void ZMMemory::initHeader()
{
    if (_header.getVersion() < 4)
    {
        _data[1] |= 0x60;  // Variable-pitch font is the default
                           // Screen-splitting available
    }
    else
    {
        // V4
        _data[1] |= 0x01;  // Colours are available
        _data[1] |= 0x04;  // Boldface available
        _data[1] |= 0x08;  // Italic available
        _data[1] |= 0x10;  // Fixed-space font available
        _data[1] |= 0x80;  // Timed keyboard input available
        
        _data[0x1e] = 3;   // Interpreter number
        _data[0x1f] = 'Z'; // Interpreter version
        _data[0x20] = 0x21;   // Screen height (set to match Zoom for testing)
        _data[0x21] = 0x5e;   // Screen width (set to match Zoom for testing)
        
        if (_header.getVersion() >= 5)
        {
            // V5
            setWord(0x22, _data[0x21]);  // Screen width in units
            setWord(0x24, _data[0x20]);  // Screen height in units
            setByte(0x26, 1);            // Font width in units
            setByte(0x27, 1);            // Font height in units
            setByte(0x2c, 0x09);         // Default background colour (set to match Zoom for testing)
            setByte(0x2d, 0x02);         // Default foreground colour (set to match Zoom for testing)
        }
    }

    _data[0x32] = 1;   // Standard revision number (major)
    _data[0x33] = 1;   // Standard revision number (minor)
}

uint16_t ZMMemory::getGlobal(int index) const
{
    return readWordFromData(_data + _header.getGlobalVariableTableLocation() + 2 * index);
}

void ZMMemory::setGlobal(int index, uint16_t value)
{
    writeWordToData(_data + _header.getGlobalVariableTableLocation() + 2 * index, value);
}

ZMObject& ZMMemory::getObject(int objectNumber)
{
    assert(objectNumber > 0);

    // Is the object already in memory?
    ZMObject *obj = _objectMap[objectNumber];
    if (obj == 0)
    {
        obj = new ZMObject(*this, objectNumber);
        _objectMap[objectNumber] = obj;

        // TESTING
        //std::string name = obj->getShortName();
        //printf("Object: %s\n", name.c_str());
    }
    return *obj;
}

uint16_t ZMMemory::getObjectCount()
{
    // The algorithm we'll use is based on the 'infodump' one as referenced in
    // the z-spec10 document.  Quoting from that:
    // "The largest valid object number is not directly stored anywhere in the
    // Z-machine. Utility programs like Infodump deduce this number by assuming
    // that, initially, the object entries end where the first property table
    // begins." 
    uint16_t objLoc = 0;
    uint16_t lowestPropLoc = 0xffff;
    uint16_t count = 0;
    while (objLoc < lowestPropLoc)
    {
        ++count;
        objLoc = ZMObject::getObjectDataLocation(*this, count);
        lowestPropLoc = std::min(lowestPropLoc,
                                 ZMObject::getPropertyTableAddress(*this, objLoc));
    }
    return count - 1;
}

void ZMMemory::createCMemChunk(uint8_t **rleBuf, size_t *rleLen)
{
    // Creates a Quetzal CMem chunk (as specified in secion 3)
    
    // Perform an XOR between the original data and the current
    size_t dynLen = _header.getBaseStaticMemory();
    uint8_t *buf = new uint8_t[dynLen];
    for (unsigned int i = 0; i < dynLen; ++i)
        buf[i] = _data[i] ^ _originalDynamicData[i];
    
    // Trim the length of the buffer so we exclude trailing zeros
    for (long i = dynLen - 1; i >= 0; --i)
        if (buf[i] != 0)
        {
            dynLen = i + 1;
            break;
        }
    
    // Run-length encode it
    *rleBuf = new uint8_t[dynLen];
    uint8_t *rlePtr = *rleBuf;
    uint8_t *runStart;
    int runCount = 0;
    bool endRun = false;
    for (unsigned int i = 0; i < dynLen; ++i)
    {
        if (buf[i] == 0)
        {
            // This is a zero, so it'll be RLE'd
            if (runCount == 0)
                runStart = buf + i;

            // But of course we can't exceed a length of 256
            if (runCount < 256)
                ++runCount;
            else
                endRun = true;
        }
        
        if (buf[i] != 0 || endRun)
        {
            if (runCount > 0)
            {
                // Write zero and run-length
                *rlePtr = 0;
                ++rlePtr;
                *rlePtr = runCount - 1;
                ++rlePtr;
            }

            // If this is non-zero, write it in
            if (buf[i] != 0)
            {
                *rlePtr = buf[i];
                ++rlePtr;
            }
            
            // Remember to count the zero that ended the run
            if (endRun)
                runCount = 1;
            else
                runCount = 0;
            endRun = false;
        }
    }
    
    delete [] buf;
    *rleLen = rlePtr - *rleBuf;
}

void ZMMemory::createIFhdChunk(uint8_t **buf, size_t *len, uint32_t pc)
{
    *buf = new uint8_t[13];
    *len = 13;

    // release number
    (*buf)[0] = _data[0x02];
    (*buf)[1] = _data[0x03];
    
    // serial number
    memcpy(*buf + 2, _data + 0x12, 6);
    
    // checksum
    (*buf)[8] = _data[0x1c];
    (*buf)[9] = _data[0x1d];
    
    // PC
    (*buf)[10] = static_cast<uint8_t>(pc >> 16);
    (*buf)[11] = static_cast<uint8_t>(pc >> 8);
    (*buf)[12] = static_cast<uint8_t>(pc);
}

void ZMMemory::dump() const
{
    // Dump global memory values
    printf("Global variables:");
    uint8_t *ptr = _data + _header.getGlobalVariableTableLocation();
    for (int i = 0; i < 240; ++i)
    {
        if (i % 8 == 0)
            printf("\n%02x: ", i);
        printf("%04x ", readWordFromData(ptr));
        ptr += 2;
    }
    printf("\n");
}

uint16_t ZMMemory::readWordFromData(const uint8_t *data)
{
    return (data[0] << 8) | data[1];
}

void ZMMemory::writeWordToData(uint8_t *data, uint16_t value)
{
    data[0] = static_cast<uint8_t>(value >> 8);
    data[1] = static_cast<uint8_t>(value);
}
