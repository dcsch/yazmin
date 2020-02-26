/*
 *  ZMProcessor.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 11/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_PROCESSOR_H__
#define ZM_PROCESSOR_H__

#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

class ZMMemory;
class ZMStack;
class ZMIO;
class ZMError;
class ZMQuetzal;

class ZMProcessor {
public:
  ZMProcessor(ZMMemory &memory, ZMStack &stack, ZMIO &io, ZMError &error,
              ZMQuetzal &quetzal);

  ~ZMProcessor() = default;

  uint32_t getProgramCounter();

  void setProgramCounter(uint32_t pc);

  bool hasQuit();

  bool execute();

  bool executeUntilHalt();

  bool callRoutine(int routine);

private:
  enum OperandType { kLargeConstant, kSmallConstant, kVariable, kOmitted };

  ZMMemory &_memory;
  ZMStack &_stack;
  ZMIO &_io;
  ZMError &_error;
  ZMQuetzal &_quetzal;
  uint32_t _pc;
  uint32_t _initialPC;
  int _operandOffset;
  int _instructionLength;
  int _operandCount;
  OperandType _operandTypes[8];
  uint16_t _store;
  int16_t _branch;
  bool _branchOnTrue;
  uint16_t _seed;
  uint16_t _lastRandomNumber;
  int _version;
  int _packedAddressFactor;
  std::vector<std::pair<uint16_t, std::string>> _redirect;
  bool _hasQuit;
  bool _hasHalted;
  bool _continuingAfterHalt;
  //  uint32_t _lastChecksum;

  bool executeLongInstruction();

  bool executeShortInstruction();

  bool executeExtendedInstruction();

  bool executeVariableInstruction();

  bool dispatch0OP(uint8_t opCode);

  bool dispatch1OP(uint8_t opCode);

  bool dispatch2OP(uint8_t opCode);

  bool dispatchVAR(uint8_t opCode);

  bool dispatchEXT(uint8_t opCode);

  OperandType operandType(uint8_t byte);

  void decodeStore();

  void decodeBranch();

  uint16_t getOperand(int index, bool noPop = false);

  uint16_t getVariable(int index, bool noPop = false);

  void setVariable(int index, uint16_t value, bool noPush = false);

  void advancePC();

  void branchOrAdvancePC(bool testResult);

  void print(std::string str);

  void print(int16_t number);

  void printUnicodeChar(uint16_t uc);

  void log(const char *name, bool showStore, bool showBranch);

  // St -- 2OP:20 14 add a b -> (result)
  void add();

  // St -- 2OP:9 9 and a b -> (result)
  void _and();

  // St -- EXT:3 3 5 art_shift number places -> (result)
  void art_shift();

  // -- -- VAR:242 12 4 buffer_mode flag
  void buffer_mode();

  // -- -- 1OP:143 F 5 call_1n routine
  void call_1n();

  // St -- 1OP:136 8 4 call_1s routine -> (result)
  void call_1s();

  // -- -- 2OP:26 1A 5 call_2n routine arg1
  void call_2n();

  // St -- 2OP:25 19 4 call_2s routine arg1 -> (result)
  void call_2s();

  // -- -- VAR:249 19 5 call_vn routine ...up to 3 args...
  void call_vn();

  // -- -- VAR:250 1A 5 call_vn2 routine ...up to 7 args...
  void call_vn2();

  // St -- VAR:224 [2OP:224] 0 1 call routine ...up to 3 args... -> (result)
  // St -- VAR:224 0 4 call_vs routine ...up to 3 args... -> (result)
  void call_vs();

  // St -- VAR:236 C 4 call_vs2 routine ...up to 7 args... -> (result)
  void call_vs2();

  // St -- 0OP:185 9 5/6 catch -> (result)
  void _catch();

  // -- Br VAR:255 1F 5 check_arg_count argument-number
  void check_arg_count();

  // -- -- EXT:12 C 5/* check_unicode char-number -> (result)
  void check_unicode();

  // -- -- 2OP:12 C clear_attr object attribute
  void clear_attr();

  // -- -- VAR:253 1D 5 copy_table first second size
  void copy_table();

  // -- -- 1OP:134 6 dec (variable)
  void dec();

  // -- Br 2OP:4 4 dec_chk (variable) value ?(label)
  void dec_chk();

  // St -- 2OP:23 17 div a b -> (result)
  void div();

  // -- -- VAR:252 1C 5 encode_text zscii-text length from coded-text
  void encode_text();

  // -- -- VAR:238 E 4/6 erase_line value
  void erase_line();

  // -- -- VAR:237 D 4 erase_window window
  void erase_window();

  // St Br 1OP:130 2 get_child object -> (result) ?(label)
  void get_child();

  // -- -- VAR:240 10 4/6 get_cursor array
  void get_cursor();

  // St -- 2OP:19 13 get_next_prop object property -> (result)
  void get_next_prop();

  // St -- 1OP:131 3 get_parent object -> (result)
  void get_parent();

  // St -- 2OP:17 11 get_prop object property -> (result)
  void get_prop();

  // St -- 2OP:18 12 get_prop_addr object property -> (result)
  void get_prop_addr();

  // St -- 1OP:132 4 get_prop_len property-address -> (result)
  void get_prop_len();

  // St Br 1OP:129 1 get_sibling object -> (result) ?(label)
  void get_sibling();

  // -- -- 1OP:133 5 inc (variable)
  void inc();

  // -- Br 2OP:5 5 inc_chk (variable) value ?(label)
  void inc_chk();

  // -- -- VAR:244 14 3 input_stream number
  void input_stream();

  // -- -- 2OP:14 E insert_obj object destination
  void insert_obj();

  // -- Br 2OP:1 1 je a b ?(label)
  void je();

  // -- Br 2OP:3 3 jg a b ?(label)
  void jg();

  // -- Br 2OP:6 6 jin obj1 obj2 ?(label)
  void jin();

  // -- Br 2OP:2 2 jl a b ?(label)
  void jl();

  // -- -- 1OP:140 C jump ?(label)
  void jump();

  // -- Br 1OP:128 0 jz a ?(label)
  void jz();

  // St -- 1OP:142 E load (variable) -> (result)
  void load();

  // St -- 2OP:16 10 loadb array byte-index -> (result)
  void loadb();

  // St -- 2OP:15 F loadw array word-index -> (result)
  void loadw();

  // St -- EXT:2 2 5 log_shift number places -> (result)
  void log_shift();

  // St -- 2OP:24 18 mod a b -> (result)
  void mod();

  // St -- 2OP:22 16 mul a b -> (result)
  void mul();

  // -- -- 0OP:187 B new_line
  void new_line();

  // -- -- 0OP:180 4 1/- nop
  void nop();

  // St -- 1OP:143 F 1/4 not value -> (result)
  // St -- VAR:248 18 5/6 not value -> (result)
  void _not();

  // St -- 2OP:8 8 or a b -> (result)
  void _or();

  // -- -- VAR:243 13 3 output_stream number
  //                  5 output_stream number table
  //                  6 output_stream number table width
  void output_stream();

  // -- Br 0OP:191 F 5/- piracy ?(label)
  void piracy();

  // -- -- 0OP:185 9 1 pop
  void pop();

  // -- -- 0OP:178 2 print
  void print();

  // -- -- 1OP:135 7 print_addr byte-address-of-string
  void print_addr();

  // -- -- VAR:229 5 print_char output-character-code
  void print_char();

  // -- -- VAR:230 6 print_num value
  void print_num();

  // -- -- 1OP:138 A print_obj object
  void print_obj();

  // -- -- 1OP:141 D print_paddr packed-address-of-string
  void print_paddr();

  // -- -- 0OP:179 3 print_ret
  void print_ret();

  // -- -- VAR:254 1E 5 print_table zscii-text width height skip
  void print_table();

  // -- -- EXT:11 B 5/* print_unicode char-number
  void print_unicode();

  // -- -- VAR:233 9 1 pull (variable)
  void pull();

  // -- -- VAR:232 8 push value
  void push();

  // -- -- VAR:227 3 put_prop object property value
  void put_prop();

  // -- -- 0OP:186 A quit
  void quit();

  // St -- VAR:231 7 random range -> (result)
  void random();

  // -- -- VAR:228 4 1 sread text parse
  void sread();

  // St -- VAR:228 4 5 aread text parse time routine -> (result)
  void aread();

  // St -- VAR:246 16 4 read_char 1 time routine -> (result)
  void read_char();

  // -- -- 1OP:137 9 remove_obj object
  void remove_obj();

  // -- -- 0OP:183 7 1 restart
  void restart();

  // -- Br 0OP:182 6 1 restore ?(label)
  // St -- 0OP:182 5 4 restore -> (result)
  void restore();

  // St -- EXT:1 1 5 restore table bytes name prompt-> (result)
  void restore_ext();

  // St -- EXT:10 A 5 restore_undo -> (result)
  void restore_undo();

  // -- -- 1OP:139 B ret value
  void ret();

  // -- -- 0OP:184 8 ret_popped
  void ret_popped();

  // -- -- 0OP:177 1 rfalse
  void rfalse();

  // -- -- 0OP:176 0 rtrue
  void rtrue();

  // -- Br 0OP:181 5 1 save ?(label)
  // St -- 0OP:181 5 4 save -> (result)
  void save();

  // St -- EXT:0 0 5 save table bytes name -> (result)
  void save_ext();

  // St -- EXT:9 9 5 save_undo -> (result)
  void save_undo();

  // St Br VAR:247 17 4 scan_table x table len form -> (result)
  void scan_table();

  // -- -- 2OP:11 B set_attr object attribute
  void set_attr();

  // -- -- 2OP:27 1B 5 set_colour foreground background
  void set_colour();

  // -- -- VAR:239 F 4 set_cursor line column
  void set_cursor();

  // St -- EXT:4 4 5 set_font font -> (result)
  void set_font();

  // -- -- VAR:241 11 4 set_text_style style
  void set_text_style();

  // -- -- EXT:13 D 5/* set_true_colour foreground background
  void set_true_colour();

  // -- -- VAR:235 B 3 set_window window
  void set_window();

  // -- -- 0OP:188 C 3 show_status
  void show_status();

  // -- -- VAR:245 15 5/3 sound_effect number effect volume routine
  void sound_effect();

  // -- -- VAR:234 A 3 split_window lines
  void split_window();

  // -- -- 2OP:13 D store (variable) value
  void store();

  // -- -- VAR:226 2 storeb array byte-index value
  void storeb();

  // -- -- VAR:225 1 storew array word-index value
  void storew();

  // St -- 2OP:21 15 sub a b -> (result)
  void sub();

  // -- Br 2OP:7 7 test bitmap flags ?(label)
  void test();

  // -- Br 2OP:10 A test_attr object attribute ?(label)
  void test_attr();

  // -- -- 2OP:28 1C 5/6 throw value stack-frame
  void _throw();

  // -- -- VAR:251 1B 5 tokenise text parse dictionary flag
  void tokenise();

  // -- Br 0OP:189 D 3 verify ?(label)
  void _verify();
};

inline uint32_t ZMProcessor::getProgramCounter() { return _pc; }

inline void ZMProcessor::setProgramCounter(uint32_t pc) { _pc = pc; }

inline bool ZMProcessor::hasQuit() { return _hasQuit; }

#endif // ZM_PROCESSOR_H__
