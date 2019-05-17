/*
 *  ZMStack.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 13/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_STACK_H__
#define ZM_STACK_H__

#include <stdint.h>
#include <stdlib.h>

/*!
 The Yazmin stack is made up of frames that look like the following (before
 anything is pushed onto the evaluation stack):
 _fp -> RETURN_ADDR_MSW
        RETURN_ADDR_LSW
        RETURN_STORE
        PREV_FRAME_POINTER
        ARG_COUNT
        LOCAL_VARIABLE_COUNT
        LOCAL_VARIABLE_1
        ...
        LOCAL_VARIABLE_N
 _sp -> (Evaluation Stack)
 */
class ZMStack
{
public:

    ZMStack(size_t size);
    
    ~ZMStack();
    
    void push(uint16_t value);
    
    uint16_t pop();
    
    void pushFrame(uint32_t callAddr,
                   uint32_t returnAddr,
                   int argCount,
                   int localCount,
                   uint16_t returnStore);
    
    uint32_t popFrame(uint16_t *returnStore);
    
    uint16_t getLocal(int index) const;
    
    void setLocal(int index, uint16_t value);
    
    uint16_t getArgCount() const;
    
    void createStksChunk(uint8_t **buf, size_t *len);

    void dump() const;
    
    uint16_t getEntry(int index) const;

    int frameCount();
    
    int framePointerArray(int *array, int maxCount);

    uint32_t getCallEntry(int index) const;

    uint16_t getFrameLocal(int frame, int index) const;
    
private:
//    size_t _maxSize;
    //uint16_t *_entries;
    uint16_t _entries[1024];
    int _sp;
    int _fp;
    uint32_t _calls[1024];
    int _frames[1024];
    uint32_t _frameCount;
};

#endif //ZM_STACK_H__
