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
#include "ZMQuetzal.h"
#include "ZMStack.h"
#include "ZMText.h"
#include <assert.h>
#include <chrono>
#include <cstdio>
#include <cstring>

ZMProcessor::ZMProcessor(ZMMemory &memory, ZMStack &stack, ZMIO &io,
                         ZMError &error, ZMQuetzal &quetzal)
    : _memory(memory), _stack(stack), _io(io), _error(error), _quetzal(quetzal),
      _pc(0), _initialPC(0), _operandOffset(0), _instructionLength(0),
      _operandCount(0), _operandTypes(), _store(0), _branch(0),
      _branchOnTrue(false), _seed(0), _lastRandomNumber(0), _version(0),
      _packedAddressFactor(0), _redirect(), _hasQuit(false), _hasHalted(false),
      _continuingAfterHalt(false) {

  // Take a copy of the initial PC, as the standard prohibits any changes to the
  // header having an effect when using `restart`
  _initialPC = _memory.getHeader().getInitialProgramCounter();
  _pc = _initialPC;

  // If this is not a version 6 story, push a dummy frame onto the stack
  // From the Quetzal spec (Section 4.11):
  // In Z-machine versions other than V6 execution starts at an address rather
  // than at a routine, and therefore data can be pushed on the evaluation stack
  // without anything being on the call stack. Therefore, in all versions other
  // than V6 a dummy stack frame must be stored as the first in the file (the
  // oldest chunk).
  if (_memory.getHeader().getVersion() != 6)
    _stack.pushFrame(0, 0, 0, 0);

  // Seed the random number generator
  using namespace std::chrono;
  _seed = duration_cast<milliseconds>(system_clock::now().time_since_epoch())
              .count();
  srandom(_seed);
}

bool ZMProcessor::execute() {
  // Lazy initialisation
  if (_version != _memory.getHeader().getVersion()) {
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

  //  // Calculate checksum on the high memory
  //  uint32_t checksum = 0;
  //  for (uint32_t i = _memory.getHeader().getBaseHighMemory(); i <
  //  _memory.getHeader().getFileLength(); ++i)
  //    checksum += _memory[i];
  //
  //  if (_lastChecksum && _lastChecksum != checksum) {
  //    int foo = 0;
  //  }
  //  _lastChecksum = checksum;

  //  printf("%05x\n", _pc);
  //  if (_pc == 0xfe7d) {
  //    int foo = 0;
  //  }

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

bool ZMProcessor::callRoutine(int routine) {

  // Called by timers while waiting for input, therefore processor
  // must be halted
  if (!_hasHalted || routine == 0)
    return false;

  uint32_t originalPC = _pc;
  _store = 0;                                   // store return value to stack
  int address = _packedAddressFactor * routine; // Packed address
  uint16_t localCount = _memory[address];

  // Set a return address of 0, and then execute until the PC is
  // set to 0
  _stack.pushFrame(0, 0, localCount, _store);
  _pc = address + 1;
  while (_pc != 0 && execute())
    ;

  _pc = originalPC;
  return getVariable(_store);
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
  _operandCount = 2;
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

  // Calculate operand count and instruction length
  if (_operandTypes[0] != kOmitted) {
    _operandCount = 1;
    if (_operandTypes[0] == kLargeConstant) {
      _instructionLength += 2;
    } else if (_operandTypes[0] == kSmallConstant) {
      ++_instructionLength;
    } else if (_operandTypes[0] == kVariable) {
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
  int operandFieldCount;

  _operandOffset = 3;

  // 4 2-bit fields, specifying operand types (4.4.3)
  uint8_t operandTypeFields = _memory[_pc + 2];
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

  // Calculate operand count and instruction length
  // (4.4.3)
  _operandCount = 0;
  for (int i = 0; i < operandFieldCount; ++i) {
    if (_operandTypes[i] == kOmitted)
      break;
    else if (_operandTypes[i] == kLargeConstant) {
      _instructionLength += 2;
    } else if (_operandTypes[i] == kSmallConstant) {
      ++_instructionLength;
    } else if (_operandTypes[i] == kVariable) {
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
  int operandFieldCount;

  _operandOffset = 2;

  // 4 2-bit fields, specifying operand types (4.4.3)
  uint8_t operandTypeFields = _memory[_pc + 1];
  _operandTypes[0] = operandType(operandTypeFields >> 6);
  _operandTypes[1] = operandType(operandTypeFields >> 4);
  _operandTypes[2] = operandType(operandTypeFields >> 2);
  _operandTypes[3] = operandType(operandTypeFields);

  if (operands == 2) {
    _instructionLength = 2;
    operandFieldCount = 4;
  } else if (_version >= 4 && (opCode == 0x0c || opCode == 0x1a)) {
    ++_operandOffset;
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

  // Calculate operand count and instruction length
  _operandCount = 0;
  for (int i = 0; i < operandFieldCount; ++i) {
    if (_operandTypes[i] == kOmitted)
      break;
    else if (_operandTypes[i] == kLargeConstant) {
      _instructionLength += 2;
    } else if (_operandTypes[i] == kSmallConstant) {
      ++_instructionLength;
    } else if (_operandTypes[i] == kVariable) {
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
    if (_version >= 5)
      _catch();
    else
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
  case 0x0f:
    piracy();
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: 0OP:%x (%x)\n", _pc, opCode,
             _memory[_pc]);
    _error.error(msg);

    printf("Quitting on: %05x: 0OP:%x (%x)\n", _pc, opCode, _memory[_pc]);
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
    if (_version >= 5)
      call_1n();
    else
      _not();
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: 1OP:%d (%x)\n", _pc, _memory[_pc],
             opCode);
    _error.error(msg);

    printf("Quitting on: %05x: 1OP:%d (%x)\n", _pc, _memory[_pc], opCode);
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
  case 0x1c:
    _throw(); // v5
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: 2OP:%d (%x)\n", _pc, _memory[_pc],
             opCode);
    _error.error(msg);

    printf("Quitting on: %05x: 2OP:%d (%x)\n", _pc, _memory[_pc], opCode);
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
  case 0x0e:
    erase_line(); // v4
    break;
  case 0x0f:
    set_cursor(); // v4
    break;
  case 0x10:
    get_cursor(); // v4
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
  case 0x14:
    input_stream(); // v3
    break;
  case 0x15:
    sound_effect(); // v5/3
    break;
  case 0x16:
    read_char(); // v4
    break;
  case 0x17:
    scan_table(); // v4
    break;
  case 0x18:
    _not(); // v5
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
  case 0x1c:
    encode_text(); // v5
    break;
  case 0x1d:
    copy_table(); // v5
    break;
  case 0x1e:
    print_table(); // v5
    break;
  case 0x1f:
    check_arg_count(); // v5
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: VAR:%d (%x)\n", _pc, _memory[_pc],
             opCode);
    _error.error(msg);

    printf("Quitting on: %05x: VAR:%d (%x)\n", _pc, _memory[_pc], opCode);
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
    save_ext();
    break;
  case 0x01:
    restore_ext();
    break;
  case 0x02:
    log_shift();
    break;
  case 0x03:
    art_shift();
    break;
  case 0x04:
    set_font();
    break;
  case 0x09:
    save_undo();
    break;
  case 0x0a:
    restore_undo();
    break;
  case 0x0b:
    print_unicode();
    break;
  case 0x0c:
    check_unicode();
    break;
  case 0x0d:
    set_true_colour();
    break;
  default: {
    char msg[256];
    snprintf(msg, 256, "Quitting on: %05x: EXT:%d (%x)\n", _pc,
             _memory[_pc + 1], opCode);
    _error.error(msg);

    printf("Quitting on: %05x: EXT:%d (%x)\n", _pc, _memory[_pc + 1], opCode);
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

uint16_t ZMProcessor::getOperand(int index, bool noPop) {
  if (index >= _operandCount)
    return 0;

  // Calculate offset
  int offset = 0;
  for (int i = 0; i < index; ++i) {
    if (_operandTypes[i] == kOmitted)
      continue;
    else if (_operandTypes[i] == kLargeConstant)
      offset += 2;
    else if (_operandTypes[i] == kSmallConstant)
      ++offset;
    else if (_operandTypes[i] == kVariable)
      ++offset;
  }

  switch (_operandTypes[index]) {
  case kLargeConstant:
    return _memory.getWord(_pc + _operandOffset + offset);
  case kSmallConstant:
    return _memory[_pc + _operandOffset + offset];
  case kVariable:
    return getVariable(_memory[_pc + _operandOffset + offset], noPop);
  case kOmitted:
    return 0;
  }
}

uint16_t ZMProcessor::getVariable(int index, bool noPop) {
  if (index == 0) {
    if (noPop)
      return _stack.getTop();
    else
      return _stack.pop();
  } else if (index < 0x10)
    return _stack.getLocal(index - 1);
  else
    return _memory.getGlobal(index - 0x10);
}

void ZMProcessor::setVariable(int index, uint16_t value, bool noPush) {
  // We use 0xffff as a value on the stack meaning to throw away the
  // returned result
  if (index == 0xffff)
    return;
  else if (index == 0) {
    if (noPush)
      _stack.setTop(value);
    else
      _stack.push(value);
  } else if (index < 0x10)
    _stack.setLocal(index - 1, value);
  else
    _memory.setGlobal(index - 0x10, value);
}

void ZMProcessor::advancePC() { _pc += _instructionLength; }

void ZMProcessor::branchOrAdvancePC(bool testResult) {
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

void ZMProcessor::print(std::string str, bool caratNewLine) {
  //  printf(">%s<\n", str.c_str());
  if (caratNewLine)
    std::transform(str.begin(), str.end(), str.begin(),
                   [](char c) -> char { return c == '^' ? '\n' : c; });

  if (_redirect.empty())
    _io.print(str);
  else
    _redirect.back().second.append(str);
}

void ZMProcessor::print(int16_t number) {
  if (_redirect.empty())
    _io.printNumber(number);
  else {
    _redirect.back().second.append(std::to_string(number));
  }
}

void ZMProcessor::log(const char *name, bool showStore, bool showBranch) {}

void ZMProcessor::add() {
  decodeStore();
  log("add", true, false);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  setVariable(_store, a + b);
  advancePC();
}

void ZMProcessor::_and() {
  decodeStore();
  log("and", true, false);

  uint16_t a = getOperand(0);
  uint16_t b = getOperand(1);
  setVariable(_store, a & b);
  advancePC();
}

void ZMProcessor::art_shift() {
  decodeStore();
  log("art_shift", true, false);

  int16_t number = static_cast<int16_t>(getOperand(0));
  int16_t places = static_cast<int16_t>(getOperand(1));
  if (places < 0)
    setVariable(_store, static_cast<int16_t>(number >> -places));
  else
    setVariable(_store, static_cast<int16_t>(number << places));
  advancePC();
}

void ZMProcessor::buffer_mode() {
  log("buffer_mode", false, false);

  uint16_t flag = getOperand(0);
  _io.setWordWrap(flag == 1);
  advancePC();
}

void ZMProcessor::call_1n() {
  log("call_1n", false, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, 0, localCount, 0xffff);
  _pc = address + 1;
}

void ZMProcessor::call_1s() {
  decodeStore();
  log("call_1s", true, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, 0, localCount, _store);

  // Load initial values into locals
  // (the initial values are only present up to version 4, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  if (_version <= 4)
    for (int i = 0; i < localCount; ++i)
      _stack.setLocal(i, _memory.getWord(address + 2 * i + 1));

  if (_version <= 4)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::call_2n() {
  log("call_2n", false, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, 1, localCount, 0xffff);

  // Load arguments into locals
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);

  _pc = address + 1;
}

void ZMProcessor::call_2s() {
  decodeStore();
  log("call_2s", true, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, 1, localCount, _store);

  // Load arguments/initial values into locals
  // (the initial values are only present up to version 4, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);
    else if (_version <= 4)
      _stack.setLocal(i, _memory.getWord(address + 2 * i + 1));

  if (_version <= 4)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::call_vn() {
  log("call_vn", false, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, argCount, localCount, 0xffff);

  // Load arguments/initial values into locals
  // (the initial values are only present up to version 4, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);
    else if (_version <= 4)
      _stack.setLocal(i, _memory.getWord(address + 2 * i + 1));

  // Change the program counter to the address of the routine's
  // first instruction
  if (_version <= 4)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::call_vs() {
  //
  // See section 6.4 Routine calls
  //
  decodeStore();
  log(_version < 4 ? "call" : "call_vs", true, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, argCount, localCount, _store);

  // Load arguments/initial values into locals
  // (the initial values are only present up to version 4, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);
    else if (_version <= 4)
      _stack.setLocal(i, _memory.getWord(address + 2 * i + 1));

  // Change the program counter to the address of the routine's
  // first instruction
  if (_version <= 4)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::call_vn2() {
  log("call_vn2", false, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, argCount, localCount, 0xffff);

  // Load argument into locals
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);

  // Change the program counter to the address of the routine's
  // first instruction
  _pc = address + 1;
}

void ZMProcessor::call_vs2() {
  decodeStore();
  log("call_vs2", true, false);

  uint16_t routine = getOperand(0);
  int address = _packedAddressFactor * routine; // Packed address

  // Check if this is a call to zero
  if (address == 0) {
    // Return false
    setVariable(_store, 0);
    advancePC();
    return;
  }

  int argCount = _operandCount - 1;
  uint16_t args[8];
  for (int i = 0; i < argCount; ++i)
    args[i] = getOperand(i + 1);

  uint16_t localCount = _memory[address];
  _stack.pushFrame(_pc + _instructionLength, argCount, localCount, _store);

  // Load arguments/initial values into locals
  // (the initial values are only present up to version 4, and the stack
  // initialises the values to zero during the 'pushFrame' above)
  for (int i = 0; i < localCount; ++i)
    if (i < argCount)
      _stack.setLocal(i, args[i]);
    else if (_version <= 4)
      _stack.setLocal(i, _memory.getWord(address + 2 * i + 1));

  // Change the program counter to the address of the routine's
  // first instruction
  if (_version <= 4)
    _pc = address + 2 * localCount + 1;
  else
    _pc = address + 1;
}

void ZMProcessor::_catch() {
  decodeStore();
  log("catch", true, false);

  setVariable(_store, _stack.catchFrame());
  advancePC();
}

void ZMProcessor::check_arg_count() {
  decodeBranch();
  log("check_arg_count", false, true);

  uint16_t argument_number = getOperand(0);
  branchOrAdvancePC(argument_number <= _stack.getArgCount());
}

void ZMProcessor::check_unicode() {
  decodeStore();
  log("check_unicode", true, false);

  uint16_t char_number = getOperand(0);
  bool printable = _io.checkUnicode(char_number);
  ZMText text(_memory.getData());
  bool receivable = text.receivableChar(char_number);
  uint16_t setting = (printable ? 0x01 : 0x00) | (receivable ? 0x02 : 0x00);
  setVariable(_store, setting);
  advancePC();
}

void ZMProcessor::clear_attr() {
  log("clear_attr", false, false);

  uint16_t object = getOperand(0);
  uint16_t attribute = getOperand(1);
  if (object > 0)
    _memory.getObject(object).setAttribute(attribute, false);
  advancePC();
}

void ZMProcessor::copy_table() {
  log("copy_table", false, false);

  uint16_t first = getOperand(0);
  uint16_t second = getOperand(1);
  int16_t size = static_cast<int16_t>(getOperand(2));
  if (second == 0)
    memset(_memory.getData(first), 0, size);
  else if (size >= 0)
    memmove(_memory.getData(second), _memory.getData() + first, size);
  else
    for (int16_t i = 0; i < -size; i++)
      _memory.setByte(second + i, _memory.getByte(first + i));

  //  printf("%x copy_table from: %x to: %x\n", _pc, first, second);
  //  if (second > 0) {
  //    for (int i = 0; i < size; ++i) {
  //      char c = _memory.getByte(second + i);
  //      if (c >= 32)
  //        printf("%c", c);
  //      else
  //        printf("[%d]", c);
  //    }
  //  }
  //  printf("\n");

  advancePC();
}

void ZMProcessor::dec() {
  log("dec", false, false);

  uint16_t variable = getOperand(0);
  setVariable(variable, getVariable(variable) - 1);
  advancePC();
}

void ZMProcessor::dec_chk() {
  decodeBranch();
  log("dec_chk", false, true);

  uint16_t variable = getOperand(0);
  uint16_t value = getOperand(1);
  setVariable(variable, getVariable(variable) - 1);
  branchOrAdvancePC(static_cast<int16_t>(getVariable(variable, true)) <
                    static_cast<int16_t>(value));
}

void ZMProcessor::div() {
  decodeStore();
  log("div", true, false);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));

  // Divide by zero error?
  if (b == 0)
    throw false;

  setVariable(_store, a / b);
  advancePC();
}

void ZMProcessor::encode_text() {
  log("encode_text", false, false);

  uint16_t zsciiText = getOperand(0);
  uint16_t length = getOperand(1);
  uint16_t from = getOperand(2);
  uint16_t codedText = getOperand(3);
  const char *zsciiTextBuffer =
      reinterpret_cast<const char *>(_memory.getData() + zsciiText);
  uint8_t *codedTextBuffer = _memory.getData(codedText);
  ZMText text(_memory.getData());
  text.encode(codedTextBuffer, zsciiTextBuffer + from, length, 6);
  advancePC();
}

void ZMProcessor::erase_line() {
  log("erase_window", false, false);

  uint16_t value = getOperand(0);
  if (value == 1)
    _io.eraseLine();
  advancePC();
}

void ZMProcessor::erase_window() {
  log("erase_window", false, false);

  int16_t window = static_cast<int16_t>(getOperand(0));
  _io.eraseWindow(window);
  advancePC();
}

void ZMProcessor::get_child() {
  decodeStore();
  decodeBranch();
  log("get_child", true, true);

  uint16_t object = getOperand(0);
  if (object == 0)
    branchOrAdvancePC(false);
  else {
    uint16_t child = _memory.getObject(object).getChild();
    setVariable(_store, child);
    branchOrAdvancePC(child != 0);
  }
}

void ZMProcessor::get_cursor() {
  log("get_cursor", false, false);

  uint16_t array = getOperand(0);
  int line;
  int column;
  _io.getCursor(line, column);
  _memory.setWord(array, line);
  _memory.setWord(array + 2, column);
  advancePC();
}

void ZMProcessor::get_next_prop() {
  decodeStore();
  log("get_next_prop", true, false);

  uint16_t object = getOperand(0);
  uint16_t property = getOperand(1);
  if (object > 0)
    setVariable(_store, _memory.getObject(object).getNextProperty(property));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_parent() {
  decodeStore();
  log("get_parent", true, false);

  uint16_t object = getOperand(0);
  if (object > 0)
    setVariable(_store, _memory.getObject(object).getParent());
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop() {
  decodeStore();
  log("get_prop", true, false);

  uint16_t object = getOperand(0);
  uint16_t property = getOperand(1);

  // TESTING
  assert(property > 0);

  if (object > 0)
    setVariable(_store, _memory.getObject(object).getProperty(property));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop_addr() {
  decodeStore();
  log("get_prop_addr", true, false);

  uint16_t object = getOperand(0);
  uint16_t property = getOperand(1);
  if (object > 0)
    setVariable(_store, _memory.getObject(object).getPropertyAddress(property));
  else
    setVariable(_store, 0);
  advancePC();
}

void ZMProcessor::get_prop_len() {
  decodeStore();
  log("get_prop_len", true, false);

  uint16_t property_address = getOperand(0);
  if (property_address > 0) {
    uint16_t addr = property_address;
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

  uint16_t object = getOperand(0);
  uint16_t sibling = 0;
  if (object > 0)
    sibling = _memory.getObject(object).getSibling();
  setVariable(_store, sibling);
  branchOrAdvancePC(sibling != 0);
}

void ZMProcessor::inc() {
  log("inc", false, false);

  uint16_t variable = getOperand(0);
  setVariable(variable, getVariable(variable) + 1);
  advancePC();
}

void ZMProcessor::inc_chk() {
  decodeBranch();
  log("inc_chk", false, true);

  uint16_t variable = getOperand(0);
  uint16_t value = getOperand(1);
  setVariable(variable, getVariable(variable) + 1);
  branchOrAdvancePC(static_cast<int16_t>(getVariable(variable, true)) >
                    static_cast<int16_t>(value));
}

void ZMProcessor::input_stream() {
  log("input_stream", false, false);

  uint16_t number = getOperand(0, true);

  if (number == 1 && !_continuingAfterHalt) {
    _hasHalted = true;
    _io.inputStream(number);
    return;
  }

  // We've already dealt with the number, but we do this here
  // to pop any potential arguments from the stack
  number = getOperand(0);

  advancePC();
}

void ZMProcessor::insert_obj() {
  log("insert_obj", false, false);

  uint16_t object = getOperand(0);
  uint16_t destination = getOperand(1);
  if (object > 0) {
    ZMObject &obj = _memory.getObject(object);
    if (destination > 0)
      obj.insert(destination);
  }
  advancePC();
}

void ZMProcessor::je() {
  decodeBranch();
  log("je", false, true);

  uint16_t a[4] = {getOperand(0), getOperand(1), getOperand(2), getOperand(3)};
  bool anyEqual = false;
  for (int i = 1; i < _operandCount; ++i)
    if (a[0] == a[i]) {
      anyEqual = true;
      break;
    }

  branchOrAdvancePC(anyEqual);
}

void ZMProcessor::jg() {
  decodeBranch();
  log("jg", false, true);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  if (_operandCount == 2)
    branchOrAdvancePC(a > b);
  else
    advancePC();
}

void ZMProcessor::jin() {
  decodeBranch();
  log("jin", false, true);

  uint16_t obj1 = getOperand(0);
  uint16_t obj2 = getOperand(1);
  if (obj1 > 0)
    branchOrAdvancePC(_memory.getObject(obj1).getParent() == obj2);
  else
    branchOrAdvancePC(obj1 == obj2);
}

void ZMProcessor::jl() {
  decodeBranch();
  log("jl", false, true);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  if (_operandCount == 2)
    branchOrAdvancePC(a < b);
  else
    advancePC();
}

void ZMProcessor::jump() {
  log("jump", false, false);

  int16_t offset = static_cast<int16_t>(getOperand(0));
  _pc = _pc + offset + 1;
}

void ZMProcessor::jz() {
  decodeBranch();
  log("jz", false, true);

  uint16_t a = getOperand(0);
  if (_operandCount == 1)
    branchOrAdvancePC(a == 0);
  else
    advancePC();
}

void ZMProcessor::load() {
  decodeStore();
  log("load", true, false);

  uint16_t variable = getOperand(0);
  bool storeIsTopOfStack = _store == 0;
  setVariable(_store, getVariable(variable, true), !storeIsTopOfStack);
  advancePC();
}

void ZMProcessor::loadb() {
  decodeStore();
  log("loadb", true, false);

  uint16_t array = getOperand(0);
  uint16_t byte_index = getOperand(1);

  // Load variable with word from array at operand0 indexed by operand1
  setVariable(_store, _memory.getByte((array + byte_index) & 0xffff));
  advancePC();
}

void ZMProcessor::loadw() {
  decodeStore();
  log("loadw", true, false);

  uint16_t array = getOperand(0);
  uint16_t word_index = getOperand(1);

  // Load variable with word from array at operand0 indexed by operand1
  setVariable(_store, _memory.getWord((array + 2 * word_index) & 0xffff));
  advancePC();
}

void ZMProcessor::log_shift() {
  decodeStore();
  log("log_shift", true, false);

  uint16_t number = getOperand(0);
  int16_t places = static_cast<int16_t>(getOperand(1));
  if (places < 0)
    setVariable(_store, static_cast<uint16_t>(number >> -places));
  else
    setVariable(_store, static_cast<uint16_t>(number << places));
  advancePC();
}

void ZMProcessor::mod() {
  decodeStore();
  log("mod", true, false);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  setVariable(_store, a % b);
  advancePC();
}

void ZMProcessor::mul() {
  decodeStore();
  log("mul", true, false);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  setVariable(_store, a * b);
  advancePC();
}

void ZMProcessor::new_line() {
  log("new_line", false, false);

  // TODO: Should we be redirecting this if printing to a buffer?
  _io.newLine();
  advancePC();
}

void ZMProcessor::_not() {
  decodeStore();
  log("or", true, false);

  uint16_t value = getOperand(0);
  setVariable(_store, ~value);
  advancePC();
}

void ZMProcessor::nop() {
  log("nop", false, false);

  advancePC();
}

void ZMProcessor::_or() {
  decodeStore();
  log("or", true, false);

  uint16_t a = getOperand(0);
  uint16_t b = getOperand(1);
  setVariable(_store, a | b);
  advancePC();
}

void ZMProcessor::output_stream() {
  log("output_stream", false, false);

  // TODO: Support for v1 and v2 transcription through the
  // setting of the header bit

  int16_t number = static_cast<int16_t>(getOperand(0, true));
  uint16_t table = getOperand(1);

  int streamNumber = number > 0 ? number : -number;
  if (streamNumber == 2 || streamNumber == 4) {
    if (!_continuingAfterHalt) {
      _hasHalted = true;
      _io.outputStream(number);
      return;
    }
  } else
    _io.outputStream(number);

  getOperand(0);
  getOperand(1);

  if (number > 0) {
    if (number == 2) {
      _memory.getHeader().setTranscriptingOn(true);
    } else if (number == 3) {
      if (_redirect.size() < 16) {
        _redirect.push_back({table, ""});
      } else {
        _hasHalted = true;
        _hasQuit = true;
        _error.error("stream 3 nesting exceeds 16 levels");
        return;
      }
    }
  } else if (number < 0) {
    if (number == -2) {
      _memory.getHeader().setTranscriptingOn(false);
    } else if (number == -3 && _redirect.size() > 0) {

      // Copy redirected stream to table
      uint16_t addr = _redirect.back().first;
      auto str = _redirect.back().second;
      _redirect.pop_back();
      size_t len = str.length();
      memcpy(_memory.getData(addr + 2), str.c_str(), len);
      _memory.setWord(addr, len);
    }
  }

  advancePC();
}

void ZMProcessor::piracy() {
  decodeBranch();
  log("piracy", false, true);

  branchOrAdvancePC(true);
}

void ZMProcessor::pop() {
  log("pop", false, false);

  _stack.pop();
  advancePC();
}

void ZMProcessor::print() {
  log("print", false, false);

  ZMText text(_memory.getData());
  size_t encLen;
  print(text.getString(_pc + 1, encLen));

  // Advance by the length of the text
  _pc += encLen + 1;
}

void ZMProcessor::print_addr() {
  log("print_addr", false, false);

  uint16_t byte_address_of_string = getOperand(0);
  assert(byte_address_of_string > 1);

  ZMText text(_memory.getData());
  print(text.getString(byte_address_of_string));

  advancePC();
}

void ZMProcessor::print_char() {
  log("print_char", false, false);

  uint16_t output_character_code = getOperand(0);
  ZMText text(_memory.getData());
  print(text.zsciiToUTF8(output_character_code), false);
  advancePC();
}

void ZMProcessor::print_num() {
  log("print_num", false, false);

  int16_t value = static_cast<int16_t>(getOperand(0));
  print(value);
  advancePC();
}

void ZMProcessor::print_obj() {
  log("print_obj", false, false);

  uint16_t object = getOperand(0);
  if (object > 0) {
    ZMObject &obj = _memory.getObject(object);
    print(obj.getShortName().c_str());
  }
  advancePC();
}

void ZMProcessor::print_paddr() {
  log("print_paddr", false, false);

  uint16_t packed_address_of_string = getOperand(0);
  assert(packed_address_of_string > 1);

  ZMText text(_memory.getData());
  print(text.getString(_packedAddressFactor * packed_address_of_string));
  advancePC();
}

void ZMProcessor::print_ret() {
  log("print_ret", false, false);

  ZMText text(_memory.getData());
  print(text.getString(_pc + 1));
  print("\r");

  // Return and set true
  _pc = _stack.popFrame(&_store);
  setVariable(_store, 1);
}

void ZMProcessor::print_table() {
  log("print_table", false, false);

  uint16_t zscii_text = getOperand(0);
  uint16_t width = getOperand(1);
  uint16_t height = 1;
  if (_operandCount > 2)
    height = getOperand(2);
  uint16_t skip = 0;
  if (_operandCount > 3)
    skip = getOperand(3);

  int line;
  int column;
  _io.getCursor(line, column);

  ZMText text(_memory.getData());
  for (int y = 0; y < height; ++y) {
    std::string str;
    uint16_t offset = zscii_text + y * (width + skip);
    for (int i = 0; i < width; ++i) {
      text.zsciiToUTF8(str, _memory.getByte(offset + i));
    }
    _io.setCursor(line, column);
    print(str);
    ++line;
  }
  advancePC();
}

void ZMProcessor::print_unicode() {
  log("print_unicode", false, false);

  uint16_t char_number = getOperand(0);
  std::string str;
  ZMText::appendAsUTF8(str, char_number);
  print(str, false);
  advancePC();
}

void ZMProcessor::pull() {
  log("pull", false, false);

  uint16_t variable = getOperand(0);
  setVariable(variable, _stack.pop(), true);
  advancePC();
}

void ZMProcessor::push() {
  log("push", false, false);

  uint16_t value = getOperand(0);
  _stack.push(value);
  advancePC();
}

void ZMProcessor::put_prop() {
  log("put_prop", false, false);

  uint16_t object = getOperand(0);
  uint16_t property = getOperand(1);
  uint16_t value = getOperand(2);
  if (object > 0)
    _memory.getObject(object).setProperty(property, value);
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

  int16_t range = static_cast<int16_t>(getOperand(0));
  if (range < 0) {
    // Seed the random number generator with |value|
    _seed = static_cast<uint16_t>(-range);

    // Section 2 Remarks suggest a predictable mode for the random number
    // generator
    // where any seed < 1000 generates predictable sequences from 1 to S
    if (_seed >= 1000)
      srandom(_seed);

    _lastRandomNumber = 0;
  } else if (range == 0) {

    // Randomly seed the random number generator
    using namespace std::chrono;
    _seed = duration_cast<milliseconds>(system_clock::now().time_since_epoch())
                .count();
    srandom(_seed);
    _lastRandomNumber = 0;
  } else {

    // Generate a random number between 0 and value
    if (_seed == 0) {
      _lastRandomNumber = ::random() % range + 1;
    } else if (_seed < 1000) {

      // The next value in a predictable sequence
      ++_lastRandomNumber;
      if ((_lastRandomNumber >= _seed) || (_lastRandomNumber >= range))
        _lastRandomNumber = 1;
    } else {
      _lastRandomNumber = ::random() % range + 1;
    }
  }

  // printf("Random number: %d (%d)\n", _lastRandomNumber, _seed);

  setVariable(_store, _lastRandomNumber);
  advancePC();
}

// -- -- VAR:228 4 1 sread text parse
void ZMProcessor::sread() {
  log("sread", false, false);

  if (_version <= 3)
    _io.showStatus();

  // Are we starting the read operation?
  if (!_continuingAfterHalt) {
    _hasHalted = true;
    _io.beginInput(0);
    return;
  }

  std::string str = _io.endInput();

  // Convert the text to lower case
  // (NOTE: This is now being done upstream, to handle localization issues)
  // std::transform(str.begin(), str.end(), str.begin(), std::tolower);

  uint16_t text = getOperand(0);
  uint16_t parse = getOperand(1);
  size_t maxLen = _memory.getByte(text);
  char *textBuf = reinterpret_cast<char *>(_memory.getData(text + 1));
  ZMText zmtext(_memory.getData());
  size_t len = zmtext.UTF8ToZscii(textBuf, str, maxLen);
  textBuf[len] = 0;

  ZMDictionary dictionary(_memory.getData());
  dictionary.lex(text, _memory.getData(parse));
  advancePC();
}

// St -- VAR:228 4 5 aread text parse time routine -> (result)
void ZMProcessor::aread() {
  decodeStore();
  log("aread", true, false);

  // Are we starting the read operation?
  if (!_continuingAfterHalt) {
    uint16_t text = getOperand(0, true);
    getOperand(1); // TODO: What if `parse` is `sp` as well?
    uint16_t time = getOperand(2);
    uint16_t routine = getOperand(3);
    _hasHalted = true;
    uint8_t existingLen = _memory.getByte(text + 1);
    _io.beginInput(existingLen);
    if (_operandCount == 4 && time && routine) {
      _io.startTimedRoutine(time, routine);
    }
    return;
  }
  _io.stopTimedRoutine();

  uint16_t text = getOperand(0);
  uint16_t parse = getOperand(1);
  getOperand(2);
  getOperand(3);
  std::string str = _io.endInput();

  // Convert the text to lower case
  // (NOTE: This is now being done upstream, to handle localization issues)
  // std::transform(str.begin(), str.end(), str.begin(), std::tolower);

  size_t maxLen = _memory.getByte(text);
  char *textBuf = reinterpret_cast<char *>(_memory.getData(text + 2));
  ZMText zmtext(_memory.getData());
  size_t len = zmtext.UTF8ToZscii(textBuf, str, maxLen);

  // Put the character count into byte 1
  _memory.setByte(text + 1, len);
  if (parse != 0) {
    ZMDictionary dictionary(_memory.getData());
    dictionary.lex(text, _memory.getData(parse));
  }
  setVariable(_store, 13);
  advancePC();
}

// St -- VAR:246 16 4 read_char 1 time routine -> (result)
void ZMProcessor::read_char() {
  decodeStore();
  log("read_char", true, false);

  // Are we starting the read operation?
  if (!_continuingAfterHalt) {
    getOperand(0);
    uint16_t time = getOperand(1);
    uint16_t routine = getOperand(2);

    _hasHalted = true;
    _io.beginInputChar();
    if (_operandCount == 3 && time && routine) {
      _io.startTimedRoutine(time, routine);
    }
    return;
  }
  _io.stopTimedRoutine();

  wchar_t wc = _io.endInputChar();
  ZMText text(_memory.getData());
  uint16_t zsciiChar = text.wcharToZscii(wc);
  setVariable(_store, zsciiChar);
  advancePC();
}

void ZMProcessor::remove_obj() {
  log("remove_obj", false, false);

  uint16_t object = getOperand(0);
  if (object > 0)
    _memory.getObject(object).remove();
  advancePC();
}

void ZMProcessor::restart() {
  log("restart", false, false);

  // Save the "transcribing to printer" and "use fixed pitch font bits
  uint16_t flags2 = _memory.getHeader().getFlags2() & 0x03;

  _memory.reset();
  _stack.reset();

  // TODO: This has become a complete hack. Get the Quetzal code
  // to take care of its own damn requirements
  if (_memory.getHeader().getVersion() != 6)
    _stack.pushFrame(0, 0, 0, 0);

  // Restore those saved bits
  _memory.getHeader().setFlags2(_memory.getHeader().getFlags2() | flags2);

  _memory.getHeader().setScreenWidth(_io.getScreenWidth());
  _memory.getHeader().setScreenHeight(_io.getScreenHeight());

  _pc = _initialPC;
}

void ZMProcessor::restore() {
  if (_version < 4) {
    decodeBranch();
    log("restore", false, true);
  } else {
    decodeStore();
    log("restore", true, false);
  }

  if (!_continuingAfterHalt) {
    _io.beginRestore();
    _hasHalted = true;
    return;
  }

  ZMQuetzal quetzal(_memory, _stack);
  uint16_t restoreResult = _io.getRestoreOrSaveResult();
  uint32_t pc = restoreResult ? quetzal.restore(_io) : _pc;

  if (_version < 4) {
    if (restoreResult == 0)
      branchOrAdvancePC(0);
    else if (restoreResult == 2)
      _pc = pc + 1;
  } else {
    if (restoreResult == 0) {
      setVariable(_store, restoreResult);
      advancePC();
    } else if (restoreResult == 2) {

      // TODO: see note below
      _pc = pc - 1;
      _instructionLength--;
      decodeStore();
      _pc = pc + 1;
      setVariable(_store, restoreResult);
    }
  }
}

void ZMProcessor::restore_ext() {
  decodeStore();
  log("restore", true, false);

  if (_operandCount > 0)
    printf(
        "WARNING: RESTORE (EXT:1) OPTIONAL PARAMETERS NOT YET IMPLEMENTED\n");

  if (!_continuingAfterHalt) {
    _io.beginRestore();
    _hasHalted = true;
    return;
  }

  ZMQuetzal quetzal(_memory, _stack);
  uint16_t restoreResult = _io.getRestoreOrSaveResult();
  uint32_t pc = restoreResult ? quetzal.restore(_io) : _pc;
  if (restoreResult == 0) {
    setVariable(_store, restoreResult);
    advancePC();
  } else if (restoreResult == 2) {

    // TODO: Fix this horrible mess. decodeStore() needs to decode the
    // store of the earlier save operation, and it is also messing with
    // the instruction length tracking
    _pc = pc - 3;
    _instructionLength--;
    decodeStore();
    _pc = pc + 1;
    setVariable(_store, restoreResult);
  }
}

void ZMProcessor::restore_undo() {
  decodeStore();
  log("restore_undo", true, false);

  uint32_t pc = _quetzal.restoreUndo();
  if (pc > 0) {
    _pc = pc - 3;
    _instructionLength--;
    decodeStore();
    _pc = pc + 1;
    setVariable(_store, 2);
  } else {
    setVariable(_store, 0);
    advancePC();
  }
}

void ZMProcessor::ret() {
  log("ret", false, false);

  uint16_t value = getOperand(0);
  _pc = _stack.popFrame(&_store);
  setVariable(_store, value);
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

  // 'save' operates in two parts. When first called, the save image is
  // generated and the processor halts, allowing the client app to store
  // the save image to disk. Execution then resumes and 'save' is called
  // again since the IP was not advanced, and 'continuingAfterHalt' will
  // be true, so this following block is skipped.
  if (!_continuingAfterHalt) {
    ZMQuetzal quetzal(_memory, _stack);
    quetzal.save(_io, _pc + _operandOffset);
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

void ZMProcessor::save_ext() {
  decodeStore();
  log("save", true, false);

  if (_operandCount > 0)
    printf("WARNING: SAVE (EXT:0) OPTIONAL PARAMETERS NOT YET IMPLEMENTED\n");

  if (!_continuingAfterHalt) {
    ZMQuetzal quetzal(_memory, _stack);
    quetzal.save(_io, _pc + _operandOffset);
    _hasHalted = true;
    return;
  }
  uint16_t saveResult = _io.getRestoreOrSaveResult();

  setVariable(_store, saveResult);
  advancePC();
}

void ZMProcessor::save_undo() {
  decodeStore();
  log("save_undo", true, false);

  _quetzal.saveUndo(_pc + _operandOffset);
  setVariable(_store, 1);
  advancePC();
}

void ZMProcessor::scan_table() {
  decodeStore();
  decodeBranch();
  log("scan_table", true, true);

  uint16_t x = getOperand(0);
  uint16_t table = getOperand(1);
  uint16_t len = getOperand(2);
  uint16_t form = 0x82;
  if (_operandCount == 4)
    form = getOperand(3);
  uint16_t fieldLength = form & 0x7f;
  bool isWord = (form & 0x80) != 0;
  uint16_t offset = table;
  bool found = false;
  for (uint16_t i = 0; i < len; ++i) {
    uint16_t read = isWord ? _memory.getWord(offset) : _memory.getByte(offset);
    if (read == x) {
      found = true;
      setVariable(_store, offset);
      break;
    }
    offset += fieldLength;
  }
  if (!found) {
    setVariable(_store, 0);
  }
  branchOrAdvancePC(found);
}

void ZMProcessor::set_attr() {
  log("set_attr", false, false);

  uint16_t object = getOperand(0);
  uint16_t attribute = getOperand(1);
  if (object > 0)
    _memory.getObject(object).setAttribute(attribute, true);
  advancePC();
}

void ZMProcessor::set_colour() {
  log("set_colour", false, false);

  uint16_t foreground = getOperand(0);
  uint16_t background = getOperand(1);
  _io.setColor(foreground, background);
  advancePC();
}

void ZMProcessor::set_cursor() {
  log("set_cursor", false, false);

  int16_t line = static_cast<int16_t>(getOperand(0));
  int16_t column = static_cast<int16_t>(getOperand(1));
  _io.setCursor(line, column);
  advancePC();
}

void ZMProcessor::set_font() {
  decodeStore();
  log("set_font", true, false);

  uint16_t font = getOperand(0);
  int result = _io.setFont(font);
  setVariable(_store, result);
  advancePC();
}

void ZMProcessor::set_text_style() {
  log("set_text_style", false, false);

  uint16_t style = getOperand(0);
  _io.setTextStyle(style);
  advancePC();
}

void ZMProcessor::set_true_colour() {
  log("set_true_colour", false, false);

  uint16_t foreground = getOperand(0);
  uint16_t background = getOperand(1);
  _io.setTrueColor(foreground, background);
  advancePC();
}

void ZMProcessor::set_window() {
  log("set_window", false, false);

  uint16_t window = getOperand(0);
  _io.setWindow(window);
  advancePC();
}

void ZMProcessor::show_status() {
  log("show_status", false, false);

  if (_version == 3)
    _io.showStatus();
  advancePC();
}

void ZMProcessor::sound_effect() {
  log("sound_effect", false, false);

  uint16_t number = getOperand(0);
  uint16_t effect = getOperand(1);
  uint16_t volume = getOperand(2);
  // uint16_t routine = getOperand(3);
  getOperand(3);
  int repeat = volume >> 8;
  int vol = volume & 0xff;
  _io.soundEffect(number, effect, repeat, vol);
  advancePC();
}

void ZMProcessor::split_window() {
  log("split_window", false, false);

  uint16_t lines = getOperand(0);
  _io.splitWindow(lines);
  advancePC();
}

void ZMProcessor::store() {
  log("store", false, false);

  uint16_t variable = getOperand(0);
  uint16_t value = getOperand(1);
  setVariable(variable, value, true);
  advancePC();
}

void ZMProcessor::storeb() {
  log("storeb", false, false);

  uint16_t array = getOperand(0);
  int16_t byte_index = static_cast<int16_t>(getOperand(1));
  uint16_t value = getOperand(2);

  // Store operand2 in array operand0 indexed by operand1
  _memory.setByte(array + byte_index, value);
  advancePC();
}

void ZMProcessor::storew() {
  log("storew", false, false);

  uint16_t array = getOperand(0);
  int16_t word_index = static_cast<int16_t>(getOperand(1));
  uint16_t value = getOperand(2);

  // Store operand2 in array operand0 indexed by operand1
  _memory.setWord(array + 2 * word_index, value);
  advancePC();
}

void ZMProcessor::sub() {
  decodeStore();
  log("sub", true, false);

  int16_t a = static_cast<int16_t>(getOperand(0));
  int16_t b = static_cast<int16_t>(getOperand(1));
  setVariable(_store, a - b);
  advancePC();
}

void ZMProcessor::test() {
  decodeBranch();
  log("test", false, true);

  uint16_t bitmap = getOperand(0);
  uint16_t flags = getOperand(1);
  branchOrAdvancePC((bitmap & flags) == flags);
}

void ZMProcessor::test_attr() {
  decodeBranch();
  log("test_attr", false, true);

  uint16_t object = getOperand(0);
  uint16_t attribute = getOperand(1);
  if (object == 0)
    branchOrAdvancePC(false);
  else
    branchOrAdvancePC(_memory.getObject(object).getAttribute(attribute));
}

void ZMProcessor::_throw() {
  log("throw", false, false);

  uint16_t value = getOperand(0);
  uint16_t stack_frame = getOperand(1);
  _stack.throwFrame(stack_frame);
  _pc = _stack.popFrame(&_store);
  setVariable(_store, value);
}

void ZMProcessor::tokenise() {
  log("tokenise", false, false);

  uint16_t text = getOperand(0);
  uint16_t parse = getOperand(1);
  uint16_t userDictionary = 0;
  if (_operandCount > 2)
    userDictionary = getOperand(2);
  uint16_t flag = 0;
  if (_operandCount > 3)
    flag = getOperand(3);

  ZMDictionary dictionary(_memory.getData(), userDictionary);
  dictionary.lex(text, _memory.getData(parse), flag == 1);
  advancePC();
}

void ZMProcessor::_verify() {
  decodeBranch();
  log("verify", false, true);

  branchOrAdvancePC(_memory.getChecksum() ==
                    _memory.getHeader().getFileChecksum());
}
