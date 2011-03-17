
#include "ZMIO.h"

@class Story;
@class StoryFacet;

class ZMStoryAdapter : public ZMIO
{
public:
    
    ZMStoryAdapter(Story *story);
    
    virtual ~ZMStoryAdapter();
    
    virtual void setWindow(int window);
    
    virtual void splitWindow(int lines);
    
    virtual void eraseWindow(int window);
    
    virtual void showStatus();
    
    virtual void setColour(int foreground, int background);
    
    virtual void setCursor(int line, int column);
    
    virtual void setTextStyle(int style);
    
    virtual void print(const char *str);
    
    virtual void printNumber(int number);
    
    virtual void newLine();
    
    virtual size_t input(char *str, size_t maxLen);
    
    virtual char inputChar();

    virtual void restore(const void **data, size_t *length);

    virtual void save(const void *data, size_t length);

    virtual uint16_t getRestoreOrSaveResult();

private:
    Story *_story;
    StoryFacet *_storyFacet;
};
