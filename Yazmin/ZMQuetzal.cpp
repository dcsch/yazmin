//
//  ZMQuetzal.cpp
//  Yazmin
//
//  Created by David Schweinsberg on 6/4/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "ZMQuetzal.h"
#include "ZMIO.h"
#include "ZMMemory.h"
#include "ZMStack.h"
#include "iff.h"

ZMQuetzal::ZMQuetzal(ZMMemory &memory, ZMStack &stack)
    : _memory(memory), _stack(stack) {}

void ZMQuetzal::save(const ZMIO &zmio, uint32_t pc) const {
  uint8_t *cmemBuf;
  size_t cmemLen;
  createCMemChunk(&cmemBuf, &cmemLen);

  uint8_t *stksBuf;
  size_t stksLen;
  createStksChunk(&stksBuf, &stksLen);

  uint8_t *ihhdBuf;
  size_t ifhdLen;
  createIFhdChunk(&ihhdBuf, &ifhdLen, pc);

  // Calculate how much space we need for all these chunks
  size_t iffLen = paddedLength(cmemLen) + paddedLength(stksLen) +
                  paddedLength(ifhdLen) + 30;

  IFFHandle handle;
  IFFCreateBuffer(&handle, iffLen);
  IFFBeginForm(&handle, IFFID('I', 'F', 'Z', 'S'));

  IFFBeginChunk(&handle, IFFID('I', 'F', 'h', 'd'));
  IFFWrite(&handle, ihhdBuf, ifhdLen);
  IFFEndChunk(&handle);

  IFFBeginChunk(&handle, IFFID('C', 'M', 'e', 'm'));
  IFFWrite(&handle, cmemBuf, cmemLen);
  IFFEndChunk(&handle);

  IFFBeginChunk(&handle, IFFID('S', 't', 'k', 's'));
  IFFWrite(&handle, stksBuf, stksLen);
  IFFEndChunk(&handle);

  char anno[256];
  snprintf(anno, 256, "Version %d game, saved from Yazmin version 0.9.1",
           _memory.getHeader().getVersion());
  size_t annoLen = strlen(anno);
  IFFBeginChunk(&handle, IFFID('A', 'N', 'N', 'O'));
  IFFWrite(&handle, anno, annoLen);
  IFFEndChunk(&handle);

  IFFEndForm(&handle);

  zmio.save(handle.data, handle.pos);

  IFFCloseBuffer(&handle);

  delete[] ihhdBuf;
  delete[] stksBuf;
  delete[] cmemBuf;
}

uint32_t ZMQuetzal::restore(const ZMIO &zmio) {
  const uint8_t *buf;
  size_t bufLen;
  zmio.endRestore(&buf, &bufLen);

  IFFHandle handle;
  // TODO: fix this hack
  IFFSetBuffer(&handle, const_cast<unsigned char *>(buf), bufLen);

  bool matched = false;
  uint32_t pc = 0;
  unsigned long size;
  unsigned long type;
  if (IFFNextForm(&handle, &size, &type) &&
      (type == IFFID('I', 'F', 'Z', 'S'))) {
    unsigned long chunkType;
    unsigned long chunkSize;
    do {
      IFFGetChunk(&handle, &chunkType, &chunkSize);
      if (chunkType == IFFID('I', 'F', 'h', 'd')) {
        matched =
            compareIFhdChunk(handle.data + handle.pos + 8, chunkSize, &pc);
        if (!matched)
          break;
      } else if (chunkType == IFFID('C', 'M', 'e', 'm')) {
        extractCMemChunk(handle.data + handle.pos + 8, chunkSize);
      } else if (chunkType == IFFID('S', 't', 'k', 's')) {
        extractStksChunk(handle.data + handle.pos + 8, chunkSize);
      }
    } while (IFFNextChunk(&handle));
  }

  delete[] buf;

  return pc;
}

void ZMQuetzal::pushSnapshot(uint32_t pc) {
  uint8_t *cmemBuf;
  size_t cmemLen;
  createCMemChunk(&cmemBuf, &cmemLen);

  uint8_t *stksBuf;
  size_t stksLen;
  createStksChunk(&stksBuf, &stksLen);

  uint8_t *ihhdBuf;
  size_t ifhdLen;
  createIFhdChunk(&ihhdBuf, &ifhdLen, pc);

  delete[] ihhdBuf;
  delete[] stksBuf;
  delete[] cmemBuf;
}

void ZMQuetzal::createCMemChunk(uint8_t **rleBuf, size_t *rleLen) const {
  // Creates a Quetzal CMem chunk (as specified in secion 3)

  // Perform an XOR between the original data and the current
  size_t dynLen = _memory.getHeader().getBaseStaticMemory();
  uint8_t *buf = new uint8_t[dynLen];
  for (unsigned int i = 0; i < dynLen; ++i)
    buf[i] = _memory.getData()[i] ^ _memory.getOriginalDynamicData()[i];

  // Trim the length of the buffer so we exclude trailing zeros
  for (long i = dynLen - 1; i >= 0; --i)
    if (buf[i] != 0) {
      dynLen = i + 1;
      break;
    }

  // Run-length encode it
  *rleBuf = new uint8_t[dynLen];
  uint8_t *rlePtr = *rleBuf;
  uint8_t *runStart;
  int runCount = 0;
  bool endRun = false;
  for (unsigned int i = 0; i < dynLen; ++i) {
    if (buf[i] == 0) {
      // This is a zero, so it'll be RLE'd
      if (runCount == 0)
        runStart = buf + i;

      // But of course we can't exceed a length of 256
      if (runCount < 256)
        ++runCount;
      else
        endRun = true;
    }

    if (buf[i] != 0 || endRun) {
      if (runCount > 0) {
        // Write zero and run-length
        *rlePtr = 0;
        ++rlePtr;
        *rlePtr = runCount - 1;
        ++rlePtr;
      }

      // If this is non-zero, write it in
      if (buf[i] != 0) {
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

  delete[] buf;
  *rleLen = rlePtr - *rleBuf;
}

void ZMQuetzal::extractCMemChunk(uint8_t *rleBuf, size_t rleLen) {

  // A chunk of memory to decode into
  size_t dynLen = _memory.getHeader().getBaseStaticMemory();
  uint8_t *buf = new uint8_t[dynLen];
  memset(buf, 0, dynLen);

  // Run-length decode it
  size_t offset = 0;
  for (unsigned int i = 0; i < rleLen; ++i) {
    if (rleBuf[i] == 0) {
      size_t runLen = rleBuf[i + 1];
      memset(buf + offset, 0, runLen + 1);
      ++i;
      offset += runLen + 1;
    } else {
      buf[offset] = rleBuf[i];
      offset++;
    }
  }

  // Perform an XOR between the original data and the extracted
  for (unsigned int i = 0; i < dynLen; ++i)
    _memory.setByte(i, buf[i] ^ _memory.getOriginalDynamicData()[i]);

  delete[] buf;
}

void ZMQuetzal::createIFhdChunk(uint8_t **buf, size_t *len, uint32_t pc) const {
  *buf = new uint8_t[13];
  *len = 13;

  // release number
  (*buf)[0] = _memory.getData()[0x02];
  (*buf)[1] = _memory.getData()[0x03];

  // serial number
  memcpy(*buf + 2, _memory.getData() + 0x12, 6);

  // checksum
  (*buf)[8] = _memory.getData()[0x1c];
  (*buf)[9] = _memory.getData()[0x1d];

  // PC
  (*buf)[10] = static_cast<uint8_t>(pc >> 16);
  (*buf)[11] = static_cast<uint8_t>(pc >> 8);
  (*buf)[12] = static_cast<uint8_t>(pc);
}

bool ZMQuetzal::compareIFhdChunk(uint8_t *buf, size_t len, uint32_t *pc) const {

  // release number
  if (_memory.getByte(0x02) != buf[0] || _memory.getByte(0x03) != buf[1])
    return false;

  // serial number
  if (memcmp(_memory.getData() + 0x12, buf + 2, 6) != 0)
    return false;

  // checksum
  if (_memory.getByte(0x1c) != buf[8] || _memory.getByte(0x1d) != buf[9])
    return false;

  // PC
  *pc = static_cast<uint32_t>(buf[10] << 16) |
        static_cast<uint32_t>(buf[11] << 8) | static_cast<uint32_t>(buf[12]);

  return true;
}

void ZMQuetzal::createStksChunk(uint8_t **buf, size_t *len) const {
  int framePointers[256];
  int count = _stack.framePointerArray(framePointers, 256);

  *len = 0;
  *buf = new uint8_t[2 * _stack.getStackPointer()];
  uint8_t *ptr = *buf;

  // Go through the frame pointers, copying each frame into the
  // supplied buffer
  for (int i = 0; i < count; ++i) {
    int fp = framePointers[i];
    int localCount = 0;

    // return PC (byte address)
    ptr[0] = static_cast<uint8_t>(_stack.getEntry(fp));
    ptr[1] = static_cast<uint8_t>(_stack.getEntry(fp + 1) >> 8);
    ptr[2] = static_cast<uint8_t>(_stack.getEntry(fp + 1));

    // flags
    ptr[3] = 0;
    if (_stack.getEntry(fp + 2) == 0xffff) // RETURN_STORE
    {
      ptr[3] |= 0x10;

      // variable number to store result
      ptr[4] = 0;
    } else
      ptr[4] = static_cast<uint8_t>(_stack.getEntry(fp + 2));

    // arguments supplied
    switch (_stack.getEntry(fp + 4)) {
    case 0:
      ptr[5] = 0;
      break;
    case 1:
      ptr[5] = 0x01;
      break;
    case 2:
      ptr[5] = 0x03;
      break;
    case 3:
      ptr[5] = 0x07;
      break;
    case 4:
      ptr[5] = 0x0f;
      break;
    case 5:
      ptr[5] = 0x1f;
      break;
    case 6:
      ptr[5] = 0x3f;
      break;
    case 7:
      ptr[5] = 0x7f;
      break;
    }

    localCount = _stack.getEntry(fp + 5);

    // number of words of evaluations stack used by this call
    int totalEntryCount = 0;
    if (i == count - 1) {
      // This is the last frame, so calculate the evaluation stack size
      // using the stack pointer
      totalEntryCount = _stack.getStackPointer() - framePointers[i];
    } else {
      // Calculate the evaluation stack size by looking at the
      // frame pointers
      totalEntryCount = framePointers[i + 1] - framePointers[i];
    }
    int evalCount = totalEntryCount - localCount - 6;
    ptr[6] = static_cast<uint8_t>(evalCount >> 8);
    ptr[7] = static_cast<uint8_t>(evalCount);

    // local variables
    ptr[3] |= static_cast<uint8_t>(localCount & 0x0f);
    uint8_t *p = &ptr[8];
    int entryIndex = fp + 6;
    for (int j = 0; j < localCount; ++j) {
      p[0] = static_cast<uint8_t>(_stack.getEntry(entryIndex) >> 8);
      p[1] = static_cast<uint8_t>(_stack.getEntry(entryIndex));
      p += 2;
      ++entryIndex;
    }

    // evaluation stack for this call
    for (int j = 0; j < evalCount; ++j) {
      p[0] = static_cast<uint8_t>(_stack.getEntry(entryIndex) >> 8);
      p[1] = static_cast<uint8_t>(_stack.getEntry(entryIndex));
      p += 2;
      ++entryIndex;
    }

    // Move on to the next frame
    int byteLen = 2 * (localCount + evalCount) + 8;
    ptr += byteLen;
    *len += byteLen;
  }
}

void ZMQuetzal::extractStksChunk(uint8_t *buf, size_t len) {
  _stack.reset();
  size_t offset = 0;
  while (offset < len) {
    uint32_t retAddr = static_cast<uint32_t>(buf[offset + 0] << 16) |
                       static_cast<uint32_t>(buf[offset + 1] << 8) |
                       static_cast<uint32_t>(buf[offset + 2]);
    uint8_t flags = buf[offset + 3];
    uint8_t resultStore = buf[offset + 4];
    uint8_t argsSupplied = buf[offset + 5];
    uint16_t evalCount = static_cast<uint32_t>(buf[offset + 6] << 8) |
                         static_cast<uint32_t>(buf[offset + 7]);
    uint16_t frameSize = 2 * ((flags & 0x0f) + evalCount) + 8;
    uint16_t *varsAndEvalStack = reinterpret_cast<uint16_t *>(buf + offset + 7);
    _stack.pushFrame(retAddr, flags, resultStore, argsSupplied, evalCount,
                     varsAndEvalStack);
    offset += frameSize;
  }
}
