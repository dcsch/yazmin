/*
 *  ZMDictionary.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 21/12/06.
 *  Copyright 2006 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_DICTIONARY_IO_H__
#define ZM_DICTIONARY_IO_H__

#include <stdint.h>

class ZMDictionary
{
public:
  
    ZMDictionary(uint8_t *data);
    
    int getWordSeparatorCount() const;
    
    char getWordSeparator(int index) const;
    
    int getEntryLength() const;
    
    int getEntryCount() const;
    
    uint16_t getEntryAddress(int index) const;
    
    void lex(uint16_t textBufferAddress, uint16_t parseBufferAddress) const;
    
private:
        
    uint8_t *_data;
    
    const uint8_t *getDictionaryData() const;
    
    int tokenise(const char *str,
                 int maxWordCount,
                 int *wordIndex,
                 int *wordLen) const;
    
    int separator(char c) const;
};

#endif //ZM_DICTIONARY_IO_H__
