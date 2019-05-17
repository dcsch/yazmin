
#include "ZMIO.h"

@class Story;
@class StoryFacet;

class ZMStoryAdapter : public ZMIO {
public:
  ZMStoryAdapter(Story *story);

  ~ZMStoryAdapter() override;

  void setWindow(int window) override;

  void splitWindow(int lines) override;

  void eraseWindow(int window) override;

  void showStatus() override;

  void setColor(int foreground, int background) override;

  void setCursor(int line, int column) override;

  void setTextStyle(int style) override;

  void print(const char *str) override;

  void printNumber(int number) override;

  void newLine() override;

  size_t input(char *str, size_t maxLen) override;

  char inputChar() override;

  void restore(const void **data, size_t *length) override;

  void save(const void *data, size_t length) override;

  uint16_t getRestoreOrSaveResult() override;

private:
  Story *_story;
  StoryFacet *_storyFacet;
};
