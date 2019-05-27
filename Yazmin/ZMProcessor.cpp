/*
 *  ZMProcessor.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 11/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMProcessor.h"
#include "ZMError.h"
#include "ZMIO.h"
#include "ZMMemory.h"
#include "ZMObject.h"
#include "ZMStack.h"
#include "ZMText.h"
#include "iff.h"
#include <assert.h>
#include <stdio.h>
#include <sys/sysctl.h>
#include <time.h>

static unsigned int macuptime(void) {
  int mib[2] = {CTL_KERN, KERN_BOOTTIME};
  struct timeval boottime;
  time_t now;
  size_t size = sizeof(boottime);

  if ((sysctl(mib, 2, &boottime, &size, NULL, 0) != -1) &&
      (boottime.tv_sec != 0)) {
    time(&now);
    return (unsigned)(now - boottime.tv_sec) * 60;
  } else
    return (unsigned)0;
}

ZMProcessor::ZMProcessor(ZMMemory &memory, ZMStack &stack, ZMIO &io,
                         ZMError &error)
    : _memory(memory), _stack(stack), _io(io), _error(error), _pc(0),
      _operandOffset(0), _instructionLength(0), _operandCount(0), _operands(),
      _operandTypes(), _operandVariables(), _store(0), _branch(0),
      _branchOnTrue(false), _seed(0), _lastRandomNumber(0), _version(0),
      _packedAddressFactor(0), _stringBuf(0), _stringBufLen(0), _redirectAddr(),
      _redirectIndex(-1), _hasQuit(false), _hasHalted(false),
      _continuingAfterHalt(false) {
  // If this is not a version 6 story, push a dummy frame onto the stack
  if (_memory.getHeader().getVersion() != 6)
    _stack.pushFrame(0, 0, 0, 0, 0);

  // Seed the random number generator
  _seed = macuptime() + 1000;
  srandom(_seed);
}

ZMProcessor::~ZMProcessor() { delete[] _stringBuf; }

bool ZMProcessor::execute() {
  // Lazy initialisation
  if (_version != _memory.getHeader().getVersion()) {
    _pc = _memory.getHeader().getInitialProgramCounter();
    _version = _memory.getHeader().getVersion();
    if (_version < 4)
      _packedAddressFactor = 2;
    else if (_version < 8)
      _packedAddressFactor = 4;
    else if (_version == 8)
      _packedAddressFactor = 8;
    else
      throw false; // We can't handle this
  }

  // Determine the encoding of the instruction by looking at the top two bits
  uint8_t inst = _memory[_pc];
  switch (inst & 0xc0) {
  case 0x00: // 00xx xxxx
  case 0x40: // 01xx xxxx
    return executeLongInstruction();
  case 0x80: // 10xx xxxx
    if (inst == 0xbe && _version >= 5)
      return executeExtendedInstruction();
    else
      return executeShortInstruction();
  case 0xc0: // 11xx xxxx
    return executeVariableInstruction();
  }
  return false;
}

bool ZMProcessor::executeUntilHalt() {
  // The '_continuingAfterHalt' flag will only be set for the first
  // instruction executed after a halt.
  if (!_hasQuit) {
    if (_hasHalted)
      _continuingAfterHalt = true;
    _hasHalted = false;
    while (!_hasHalted) {
      execute();
      _continuingAfterHalt = false;
    }
  }
  return _hasQuit;
}

//
// Long instructions have 2 operands
//
bool ZMProcessor::executeLongInstruction() {
  uint8_t inst = _memory[_pc];
  uint8_t opCode = inst & 0x1f; // opcode is bottom five bits

  _operandTypes[0] = (inst & 0x40) ? kVariable : kSmallConstant;
  _operandTypes[1] = (inst & 0x20) ? kVariable : kSmallConstant;

  _operandOffset = 1;

  // Load each of the arguments
  _operandCount = 2;
  for (int i = 0; i < _operandCount; ++i) {
    if (_operandTypes[i] == kVariable) {
      _operands[i] = getVariable(_memory[_pc + i + 1]);
      _operandVariables[i] = _memory[_pc + i + 1];
    } else if (_operandTypes[i] == kSmallConstant)
      _operands[i] = _memory[_pc + i + 1];
  }

  _instructionLength = _operandCount + 1;

  return dispatch2OP(opCode);
}

//
// Short instructions can only have either 0 operands or 1 operand
//
bool ZMProcessor::executeShortInstruction() {
  uint8_t inst = _memory[_pc];
  uint8_t opCode = inst & 0x0f; // opcode is bottom four bits
  _operandTypes[0] = operandType(inst >> 4);

  _instructionLength = 1;
  _operandOffset = 1;

  // Load any argument
  if (_operandTypes[0] != kOmitted) {
    _operandCount = 1;
    if (_operandTypes[0] == kLargeConstant) {
      _operands[0] = _memory.getWord(_pc + 1);
      _instructionLength += 2;
    } else if (_operandTypes[0] == kSmallConstant) {
      _operands[0] = _memory[_pc + 1];
      ++_instructionLength;
    } else if (_operandTypes[0] == kVariable) {
      _operands[0] = getVariable(_memory[_pc + 1]);
      _operandVariables[0] = _memory[_pc + 1];
      ++_instructionLength;
    }
  } else
    _operandCount = 0;

  // Execute the opcode
  if (_operandCount == 0)
    return dispatch0OP(opCode);
  else
    return dispatch1OP(opCode);
}

bool ZMProcessor::executeExtendedInstruction() {
  uint8_t inst = _memory[_pc + 1];
  uint8_t opCode = inst & 0x1f; // opcode is bottom five bits
  int operands = (inst & 0x20) ? -1 : 2;
  uint8_t operandTypeFields = _memory[_pc + 2];
  int operandFieldCount;

  _operandOffset = 3;

  _operandTypes[0] = operandType(operandTypeFields >> 6);
  _operandTypes[1] = operandType(operandTypeFields >> 4);
  _operandTypes[2] = operandType(operandTypeFields >> 2);
  _operandTypes[3] = operandType(operandTypeFields);

  if (operands == 2) {
    _instructionLength = 3;
    operandFieldCount = 4;
  } else {
    _instructionLength = 3;
    operandFieldCount = 4;
    _operandTypes[4] = kOmitted;
    _operandTypes[5] = kOmitted;
    _operandTypes[6] = kOmitted;
    _operandTypes[7] = kOmitted;
  }

  _operandCount = 0;
  for (int i = 0; i < operandFieldCount; ++i) {
    if (_operandTypes[i] == kOmitted)
      break;
    else if (_operandTypes[i] == kLargeConstant) {
      _operands[_operandCount] = ZMMemory::readWordFromData(
          _memory.getData() + _pc + _instructionLength);
      _instructionLength += 2;
    } else if (_operandTypes[i] == kSmallConstant) {
      _operands[_operandCount] = _memory[_pc + _instructionLength];
      ++_instructionLength;
    } else if (_operandTypes[i] == kVariable) {
      _operands[_operandCount] = getVariable(_memory[_pc + _instructionLength]);
      _operandVariables[_operandCount] = _memory[_pc + _instructionLength];
      ++_instructionLength;
    }
    ++_operandCount;
  }

  return dispatchEXT(opCode);
}

bool ZMProcessor::executeVariableInstruction() {
  uint8_t inst = _memory[_pc];
  uint8_t opCode = inst & 0x1f; // opcode is bottom five bits
  int operands = (inst & 0x20) ? -1 : 2;
  uint8_t operandTypeFields = _memory[_pc + 1];
  int operandFieldCount;

  _operandOffset = 2;

  _operandTypes[0] = operandType(operandTypeFields >> 6);
  _operandTypes[1] = operandType(operandTypeFields >> 4);
  _operandTypes[2] = operandType(operandTypeFields >> 2);
  _operandTypes[3] = operandType(operandTypeFields);

  if (operands == 2) {
    _instructionLength = 2;
    operandFieldCount = 4;
  } else if (_version >= 4 && (opCode == 0x0c || opCode == 0x1a)) {
    _instructionLength = 3;
    operandFieldCount = 8;
    operandTypeFields = _memory[_pc + 2];
    _operandTypes[4] = operandType(operandTypeFields >> 6);
    _operandTypes[5] = operandType(operandTypeFields >> 4);
    _operandTypes[6] = operandType(operandTypeFields >> 2);
    _operandTypes[7] = operandType(operandTypeFields);
  } else {
    _instructionLength = 2;
    operandFieldCount = 4;
    _operandTypes[4] = kOmitted;
    _operandTypes[5] = kOmitted;
    _operandTypes[6] = kOmitted;
    _operandTypes[7] = kOmitted;
  }

  _operandCount = 0;
  for (int i = 0; i < operandFieldCount; ++i) {
    if (_operandTypes[i] == kOmitted)
      break;
    else if (_operandTypes[i] == kLargeConstant) {
      _operands[_operandCount] = ZMMemory::readWordFromData(
          _memory.getData() + _pc + _instructionLength);
      _instructionLength += 2;
    } else if (_operandTypes[i] == kSmallConstant) {
      _operands[_operandCount] = _memory[_pc + _instructionLength];
      ++_instructionLength;
    } else if (_operandTypes[i] == kVariable) {
      _operands[_operandCount] = getVariable(_memory[_pc + _instructionLength]);
      _operandVariables[_operandCount] = _memory[_pc + _instructionLength];
      ++_instructionLength;
    }
    ++_operandCount;
  }

  if (operands == 2)
    return dispatch2OP(opCode);
  else
    return dispatchVAR(opCode);
}

bool ZMProcessor::dispatch0OP(uint8_t opCode) {
  switch (opCode) {
  case 0x00:
    rtrue();
    break;
  case 0x01:
    rfalse();
    break;
  case 0x02:
    print();
    break;
  case 0x03:
    print_ret();
    break;
  case 0x04:
    nop();
    break;
  case 0x05:
    save();
    break;
  case 0x06:
    restore();
    break;
  case 0x07:
    restart();
    break;
  case 0x08:
    ret_popped();
    break;
  case 0x09:
    pop();
    break;
  case 0x0a:
    quit();
    return false;
  case 0x0b:
    new_line();
    break;
  case 0x0c:
    show_status();
    break;
  case 0x0d:
    _verify();
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _hasHalted = true;
    _hasQuit = true;
    return false;
  }
  }
  return true;
}

bool ZMProcessor::dispatch1OP(uint8_t opCode) {
  switch (opCode) {
  case 0x00:
    jz();
    break;
  case 0x01:
    get_sibling();
    break;
  case 0x02:
    get_child();
    break;
  case 0x03:
    get_parent();
    break;
  case 0x04:
    get_prop_len();
    break;
  case 0x05:
    inc();
    break;
  case 0x06:
    dec();
    break;
  case 0x07:
    print_addr();
    break;
  case 0x08:
    call_1s(); // v4
    break;
  case 0x09:
    remove_obj();
    break;
  case 0x0a:
    print_obj();
    break;
  case 0x0b:
    ret();
    break;
  case 0x0c:
    jump();
    break;
  case 0x0d:
    print_paddr();
    break;
  case 0x0e:
    load();
    break;
  case 0x0f:
    if (_version >= 5) {
      call_1n();
      break;
    }
  // otherwise fall through to default
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _hasHalted = true;
    _hasQuit = true;
    return false;
  }
  }
  return true;
}

bool ZMProcessor::dispatch2OP(uint8_t opCode) {
  // Execute the opcode
  switch (opCode) {
  case 0x01:
    je();
    break;
  case 0x02:
    jl();
    break;
  case 0x03:
    jg();
    break;
  case 0x04:
    dec_chk();
    break;
  case 0x05:
    inc_chk();
    break;
  case 0x06:
    jin();
    break;
  case 0x07:
    test();
    break;
  case 0x08:
    _or();
    break;
  case 0x09:
    _and();
    break;
  case 0x0a:
    test_attr();
    break;
  case 0x0b:
    set_attr();
    break;
  case 0x0c:
    clear_attr();
    break;
  case 0x0d:
    store();
    break;
  case 0x0e:
    insert_obj();
    break;
  case 0x0f:
    loadw();
    break;
  case 0x10:
    loadb();
    break;
  case 0x11:
    get_prop();
    break;
  case 0x12:
    get_prop_addr();
    break;
  case 0x13:
    get_next_prop();
    break;
  case 0x14:
    add();
    break;
  case 0x15:
    sub();
    break;
  case 0x16:
    mul();
    break;
  case 0x17:
    div();
    break;
  case 0x18:
    mod();
    break;
  case 0x19:
    call_2s(); // v4
    break;
  case 0x1a:
    call_2n(); // v5
    break;
  case 0x1b:
    set_colour(); // v5
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _hasHalted = true;
    _hasQuit = true;
    return false;
  }
  }
  return true;
}

bool ZMProcessor::dispatchVAR(uint8_t opCode) {
  switch (opCode) {
  case 0x00:
    call_vs();
    break;
  case 0x01:
    storew();
    break;
  case 0x02:
    storeb();
    break;
  case 0x03:
    put_prop();
    break;
  case 0x04:
    if (_version < 5)
      sread();
    else
      aread();
    break;
  case 0x05:
    print_char();
    break;
  case 0x06:
    print_num();
    break;
  case 0x07:
    random();
    break;
  case 0x08:
    push();
    break;
  case 0x09:
    pull();
    break;
  case 0x0a:
    split_window(); // v3
    break;
  case 0x0b:
    set_window(); // v3
    break;
  case 0x0c:
    call_vs2(); // v4
    break;
  case 0x0d:
    erase_window(); // v4
    break;
  case 0x0f:
    set_cursor(); // v4
    break;
  case 0x11:
    set_text_style(); // v4
    break;
  case 0x12:
    buffer_mode(); // v4
    break;
  case 0x13:
    output_stream(); // v3
    break;
  case 0x16:
    read_char(); // v4
    break;
  case 0x19:
    call_vn(); // v5
    break;
  case 0x1a:
    call_vn2(); // v5
    break;
  case 0x1b:
    tokenise(); // v5
    break;
  case 0x1f:
    check_arg_count(); // v5
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _hasHalted = true;
    _hasQuit = true;
    return false;
  }
  }
  return true;
}

bool ZMProcessor::dispatchEXT(uint8_t opCode) {
  switch (opCode) {
  case 0x00:
    save();
    break;
  case 0x01:
    restore();
    break;
  //  case 0x02:
  //    log_shift();
  //    break;
  //  case 0x03:
  //    art_shift();
  //    break;
  case 0x04:
    set_font();
    break;
  case 0x09:
    save_undo();
    break;
  //  case 0x0a:
  //    restore_undo();
  //    break;
  //  case 0x0b:
  //    print_unicode();
  //    break;
  //  case 0x0c:
  //    check_unicode();
  //    break;
  //  case 0x0d:
  //    set_true_colour();
  //    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: %x\n", _pc, _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: EXT:%x\n", _pc, _memory[_pc]);
    _hasHalted = true;
    _hasQuit = true;
    return false;
  }
  }
  return true;
}

ZMProcessor::OperandType ZMProcessor::operandType(uint8_t byte) {
  switch (byte & 0x03) {
  case 0:
    return kLargeConstant;
  case 1:
    return kSmallConstant;
  case 2:
    return kVariable;
  case 3:
    return kOmitted;
  }
  return kOmitted;
}

void ZMProcessor::decodeStore() {
  _store = _memory[_pc + _instructionLength];
  ++_instructionLength;
}

void ZMProcessor::decodeBranch() {
  uint8_t firstByte = _memory[_pc + _instructionLength];
  _branchOnTrue = firstByte & 0x80 ? true : false;
  if (firstByte & 0x40) {
    _branch = firstByte & 0x3f;
    ++_instructionLength;
  } else {
    _branch = (firstByte & 0x3f) << 8 | _memory[_pc + _instructionLength + 1];
    if (firstByte & 0x20)
      _branch = -((~_branch & 0x1fff) + 1);
    _instructionLength += 2;
  }
}

uint16_t ZMProcessor::getVariable(int index) {
  if (index == 0)
    return _stack.pop();
  else if (index < 0x10)
    return _stack.getLocal(index - 1);
  else
    return _memory.getGlobal(index - 0x10);
}

void ZMProcessor::setVariable(int index, uint16_t value) {
  // We use 0xffff as a value on the stack meaning to throw away the
  // returned result
  if (index == 0xffff)
    return;
  else if (index == 0)
    _stack.push(value);
  else if (index < 0x10)
    _stack.setLocal(index - 1, value);
  else
    _memory.setGlobal(index - 0x10, value);
}

void ZMProcessor::advancePC() { _pc += _instructionLength; }

void ZMProcessor::branchOrAdvancePC(bool testResult) {
  // if ((testResult && _branchOnTrue) || (!testResult && !_branchOnTrue))
  if (testResult == _branchOnTrue) {
    // If branch is 0 or 1, then rtrue or rfalse
    if (0 <= _branch && _branch <= 1) {
      _pc = _stack.popFrame(&_store);
      setVariable(_store, _branch);
    } else
      _pc = _pc + _instructionLength + _branch - 2;
  } else
    advancePC();
}

void ZMProcessor::printToTable(const char *str) {
  uint16_t addr = _redirectAddr[_redirectIndex];
  size_t len = strlen(str);
  memcpy(_memory.getData() + addr + 2, str, len);
  _memory.setWord(addr, len);
}

void ZMProcessor::print(const char *str) {
  if (_redirectIndex == -1)
    _io.print(str);
  else
    printToTable(str);
}

void ZMProcessor::print(int16_t number) {
  if (_redirectIndex == -1)
    _io.printNumber(number);
  else {
    char buf[32];
    snprintf(buf, 32, "%d", number);
    printToTable(buf);
  }
}

void ZMProcessor::log(const char *name, bool showStore, bool showBranch) {
  //    static int count = 0;
  //    printf("%04x %05x: %s ", count++, _pc, name);
  //    for (int i = 0; i < _operandCount; ++i)
  //    {
  //        if (_operandTypes[i] == kSmallConstant)
  //        {
  //            bool asVariable = false;
  //            if (i == 0)
  //            {
  //                if (strcmp(name, "inc_chk") == 0)
  //                    asVariable = true;
  //            }
  //
  //            if (asVariable)
  //                printf("%02x<%04x> ", _operands[i],
  //                getVariable(_operands[i]));
  //            else
  //                printf("#%02x ", _operands[i]);
  //        }
  //        else if (_operandTypes[i] == kLargeConstant)
  //        {
  //            bool asPackedAddress = false;
  //            if (i == 0)
  //            {
  //                if (strncmp(name, "call", 4) == 0)
  //                    asPackedAddress = true;
  //            }
  //
  //            if (asPackedAddress)
  //                printf("%05x ", _packedAddressFactor * _operands[i]);
  //            else
  //                printf("#%04x ", _operands[i]);
  //        }
  //        else
  //            printf("%02x<%04x> ", _operandVariables[i], _operands[i]);
  //    }
  //
  //    if (showStore)
  //        printf("-> %02x ", _store);
  //    if (showBranch)
  //    {
  //        if (_branch == 0)
  //            printf("%srfalse", _branchOnTrue ? "" : "~");
  //        else if (_branch == 1)
  //            printf("%srtrue", _branchOnTrue ? "" : "~");
  //        else
  //            printf("%s%04x",
  //                   _branchOnTrue ? "" : "~",
  //                   _pc + _instructionLength + _branch - 2);
  //    }
  //    printf("\n");
}

char *ZMProcessor::getStringBuf(size_t len) {
  if (_stringBufLen < len) {
    delete[] _stringBuf;
    _stringBuf = new char[len];
    _stringBufLen = len;
  }
  return _stringBuf;
}

void ZMProcessor::add() {
  decodeStore();
  log("add", true, false);

  setVariable(_store, static_cast<int16_t>(_operands[0]) +
                          static_cast<int16_t>(_operands[1]));
  advancePC();
}

void ZMProcessor::_and() {
  decodeStore();
  log("and", true, false);

  setVariable(_store, _operands[0] & _operands[1]);
  advancePC();
}

void ZMProcessor::buffer_mode() {
  log("buffer_mode", false, false);

  _io.setWordWrap(_operands[0] == 1);
  advancePC();
}

void ZMProcessor::call_1n() {
  log("call_1n", false, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, 0, localCount, 0xffff);
  _pc = address + 1;
}

void ZMProcessor::call_1s() {
  decodeStore();
  log("call_1s", true, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, 0, localCount, _store);
  _pc = address + 1;
}

void ZMProcessor::call_2n() {
  log("call_2n", false, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, 1, localCount, 0xffff);

  // Load arguments into locals
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);

  _pc = address + 1;
}

void ZMProcessor::call_2s() {
  decodeStore();
  log("call_2s", true, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, 1, localCount, _store);

  // Load arguments into locals
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);

  _pc = address + 1;
}

void ZMProcessor::call_vn() {
  log("call_vn", false, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, _operandCount - 1,
                   localCount, 0xffff);

  // Load argument into locals
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);

  // Change the program counter to the address of the routine's
  // first instruction
  _pc = address + 1;
}

void ZMProcessor::call_vs() {
  //
  // See section 6.4 Routine calls
  //
  decodeStore();
  log(_version < 4 ? "call" : "call_vs", true, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];

  //_stack.dump();
  _stack.pushFrame(address, _pc + _instructionLength, _operandCount - 1,
                   localCount, _store);
  //_stack.dump();

  // Load arguments/initial values into locals
  // (the initial values are only present up to version 3, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);
    else if (_version <= 3)
      _stack.setLocal(i, (_memory[address + 2 * i + 1] << 8) |
                             _memory[address + 2 * i + 2]);

  // Change the program counter to the address of the routine's
  // first instruction
  if (_version <= 3)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::call_vn2() {
  log("call_vn2", false, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(address, _pc + _instructionLength, _operandCount - 1,
                   localCount, 0xffff);

  // Load argument into locals
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);

  // Change the program counter to the address of the routine's
  // first instruction
  _pc = address + 1;
}

void ZMProcessor::call_vs2() {
  decodeStore();
  log("call_vs2", true, false);

  int address = _packedAddressFactor * _operands[0]; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];

  //_stack.dump();
  _stack.pushFrame(address, _pc + _instructionLength, _operandCount - 1,
                   localCount, _store);
  //_stack.dump();

  // Load arguments into locals
  for (int i = 0; i < localCount; ++i)
    if (i < _operandCount - 1)
      _stack.setLocal(i, _operands[i + 1]);

  // Change the program counter to the address of the routine's
  // first instruction
  _pc = address + 1;
}

void ZMProcessor::check_arg_count() {
  decodeBranch();
  log("check_arg_count", false, true);

  branchOrAdvancePC(_operands[0] <= _stack.getArgCount());
}

void ZMProcessor::clear_attr() {
  log("clear_attr", false, false);

  if (_operands[0] > 0)
    _memory.getObject(_operands[0]).setAttribute(_operands[1], false);
  advancePC();
}

void ZMProcessor::dec() {
  log("dec", false, false);

  setVariable(_operands[0], getVariable(_operands[0]) - 1);
  advancePC();
}

void ZMProcessor::dec_chk() {
  decodeBranch();
  log("dec_chk", false, true);

  setVariable(_operands[0], getVariable(_operands[0]) - 1);
  branchOrAdvancePC(static_cast<int16_t>(getVariable(_operands[0])) <
                    static_cast<int16_t>(_operands[1]));
}

void ZMProcessor::div() {
  decodeStore();
  log("div", true, false);

  // Divide by zero error?
  if (_operands[1] == 0)
    throw false;

  setVariable(_store, static_cast<int16_t>(_operands[0]) /
                          static_cast<int16_t>(_operands[1]));
  advancePC();
}

void ZMProcessor::erase_window() {
  log("erase_window", false, false);

  _io.eraseWindow(static_cast<int16_t>(_operands[0]));
  advancePC();
}

void ZMProcessor::get_child() {
  decodeStore();
  decodeBranch();
  log("get_child", true, true);

  if (_operands[0] == 0)
    branchOrAdvancePC(false);
  else {
    uint16_t child = _memory.getObject(_operands[0]).getChild();
    setVariable(_store, child);
    branchOrAdvancePC(child != 0);
  }
}

void ZMProcessor::get_next_prop() {
  decodeStore();
  log("get_next_prop", true, false);

  if (_operands[0] > 0)
    setVariable(_store,
                _memory.getObject(_operands[0]).getNextProperty(_operands[1]));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_parent() {
  decodeStore();
  log("get_parent", true, false);

  if (_operands[0] > 0)
    setVariable(_store, _memory.getObject(_operands[0]).getParent());
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop() {
  decodeStore();
  log("get_prop", true, false);

  // TESTING
  assert(_operands[1] > 0);

  if (_operands[0] > 0)
    setVariable(_store,
                _memory.getObject(_operands[0]).getProperty(_operands[1]));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop_addr() {
  decodeStore();
  log("get_prop_addr", true, false);

  // TESTING
  assert(_operands[1] > 0);
  //    if (_operands[0] > 0)
  //    {
  //        uint16_t addr =
  //        _memory.getObject(_operands[0]).getPropertyAddress(_operands[1]);
  //        printf("Property address: %04x\n", addr);
  //    }

  if (_operands[0] > 0)
    setVariable(
        _store,
        _memory.getObject(_operands[0]).getPropertyAddress(_operands[1]));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop_len() {
  decodeStore();
  log("get_prop_len", true, false);

  if (_operands[0] > 0) {
    uint16_t addr = _operands[0];
    --addr;
    if (_version >= 4 && ((_memory.getByte(addr) & 0x80) == 0x80))
      --addr;

    uint8_t size;
    uint16_t propertyAddr;
    uint16_t nextAddr;
    ZMObject::getPropertyAtAddress(_memory, addr, &size, &propertyAddr,
                                   &nextAddr);
    setVariable(_store, size);
  } else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_sibling() {
  decodeStore();
  decodeBranch();
  log("get_sibling", true, true);

  uint16_t sibling = 0;
  if (_operands[0] > 0)
    sibling = _memory.getObject(_operands[0]).getSibling();
  setVariable(_store, sibling);
  branchOrAdvancePC(sibling != 0);
}

void ZMProcessor::inc() {
  log("inc", false, false);

  setVariable(_operands[0], getVariable(_operands[0]) + 1);
  advancePC();
}

void ZMProcessor::inc_chk() {
  decodeBranch();
  log("inc_chk", false, true);

  setVariable(_operands[0], getVariable(_operands[0]) + 1);
  branchOrAdvancePC(static_cast<int16_t>(getVariable(_operands[0])) >
                    static_cast<uint16_t>(_operands[1]));
}

void ZMProcessor::insert_obj() {
  log("insert_obj", false, false);

  if (_operands[0] > 0) {
    ZMObject &obj = _memory.getObject(_operands[0]);
    if (_operands[1] > 0) {
      ZMObject &dest = _memory.getObject(_operands[1]);
      printf("Insert object: %s -> %s\n", obj.getShortName().c_str(),
             dest.getShortName().c_str());

      obj.insert(_operands[1]);
    }
  }
  advancePC();
}

void ZMProcessor::je() {
  decodeBranch();
  log("je", false, true);

  bool anyEqual = false;
  for (int i = 1; i < _operandCount; ++i)
    if (_operands[0] == _operands[i]) {
      anyEqual = true;
      break;
    }

  branchOrAdvancePC(anyEqual);
}

void ZMProcessor::jg() {
  decodeBranch();
  log("jg", false, true);

  if (_operandCount == 2)
    branchOrAdvancePC(static_cast<int16_t>(_operands[0]) >
                      static_cast<int16_t>(_operands[1]));
  else
    advancePC();
}

void ZMProcessor::jin() {
  decodeBranch();
  log("jin", false, true);

  if (_operands[0] > 0)
    branchOrAdvancePC(_memory.getObject(_operands[0]).getParent() ==
                      _operands[1]);
  else
    branchOrAdvancePC(false);
}

void ZMProcessor::jl() {
  decodeBranch();
  log("jl", false, true);

  if (_operandCount == 2)
    branchOrAdvancePC(static_cast<int16_t>(_operands[0]) <
                      static_cast<int16_t>(_operands[1]));
  else
    advancePC();
}

void ZMProcessor::jump() {
  log("jump", false, false);

  _pc = _pc + static_cast<int16_t>(_operands[0]) + 1;
}

void ZMProcessor::jz() {
  decodeBranch();
  log("jz", false, true);

  if (_operandCount == 1)
    branchOrAdvancePC(_operands[0] == 0);
  else
    advancePC();
}

void ZMProcessor::load() {
  decodeStore();
  log("load", true, false);

  setVariable(_store, getVariable(_operands[0]));
  advancePC();
}

void ZMProcessor::loadb() {
  decodeStore();
  log("loadb", true, false);

  // Load variable with word from array at operand0 indexed by operand1
  setVariable(_store, _memory.getByte(_operands[0] + _operands[1]));
  advancePC();
}

void ZMProcessor::loadw() {
  decodeStore();
  log("loadw", true, false);

  // Load variable with word from array at operand0 indexed by operand1
  setVariable(_store, _memory.getWord(_operands[0] + 2 * _operands[1]));
  advancePC();
}

void ZMProcessor::mod() {
  decodeStore();
  log("mod", true, false);

  setVariable(_store, static_cast<int16_t>(_operands[0]) %
                          static_cast<int16_t>(_operands[1]));
  advancePC();
}

void ZMProcessor::mul() {
  decodeStore();
  log("mul", true, false);

  setVariable(_store, static_cast<int16_t>(_operands[0]) *
                          static_cast<int16_t>(_operands[1]));
  advancePC();
}

void ZMProcessor::new_line() {
  log("new_line", false, false);

  _io.newLine();
  advancePC();
}

void ZMProcessor::nop() {
  log("nop", false, false);

  advancePC();
}

void ZMProcessor::_or() {
  decodeStore();
  log("or", true, false);

  setVariable(_store, _operands[0] | _operands[1]);
  advancePC();
}

void ZMProcessor::output_stream() {
  log("output_stream", false, false);

  int16_t number = static_cast<int16_t>(_operands[0]);
  _io.outputStream(number);
  if (number > 0) {
    if (number == 3) {
      ++_redirectIndex;
      _redirectAddr[_redirectIndex] = _operands[1];
    }
  } else if (number < 0) {
    if (number == -3) {
      --_redirectIndex;
    }
  }

  advancePC();
}

void ZMProcessor::pop() {
  log("pop", false, false);

  _stack.pop();
  advancePC();
}

void ZMProcessor::print() {
  log("print", false, false);

  ZMText text(_memory.getData());
  size_t len = text.getDecodedLength(_pc + 1) + 1;
  char *str = getStringBuf(len);
  size_t encLen = text.getString(_pc + 1, str, len);
  print(str);

  // Advance by the length of the text
  _pc += encLen + 1;
}

void ZMProcessor::print_addr() {
  log("print_addr", false, false);

  assert(_operands[0] > 1);

  ZMText text(_memory.getData());
  size_t len = text.getDecodedLength(_operands[0]) + 1;
  char *str = getStringBuf(len);
  text.getString(_operands[0], str, len);
  print(str);

  advancePC();
}

void ZMProcessor::print_char() {
  log("print_char", false, false);

  char str[2];
  str[0] = static_cast<char>(_operands[0]);
  str[1] = 0;
  print(str);
  advancePC();
}

void ZMProcessor::print_num() {
  log("print_num", false, false);

  print(static_cast<int16_t>(_operands[0]));
  advancePC();
}

void ZMProcessor::print_obj() {
  log("print_obj", false, false);

  if (_operands[0] > 0) {
    ZMObject &obj = _memory.getObject(_operands[0]);
    print(obj.getShortName().c_str());
  }
  advancePC();
}

void ZMProcessor::print_paddr() {
  log("print_paddr", false, false);

  assert(_operands[0] > 1);

  ZMText text(_memory.getData());
  size_t len = text.getDecodedLength(_packedAddressFactor * _operands[0]) + 1;
  char *str = getStringBuf(len);
  text.getString(_packedAddressFactor * _operands[0], str, len);
  print(str);

  advancePC();
}

void ZMProcessor::print_ret() {
  log("print_ret", false, false);

  ZMText text(_memory.getData());
  size_t len = text.getDecodedLength(_pc + 1) + 1;
  char *str = getStringBuf(len);
  text.getString(_pc + 1, str, len);
  print(str);
  print("\r");

  // Return and set true
  _pc = _stack.popFrame(&_store);
  setVariable(_store, 1);
}

void ZMProcessor::pull() {
  log("pull", false, false);

  setVariable(_operands[0], _stack.pop());
  advancePC();
}

void ZMProcessor::push() {
  log("push", false, false);

  _stack.push(_operands[0]);
  advancePC();
}

void ZMProcessor::put_prop() {
  log("put_prop", false, false);

  if (_operands[0] > 0)
    _memory.getObject(_operands[0]).setProperty(_operands[1], _operands[2]);
  advancePC();
}

void ZMProcessor::quit() {
  log("quit", false, false);

  _hasHalted = true;
  _hasQuit = true;
  advancePC();
}

void ZMProcessor::random() {
  decodeStore();
  log("random", true, false);

  int16_t value = static_cast<int16_t>(_operands[0]);
  if (value < 0) {
    // Seed the random number generator with |value|
    _seed = static_cast<uint16_t>(-value);
    if (_seed >= 1000)
      srandom(_seed);
    _lastRandomNumber = 0;
  } else if (value == 0) {
    // Randomly seed the random number generator
    // TODO: seed with milliseconds
    _seed = 0xbaad;
    srandom(_seed);
    _lastRandomNumber = 0;
  } else {
    // Generate a random number between 0 and value
    if (_seed == 0) {
      _lastRandomNumber = ::random() % value + 1;
    } else if (_seed < 1000) {
      ++_lastRandomNumber;
      if ((_lastRandomNumber >= _seed) || (_lastRandomNumber >= value))
        _lastRandomNumber = 1;
    } else {
      _lastRandomNumber = ::random() % value + 1;
    }
  }

  //  printf("Random number: %d (%d)\n", _lastRandomNumber, _seed);

  setVariable(_store, _lastRandomNumber);
  advancePC();
}

void ZMProcessor::sread() {
  log("sread", false, false);

  if (_version <= 3)
    _io.showStatus();

  size_t maxLen = _memory.getByte(_operands[0]);
  char *textBuf =
      reinterpret_cast<char *>(_memory.getData()) + _operands[0] + 1;
  size_t len = _io.input(textBuf, maxLen);

  // If there is nothing in the input buffer, halt so that input can be made
  if (len == 0) {
    _hasHalted = true;
    return;
  }

  // Convert the text to lower case
  for (unsigned int i = 0; i < len; ++i)
    textBuf[i] = tolower(textBuf[i]);

  //_io.newLine();
  _memory.getDictionary().lex(_operands[0], _operands[1]);
  advancePC();
}

void ZMProcessor::aread() {
  decodeStore();
  log("aread", true, false);

  size_t maxLen = _memory.getByte(_operands[0]);
  size_t len = _io.input(
      reinterpret_cast<char *>(_memory.getData()) + _operands[0] + 2, maxLen);
  //_io.newLine();

  // If there is nothing in the input buffer, halt so that input can be made
  if (len == 0) {
    _hasHalted = true;
    return;
  }

  // Put the character count into byte 1
  _memory.setByte(_operands[0] + 1, len);
  if (_operandTypes[1] != kOmitted && _operands[1] != 0)
    _memory.getDictionary().lex(_operands[0], _operands[1]);
  setVariable(_store, 10);
  advancePC();
}

void ZMProcessor::read_char() {
  decodeStore();
  log("read_char", true, false);

  char c = _io.inputChar();

  // If there is nothing in the input buffer, halt so that input can be made
  if (c == 0) {
    _hasHalted = true;
    return;
  }

  setVariable(_store, c);
  advancePC();
}

void ZMProcessor::remove_obj() {
  log("remove_obj", false, false);

  if (_operands[0] > 0)
    _memory.getObject(_operands[0]).remove();
  advancePC();
}

void ZMProcessor::restart() {
  log("restart", false, false);

  printf("WARNING: RESTART NOT YET IMPLEMENTED\n");

  advancePC();
}

void ZMProcessor::restore() {
  decodeBranch();
  log("restore", false, true);

  _io.restore(0, 0);

  printf("WARNING: RESTORE NOT YET IMPLEMENTED\n");

  advancePC();
}

void ZMProcessor::ret() {
  log("ret", false, false);

  _pc = _stack.popFrame(&_store);
  setVariable(_store, _operands[0]);
}

void ZMProcessor::ret_popped() {
  log("ret_popped", false, false);

  int r = _stack.pop();
  _pc = _stack.popFrame(&_store);
  setVariable(_store, r);
}

void ZMProcessor::rfalse() {
  log("rfalse", false, false);

  _pc = _stack.popFrame(&_store);
  setVariable(_store, 0);
}

void ZMProcessor::rtrue() {
  log("rtrue", false, false);

  _pc = _stack.popFrame(&_store);
  setVariable(_store, 1);
}

void ZMProcessor::save() {
  if (_version < 4) {
    decodeBranch();
    log("save", false, true);
  } else {
    decodeStore();
    log("save", true, false);
  }

  if (!_continuingAfterHalt) {
    uint8_t *cmemBuf;
    size_t cmemLen;
    _memory.createCMemChunk(&cmemBuf, &cmemLen);

    uint8_t *stksBuf;
    size_t stksLen;
    _stack.createStksChunk(&stksBuf, &stksLen);

    uint8_t *ihhdBuf;
    size_t ifhdLen;
    _memory.createIFhdChunk(&ihhdBuf, &ifhdLen, _pc + _operandOffset);

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

    _io.save(handle.data, handle.pos);

    IFFCloseBuffer(&handle);

    delete[] ihhdBuf;
    delete[] stksBuf;
    delete[] cmemBuf;

    _hasHalted = true;
    return;
  }

  uint16_t saveResult = _io.getRestoreOrSaveResult();

  if (_version < 4)
    branchOrAdvancePC(saveResult != 0);
  else {
    setVariable(_store, saveResult);
    advancePC();
  }
}

void ZMProcessor::save_undo() {
  decodeStore();
  log("save_undo", true, false);

  // setVariable(_store, 0xffff);
  setVariable(_store, 1);
  printf("WARNING: SAVE UNDO NOT YET IMPLEMENTED\n");

  advancePC();
}

void ZMProcessor::set_attr() {
  log("set_attr", false, false);

  if (_operands[0] > 0)
    _memory.getObject(_operands[0]).setAttribute(_operands[1], true);
  advancePC();
}

void ZMProcessor::set_colour() {
  log("set_colour", false, false);

  _io.setColor(_operands[0], _operands[1]);
  advancePC();
}

void ZMProcessor::set_cursor() {
  log("set_cursor", false, false);

  _io.setCursor(_operands[0], _operands[1]);
  advancePC();
}

void ZMProcessor::set_font() {
  decodeStore();
  log("set_font", true, false);

  int result = _io.setFont(_operands[0]);
  setVariable(_store, result);
  advancePC();
}

void ZMProcessor::set_text_style() {
  log("set_text_style", false, false);

  _io.setTextStyle(_operands[0]);
  advancePC();
}

void ZMProcessor::set_window() {
  log("set_window", false, false);

  _io.setWindow(_operands[0]);
  advancePC();
}

void ZMProcessor::show_status() {
  log("show_status", false, false);

  if (_version == 3)
    _io.showStatus();
  advancePC();
}

void ZMProcessor::split_window() {
  log("split_window", false, false);

  _io.splitWindow(_operands[0]);
  advancePC();
}

void ZMProcessor::store() {
  log("store", false, false);

  setVariable(_operands[0], _operands[1]);
  advancePC();
}

void ZMProcessor::storeb() {
  log("storeb", false, false);

  // Store operand2 in array operand0 indexed by operand1
  _memory.setByte(_operands[0] + _operands[1], _operands[2]);
  advancePC();
}

void ZMProcessor::storew() {
  log("storew", false, false);

  // Store operand2 in array operand0 indexed by operand1
  _memory.setWord(_operands[0] + 2 * _operands[1], _operands[2]);
  advancePC();
}

void ZMProcessor::sub() {
  decodeStore();
  log("sub", true, false);

  setVariable(_store, static_cast<int16_t>(_operands[0]) -
                          static_cast<int16_t>(_operands[1]));
  advancePC();
}

void ZMProcessor::test() {
  decodeBranch();
  log("test", false, true);

  branchOrAdvancePC((_operands[0] & _operands[1]) == _operands[1]);
}

void ZMProcessor::test_attr() {
  decodeBranch();
  log("test_attr", false, true);

  if (_operands[0] == 0)
    branchOrAdvancePC(false);
  else
    branchOrAdvancePC(
        _memory.getObject(_operands[0]).getAttribute(_operands[1]));
}

void ZMProcessor::tokenise() {
  log("tokenise", false, false);

  if (_operandCount > 2)
    printf(
        "WARNING: tokenise with more that two operands NOT YET IMPLEMENTED\n");

  _memory.getDictionary().lex(_operands[0], _operands[1]);
  advancePC();
}

void ZMProcessor::_verify() {
  decodeBranch();
  log("verify", false, true);

  printf("WARNING: VERIFY NOT YET IMPLEMENTED\n");

  advancePC();
}
