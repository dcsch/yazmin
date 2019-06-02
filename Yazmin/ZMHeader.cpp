/*
 *  ZMHeader.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 10/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMHeader.h"
#include <stdio.h>

ZMHeader::ZMHeader(uint8_t *headerData)
    : _headerData(headerData), _preV4ScreenHeight(0), _preV4ScreenWidth(0) {}

std::string ZMHeader::getSerialCode() const {
  char revision[7];
  for (int i = 0; i < 6; ++i)
    if (_headerData[i + 0x12] == 0)
      revision[i] = '-';
    else
      revision[i] = _headerData[i + 0x12];
  revision[6] = 0;
  return std::string(revision);
}

void ZMHeader::dump() const {
  printf("Version:                     %d\n", getVersion());
  printf("Flags 1:                     %02x\n", getFlags1());
  printf("BaseHighMemory:              %04x\n", getBaseHighMemory());
  printf("InitialProgramCounter:       %04x\n", getInitialProgramCounter());
  printf("DictionaryLocation:          %04x\n", getDictionaryLocation());
  printf("ObjectTableLocation:         %04x\n", getObjectTableLocation());
  printf("GlobalVariableTableLocation: %04x\n",
         getGlobalVariableTableLocation());
  printf("BaseStaticMemory:            %04x\n", getBaseStaticMemory());
  printf("Flags 2:                     %02x\n", getFlags2());
  printf("AbbreviationsTableLocation:  %04x\n",
         getAbbreviationsTableLocation());
  printf("FileLength:                  %x\n", getFileLength());
  printf("FileChecksum:                %04x\n", getFileChecksum());

  if (getVersion() < 4)
    return;

  printf("ScreenHeight:                %02x\n", getScreenHeight());
  printf("ScreenWidth:                 %02x\n", getScreenWidth());
}
