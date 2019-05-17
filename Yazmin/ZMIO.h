/*
 *  ZMIO.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 19/12/06.
 *  Copyright 2006 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_IO_H__
#define ZM_IO_H__

#include <stdlib.h>
#include <stdint.h>

class ZMIO
{
public:
    
    virtual ~ZMIO() { }
    
    virtual void setWindow(int window) = 0;
    
    virtual void splitWindow(int lines) = 0;
    
    virtual void eraseWindow(int window) = 0;
    
    virtual void showStatus() = 0;
    
    virtual void setColor(int foreground, int background) = 0;
    
    virtual void setCursor(int line, int column) = 0;
    
    virtual void setTextStyle(int style) = 0;
    
    virtual void print(const char *str) = 0;
    
    virtual void printNumber(int number) = 0;
    
    virtual void newLine() = 0;
    
    virtual size_t input(char *str, size_t maxLen) = 0;
    
    virtual char inputChar() = 0;
    
    virtual void restore(const void **data, size_t *length) = 0;
    
    virtual void save(const void *data, size_t length) = 0;

    virtual uint16_t getRestoreOrSaveResult() = 0;
    
};

#endif //ZM_IO_H__
